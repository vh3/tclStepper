# tclStepper.tcl
# A pure tcl package for driving stepper motors via gpio on Raspbberry Pi
# This package can be cloned to your rPI with "git clone https://github.com/vh3/tclStepper.git"
#  3 Mar 2019
# 23 Mar 2019, vh, added scripts for Motormotor object

# Object-oriented structures created with the help of: https://www.magicsplat.com/articles/oo.html
# --------------------------------------------------------------------------------------------------

# Add the current path to the autopath variable so any local package require calls will work
set auto_path [append auto_path " [pwd]"]

package require Tcl 8.6
package require Thread;  # Info about how threads work in Tcl can be found here: http://www.beedub.com/book/4th/Threads.pdf
package require tclGPIO; # A local package needed to drive individual gpio pins

package provide tclStepper 0.1.0

namespace eval ::tclStepper {

	# This class will will define the movement of a single motor.  Since a device may need to coordinate multiple motors, we will need another class later to assemble and coordinate motors.
	# We can use threading as means to make both motors move in a relatively smooth, coordinated manner.
	oo::class create Motor
	oo::define Motor {

		# Actively used variables
		variable GpioPins        ;# a list of GPIO pins that will be used for this motor.
		variable CoilCount       ;# the number of wires that will use to drive the motor
		variable StepTiming      ;# the minimum number of milliseconds between steps (knowing that OS timing is not precise)
		variable AngleStart      ;# the reference angle (degrees) where the motor started (the location of this motor's 'zero' angle.
		variable StepPerRotation ;# the number of steps for a full rotation of the motor (4076, for 28BJY-48A, empirically)
		variable StepSignals     ;# a list of pin activation sequences (each list element has a sequence of 0s or 1s for each coil state)
		variable StepState       ;# what is the net sum of steps we have taken since motor initialization.
		variable StepCycleState  ;# where in the current of stepper driver sequences we are located. (starts at zero)
		variable Reference       ;# A web link to datasheet or refernece material used to create the motor parameters

		# Unused variables so far...
		variable AngleTarget     ;# the reference angle (degrees) where intent to move the motor to
		variable AngleCurrent    ;# the current location (degrees) of the motor
		variable StepMode        ;# the mode that this stepper will use (half, full, ...)

		constructor {gpio_list {motor_type "28BJY-48A"}} {
			puts "Creating motor object"

			# Add motor configurations as we test new motors.  TODO: move this out to a configuration file that can be edited by users outside the package
			# Todo: add the means to configure multiple step methods for a moto180
			set motor_config(28BJY-48)       [list CoilCount 4 StepTiming 5 AngleStart 0 StepPerRotation 513  StepSignals {1000 0100 0010 0001} StepState 0 Reference "https://42bots.com/tutorials/28byj-48-stepper-motor-with-uln2003-driver-and-arduino-uno/"]
			set motor_config(28BJY-48_half)  [list CoilCount 4 StepTiming 5 AngleStart 0 StepPerRotation 1026 StepSignals {1000 1100 0100 0110 0010 0011 0001 1001} StepState 0]
			set motor_config(28BJY-48A)      [list CoilCount 4 StepTiming 1 AngleStart 0 StepPerRotation 2038 StepSignals {1000 0100 0010 0001} StepState 0]
			set motor_config(28BJY-48A_half) [list CoilCount 4 StepTiming 1 AngleStart 0 StepPerRotation 4076 StepSignals {1000 1100 0100 0110 0010 0011 0001 1001} StepState 0]
			set motor_config(28BJY-48A_Robot2_1) [list CoilCount 4 StepTiming 1 AngleStart 250 StepPerRotation 4076 StepSignals {1000 1100 0100 0110 0010 0011 0001 1001} StepState 0]
			set motor_config(28BJY-48A_Robot2_2) [list CoilCount 4 StepTiming 1 AngleStart 215 StepPerRotation 4076 StepSignals {1000 1100 0100 0110 0010 0011 0001 1001} StepState 0]

			# initialize the configuration parameters passed in the config statement
			# TODO: implement a formal config statement so users can set and reconfigure all or some parameters.
			set GpioPins $gpio_list
			foreach {i j} $motor_config($motor_type) {set $i $j}

			# Setup the GPIO pins for this motor
			puts "Initializing Gpio pins for this motor: $GpioPins"
			foreach i $GpioPins {

				# Initialize the pins to output
				if {[catch {::tclGPIO::open_port $i "out"} err]} {puts $err}
				# Set the initial value to zero
				if {[catch {::tclGPIO::write_port $i 0} err]} {puts $err}
			}

			# if the StartAngle is not zero, set the StepState to an appropriate value
			if {$AngleStart != 0} {

				set StepState [expr round($AngleStart * $StepPerRotation / 360.0)]
				puts "AngleStart was not zero:  StepState is now: $StepState"
			}

			# Attempt one step forward, then back.
			my step 1
			my step -1
		}

		destructor {

			puts "Destroying motor object"

			# Return the motor to it's starting position.
			# my rotateto $AngleStart

			# Set the values of the pins to zero, and close the ports to these pins
			puts " Releasing motor pins: $GpioPins"
			foreach i $GpioPins {

				if {[catch {::tclGPIO::write_port $i 0} err]} {puts $err}
				if {[catch {::tclGPIO::close_port $i} err]} {puts $err}
			}
		}

		# A method to move a single step CW or CCW and update all the related state variables
		method onestep {{direction "CW"}} {

			if {$direction == "CW"} {set incr_value 1} else {set incr_value -1}

			# update the StepState
			incr StepState $incr_value

			# update the StepCycleState
			incr StepCycleState $incr_value
			set StepCycleState [expr $StepCycleState % [llength $StepSignals]]

			# Find the appropriate sequence we need to activate
			set seq [lindex $StepSignals $StepCycleState]
			# puts "sequence: $StepCycleState, LED states: $seq"

			# Turn on the appropriate pins (we can't do it all simultaneously here.  Does the order matter?  TODO: experiment with order and correct for rotation direction if we discover it matters
			for {set i 0} {$i < $CoilCount} {incr i} {
				::tclGPIO::write_port [lindex $GpioPins $i] [string index $seq $i]
			}

		}; #end of method onestep

		#step a single motor by a discrete set of steps
		method step {stepcount} {

			# puts "inside proc step.  stepcount=$stepcount"

			if {$stepcount > 0} {set dir "CW"} elseif {$stepcount < 0} {set dir "CCW"} else {return}
			set stepcount [expr abs($stepcount)]

			# count down the steps
			while { $stepcount > 0 } {

					# Send appropriate GPIO signals
					# puts "stepcount = $stepcount"
					# if {$dir == "CW"} {incr StepState} else {incr StepState -1}
					my onestep $dir

					::tclStepper::delay-ev $StepTiming

					# figure out which signal to do next (from where we are)

					# We have finished one step.  Count down the stepcounter by one.
					incr stepcount -1

					# Wait an appropriate time before stepping again
					after $StepTiming
			}

			# puts "current StepState = $StepState"
			return

		}; # End of method "step"

		#  rotate by a specific number of degrees
		method rotate {angle_deg} {

			# Convert angles into steps
			set stepcount [expr round($angle_deg / 360.0 * $StepPerRotation)]
			my step $stepcount

			return

		}; # End of proc rotate

		# Rotate to an absolute orientation angle
		method rotateto {angle_deg} {

				# Calculate the current angle of orientation
				# puts "StepState=$StepState, StepPerRotation=$StepPerRotation, AngleStart=$AngleStart, Target Angle=$angle_deg"

				# set current_angle [expr 360.0 * ($StepState % round($StepPerRotation)) / $StepPerRotation + $AngleStart]
				set current_angle [my showcurrentangle]
				# set current_angle [expr 360.0 * $StepState / $StepPerRotation ]
				# set current_angle [expr 360.0 * (($StepState % $StepPerRotation) / $StepPerRotation) + $AngleStart]
				# puts "current_angle=$current_angle"

				# set current_angle [expr  $current_angle % 360]

				# Currently, do not cross "zero degrees" to move between angles.
				# TODO: Calculate the shortest rotation to get to this angle.  Account for known areas to which the motor may not rotate due to obstructions
				if {$angle_deg <= $current_angle} {

					set rotate_angle [expr $angle_deg - $current_angle]

				} else {

					set rotate_angle [expr $angle_deg - $current_angle]
				}

				# puts "Current_angle=$current_angle.  Rotating $rotate_angle degrees to get to $angle_deg"
				my rotate $rotate_angle

				return

		}; # End of proc rotateto

		# Report the current angle of rotation (0 to 360 degreees)
		method showcurrentangle {} {

			# This calculation will never be exactly correct if the StepPerRotation is not actually an integer.  Close enough for the moment
			return [expr 360.0 * ($StepState % round($StepPerRotation)) / $StepPerRotation]

		}; # End of method ShowCurrentAngle

		method showstartangle {} {
	
			return $AngleStart
		}
	
		method gettiming {} {return $StepTiming}		
		method settiming {new_value} {set StepTiming $new_Value; return}

		# TODO: write generic get and config commands

	}; # end of Motor object definition

	# Methods with lower case names are exported by default.  Export others if necessary
	# oo::define Motor {export XXXXX}

	# ------------------------------------------------------------------
	# Multimotor object
	# A multimotor is an object made up of motor objects which must be syncronized
	oo::class create Multimotor
	oo::define Multimotor {

		variable MotorHandleList   ;# A variable definition
		variable MotorCount

		constructor {handlelist} {

			set MotorHandleList $handlelist
			set MotorCount [llength $handlelist]
			puts "Multimotor object ([self]) created with $MotorCount motors."

		}; # end of constructor

		destructor {

			# For now, we must use the Motor destructors
			foreach i $MotorHandleList {destroy $i}

		}; # end of destructor

		# Syncronize the movmment of multiple motors
		# Assume target_list values are all positive, 0 <= x < 360
		method rotateto {target_list} {
			
			# for the moment, set step time = 2ms, steps per rotation 4076 - TODO: set up the introspection methods in Motor object
			set step_time 2
			set step_per_rot 4076

			# check that there are enough parameters provided for the number of  motors defined
			if {[llength $target_list] != $MotorCount} {puts "not enough parameters passed.  Got [llength $target_list], was expecting $MotorCount";return}

			# Calculate the steps needed for each motor.
			set motor_count 0
			set max_steps 0
			set long_rotation 0
			set long_rotation_motor ""
			foreach i $target_list {

				set motor_handle($motor_count) [lindex $MotorHandleList $motor_count]
				set target_angle($motor_count) $i
				set current_angle($motor_count) [[lindex $MotorHandleList $motor_count] showcurrentangle]
				set rot_angle($motor_count) [expr $i - $current_angle($motor_count)]
				set step_count($motor_count) [expr round($rot_angle($motor_count) / 360.0 * $step_per_rot)]
				puts "for motor $motor_count (handle=$motor_handle($motor_count)), current_angle=$current_angle($motor_count).  Need to rotate $rot_angle($motor_count) to get to $target_angle($motor_count) = $step_count($motor_count) steps"

				# keep track of the longest rotation
				if {[expr abs($rot_angle($motor_count))] >= $long_rotation} {
				
						set long_rotation [expr abs($rot_angle($motor_count))]
						set long_rotation_motor $motor_count
				}

				incr motor_count
			}

			incr motor_count -1

			puts "largest rotation:$long_rotation on motor $long_rotation_motor"

			# run a stepper loop for the longest step, and stop both motors at the appropriate time.  
			# This means that the two motors will not stop at the exact same moment. 
			for {set i 1} {$i <= [expr abs($step_count($long_rotation_motor))]} {incr i} {
			
				# iterate over each of the motors
				for {set motor_num 0} {$motor_num <= $motor_count} {incr motor_num} {

					# Step if we have steps left to go
					if {$i <= [expr abs($step_count($motor_num))] } {

						if {$rot_angle($motor_num) > 0} {

							# Step clockwise
							$motor_handle($motor_num) onestep CW

						} elseif {$rot_angle($motor_num) < 0} {

							# Step clockwise
							$motor_handle($motor_num) onestep CCW							
						}
					}
				}
			}			

		}; # end of Moveto method definition

	}; # end of class definition for MultiMotor


	# ------------------------------------------------------------------
	# OBJECT TEMPLATE
	# <describe this object>
	oo::class create DummyObject
	oo::define DummyObject {

		variable varname1   ;# A variable definition

		constructor {} {

		}; # end of constructor

		destructor {

		}; # end of destructor

		method methodname1 {varlist} {return}

	}; # end of class definition for DummyObject
	# ------------------------------------------------------------------

}; # end of namespace definition:  tclStepper

# ::tclStepper::angle1
# A helper function for a specific 2D drawing arm robot.  Move this to a separate implementation script for a specific robot later
# calculations after https://www.instructables.com/id/CNC-Drawing-Arm/
# see diagrams at: https://cdn.instructables.com/F47/IOSI/J5K6TR3R/F47IOSIJ5K6TR3R.LARGE.jpg
# and https://cdn.instructables.com/FJH/PIIJ/J5K6TR1H/FJHPIIJJ5K6TR1H.LARGE.jpg

# the actual calculations ported from: https://cdn.instructables.com/ORIG/FUD/XDBE/J6FDYDES/FUDXDBEJ6FDYDES.ino
# They are not strictly identical to the calculations presented in the diagrams.  Get your Grade 12 Functions notes out!
# returns a list of 2 angles in degrees, clockwise from the vertical.

# Example usage
# set x      209.99   ; # Cartesion coordinate of the destination point
# set y      0.0   ; # Cartesian coordinate of the destination point
# set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
# set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
# set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
# set result [::tclStepper::angle $x $y $offset $Y $L]
# puts "Result is:$result"
proc ::tclStepper::angle1 {x y offset Y L} {

	set pi [expr acos(-1.0)]
	set rad2deg [expr 180 / $pi]

	if {$x >= $offset} {

	   # puts "x ($x) >= offset ($offset)"
	   set D      [expr sqrt(($offset - $x) * ($offset - $x) + ($Y - $y) * ($Y - $y))]

	   # set angle1 [expr $pi + atan(($offset - $x) / ($Y - $y)) + acos($D/(2 * $L))]; # clockwise from vertical
	   # angle1 = PI + acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))] ; #radians, clockwise from vertical

	   # set angle2 [expr $pi + atan(($offset - $x) / ($Y - $y)) - acos($D /2 * $L)]    ; #clockwise from vertical
	   #  angle2 = PI - acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
    	   # angle2 = PI - acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))]

	} else {

	   # puts "x ($x) < offset ($offset)"

		set D      [expr sqrt(($x - $offset)*($x - $offset) + ($Y - $y) * ($Y - $y))]
		# puts "D=$D"
		# puts "D/2L = [expr $D / (2 * $L)]"

		#   angle1 = PI + acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
		set angle1 [expr $pi + acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))] ; # radians, clockwise from vertical
		# puts "angle1 = $angle1"

		# angle2 = PI - acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
		set angle2 [expr $pi - acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))]
	   #   puts "angle2 = $angle2"
	}

	# Convert to degrees and return
	return [list [expr $angle1 * $rad2deg ] [expr $angle2 * $rad2deg]]
}


proc ::tclStepper::angle2 {x y offset1 offset2 y_axis length} {

	# return angles (clockwise from vertical) for a 2-arm plotting arm
	# after https://www.instructables.com/id/CNC-Dual-Arm-Plotter/ 
	# and https://cdn.instructables.com/ORIG/FV9/MFQ9/J5UA3DYI/FV9MFQ9J5UA3DYI.ino

	set pi [expr acos(-1.0)]
	set rad2deg [expr 180.0 / $pi]

	set distance1 [expr sqrt(($offset1 - $x) * ($offset1 - $x) + ($y_axis - $y) * ($y_axis - $y) )]
	set distance2 [expr sqrt(($offset2 - $x) * ($offset2 - $x) + ($y_axis - $y) * ($y_axis - $y) )]

	if {$x > $offset1} {
	
		set angle1 [expr $pi + acos($distance1 / (2 * $length)) - atan(($x - $offset1) / ($y_axis - $y))] ;# radians	

	} else {

		set angle1 [expr $pi + acos($distance1 / (2 * $length)) + atan(($offset1 - $x) / ($y_axis - $y))]; # radians
	}

	if {$x > $offset2} {
	
		set angle2 [expr $pi - acos($distance2 / (2 * $length)) - atan(($x - $offset2) / ($y_axis  - $y))]; # radians

	} else {
	
		set angle2 [expr $pi - acos($distance2 / (2 * $length)) + atan(($offset2 - $x) / ($y_axis - $y))]; # radians
	}

	# Convert angles to degrees and return
	return [list [expr $rad2deg * $angle1] [expr $rad2deg * $angle2]]
};  #end of proc angle2


# --------------------------------------------------------------------
# USEFUL INFO FROM THE ARDUINO VERSION

#define PI 3.1415926535897932384626433832795
#define HALF_PI 1.5707963267948966192313216916398
#define TWO_PI 6.283185307179586476925286766559
#define DEG_TO_RAD 0.017453292519943295769236907684886
#define RAD_TO_DEG 57.295779513082320876798154814105

# OFFSET = 210,                       //motor offset along x_axis
# YAXIS = 465,                        //motor heights above (0,0)
# LENGTH = 300,                       //length of each arm-segment
# SCALE_FACTOR = 1,                   //drawing scale (1 = 100%)
# ARC_MAX = 2;                        //maximum arc-length (controls smoothness)

# Result is:219.19496742598292 140.80503257401708

# -----------------------------------------------------

# Test data
# set x      209.99   ; # Cartesion coordinate of the destination point
# set y      0.0   ; # Cartesian coordinate of the destination point
# set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
# set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
# set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
# set result [::tclStepper::angle $x $y $offset $Y $L]
# puts "Result is:$result"

# # Full Step (CW)
# Orange   0 1000
# Yellow   1 0100
# Pink     2 0010
# Blue     3 0001

# Half Step2 (CW)
# Orange 0 11000001
# Yellow 1 01110000
# Pink   2 00011100
# Blue   3 00000111


# ----------------------------------------------------------------------
# HELPER FUNCTIONS FOR THE STEPPER PACKAGE - NOT PART OF OBJECTS
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Scripts to help improve motor stepping time intervals because all
# timing activities are at the mercy the multi-tasking operating system.
# These are good enough for our stepper motors.
# after: https://wiki.tcl-lang.org/page/sleep
# Usage:
# ::tclStepper::delay <ms>     ;# simple delay used by every Tcl example on the web
# ::tclStepper::delay-ev <ms>  ;# simple delay made by doing no work inside a loop
# ::tclStepper::delay-bw <ms>  ;# an event-loop
namespace eval ::tclStepper:: {
	variable _i
	variable c/ms

	proc calibrate {} {
		variable c/ms
		puts "calibrating clock clicks.."
		set start [clock clicks]
		after 1000
		set end [clock clicks]
		set c/ms [expr {($end-$start)/1000.0}]
		puts "speed: [expr {${c/ms}*1000}] clicks per second"
	}

	# simplest delay example
	proc delay {ms} {
		global stop_flag
		set stop_flag 0
		after $ms {set stop_flag 1}
		vwait stop_flag
	}

	# TODO: Can we update the calibration function to test the other methods, then recalculate a new calibration measure that accounts for the behaviour of our favourite method?

	calibrate

	# busywaiting delay
	proc delay-bw {sec} {
		# set sec [expr $ms / 1000.0]
		variable c/ms
		set s [clock clicks]
		while {[clock clicks] < $s+(${c/ms}*$sec)} {# do nothing}
	}

	# busywaiting "after idle" delay, using event loop
	proc delay-ev {sec} {
		# set sec [expr $ms / 1000.0]
		variable c/ms
		set s [clock clicks]
		set e [expr {$s+$sec*${c/ms}}]
		evwait ::tclStepper::_i $e
		vwait ::tclStepper::_i
		unset ::tclStepper::_i
	}

	# worker for delay-ev
	# continually reschedules itself via "after idle" until end time
	proc evwait {var {end 0}} {
		set ct [clock clicks]
		if {$ct < $end} {
			after idle [list ::tclStepper::evwait $var $end]
			return
		} else {
			set $var 0
		}
	}
}
