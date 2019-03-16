# tclStepper.tcl
# A package for driving stepper motors via gpio on Raspbberry Pi
# 3 Mar 2019

# Object-oriented structures created with the help of: https://www.magicsplat.com/articles/oo.html
# --------------------------------------------------------------------------------------------------

package require Tcl 8.6
package provide tclStepper 0.1.0

namespace eval ::tclStepper {

	# This class will will define the movement of a single motor.  Since a device may need to coordinate multiple motors, we will need another class later to assemble and coordinate motors.
	# We can use threading as means to make both motors move in a relatively smooth, coordinated manner.
	oo::class create Motor
	oo::define Motor {

		variable StepAbsolute    ;# the absolute count of steps from AngleStart we have moved since startup. This is a whole number of steps, and the most accurate method for avoiding additive errors over time?
		variable GpioPins        ;# a list of GPIO pins that will be used for this motor.
		variable CoilCount       ;# the number of wires that will use to drive the motor
		variable StepTiming      ;# the number of milliseconds between steps
		variable AngleStart      ;# the reference angle (degrees) where the motor started (the location of this motor's 'zero' angle.
		variable StepPerRotation ;# the number of steps for a full rotation of the motor (4076, for 28BJY-48A, empirically)
		variable StepSignals     ;# a list of pin activation sequences (each list element has a sequence of 0s or 1s for each coil state)
		variable StepState       ;# where in the current sequence of predefined steps we are (starts at zero)

		variable AngleTarget     ;# the reference angle (degrees) where intent to move the motor to
		variable AngleCurrent    ;# the current location (degrees) of the motor
		variable StepMode        ;# the mode that this stepper will use (half, full, ...)

		#step a single motor by a discrete set of steps
		method step {stepcount} {

			# variable stepcount

			puts "inside proc step.  stepcount=$stepcount"

			if {$stepcount > 0} {set dir "CW"} elseif {$stepcount < 0} {set dir "CCW"} else {return}
			set stepcount [expr abs($stepcount)]

			# count down the steps
			while { $stepcount > 0 } {

					# Send appropriate GPIO signals
					# puts "stepcount = $stepcount"
					if {$dir == "CW"} {incr StepState} else {incr StepState -1}

					# figure out which signal to do next (from where we are)

					# We have finished one step.  Count down the stepcounter by one.
					incr stepcount -1

					# Wait an appropriate time before stepping again
					after $StepTiming 

			}

			puts "current StepState = $StepState"

		}
	# End of method "step"


	}

	oo::define Motor {
		constructor {gpio_list {motor_type "28BJY-48A"}} {
			puts "Creating motor object"

			# Add motor configurations as we test new motors.  TODO: move this out to a configuration file that can be edited by users outside the package
			# Todo: add the means to configure multiple step methods for a motor.
			set motor_config(28BJY-48) [list StepAbsolute 0 Coilcount 4 StepTiming 2 Anglestart 0 StepPerRotation 512.8 StepSignals {1000 0100 0010 0000} StepState 0]
			set motor_config(28BJY-48A) [list StepAbsolute 0 Coilcount 4 StepTiming 2 Anglestart 0 StepPerRotation 4076 StepSignals {1000 0100 0010 0000} StepState 0]
			foreach {i j} $motor_config($motor_type) {set $i $j}

		}

		destructor {
			puts "Destroying motor object"
		}
	}

	# Methods with lower case names are exported by default.  Export others if necessary
	# oo::define Motor {export XXXXX}

	# END OF CLASS DEFINITIONS FOR 'MOTOR'
	# --------------------------------------------------------



	# Create our class in the global namespace
	# class create CLASSNAME DEFINITIONSCRIPT
	
	# Add some state and behaviour to this class
	# oo::define CLASSNAME DEFINITIONSCRIPT
	# Note: we are using mixed case for variables, lower case for methods

}


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
proc ::tclStepper::angle {x y offset Y L} {

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

	   # set angle1 [expr $pi - atan(($x - $offset) / ($Y - $y)) + acos($D/(2 * $L))]
	   #    angle1 = PI + acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))] ; # radians, clockwise from vertical
	   # puts "angle1 = $angle1"

	   # set angle2 [expr $pi – atan(($x - $offset) / ($Y - $y)) – acos($D/(2 * $L))]
	   #    angle2 = PI - acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))]
	   #   puts "angle2 = $angle2"
	}

	# Convert to degrees and return
	return [list [expr $angle1 * $rad2deg ] [expr $angle2 * $rad2deg]]
}

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

proc step {} {

	# 1. calculate the next location (x,y)> absolute angle
	# 2. calculate the relative rotation required from the current rotation
	# 3. calculate the relative speed of the two motors needed to finish at the same moment, accounting for accelleration.
	# 4. loop through the steps.
}


# ----------------------------------------------------------------------
# Scripts to time motor stepping as accurately as you can in tcl
# scripts from: https://wiki.tcl-lang.org/page/sleep
namespace eval delay {
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
		evwait ::delay::_i $e
		vwait ::delay::_i
		unset ::delay::_i
	}

	# worker for delay-ev
	# continually reschedules itself via "after idle" until end time
	proc evwait {var {end 0}} {
		set ct [clock clicks]
		if {$ct < $end} {
			after idle [list ::delay::evwait $var $end]
			return
		} else {
			set $var 0
		}
	}
}

# set time1 [time {::delay::delay-ev 2}]
# puts "$time1"

# set time2 [time {::delay::delay-bw 2}]
# puts "$time2"
