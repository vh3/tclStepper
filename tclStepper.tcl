# tclStepper.tcl
# A package for driving stepper motors via gpio on Raspbberry Pi
# 3 Mar 2019

# Object-oriented structures created with the help of: https://www.magicsplat.com/articles/oo.html
# --------------------------------------------------------------------------------------------------

package require Tcl 8.6
package provide tclStepper 0.1.0

namespace eval ::tclStepper {

	oo::class create Stepper
	# Also, oo::define CLASSNAME DEFINITIONSCRIPT
	
	oo::define Stepper {
		variable CoilCount       ;# the number of wires that will use to drive the motor
		variable Timing          ;# the number of milliseconds between steps
		variable AngleStart      ;# the reference angle (degrees) where the motor started
		variable AngleTarget     ;# the reference angle (degrees) where intent to move the motor to
		variable AngleCurrent    ;# the current location (degrees) of the motor
		variable StepPerRotation ;# the number of steps for a full rotation of the motor (4076, for 28BJY-48A, empirically)
		variable StepMode        ;# the mode that this stepper will use (half, full, ...)
		variable StepModeSignals ;# the list of pins that 
		variable GpioPins        ;# the ordered list of gpio pins that will be used by this motor

		method step {} {

		}	
	}

# calculations after https://www.instructables.com/id/CNC-Drawing-Arm/
# diagrams at: https://cdn.instructables.com/F47/IOSI/J5K6TR3R/F47IOSIJ5K6TR3R.LARGE.jpg
# and https://cdn.instructables.com/FJH/PIIJ/J5K6TR1H/FJHPIIJJ5K6TR1H.LARGE.jpg

# the actual calculations ported from: https://cdn.instructables.com/ORIG/FUD/XDBE/J6FDYDES/FUDXDBEJ6FDYDES.ino
# They are not strictly identical to the calculations presented in the diagrams.  Get your Grade 12 Functions notes out!
# returns a list of 2 angles in degrees, clockwise from the vertical.
proc angle {x y offset Y L} {

	set pi [expr acos(-1.0)]
	set rad2deg [expr 180 / $pi]

	if {$x >= $offset} {

	   puts "x ($x) >= offset ($offset)"
	   set D      [expr sqrt(($offset - $x) * ($offset - $x) + ($Y - $y) * ($Y - $y))]
	   
	   # set angle1 [expr $pi + atan(($offset - $x) / ($Y - $y)) + acos($D/(2 * $L))]; # clockwise from vertical
	   # angle1 = PI + acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))] ; #radians, clockwise from vertical

	   # set angle2 [expr $pi + atan(($offset - $x) / ($Y - $y)) - acos($D /2 * $L)]    ; #clockwise from vertical
	   #  angle2 = PI - acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
    	   # angle2 = PI - acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))]

	} else {

	   puts "x ($x) < offset ($offset)"

	   set D      [expr sqrt(($x - $offset)*($x - $offset) + ($Y - $y) * ($Y - $y))]
	   puts "D=$D"
	   puts "D/2L = [expr $D / (2 * $L)]"

	   # set angle1 [expr $pi - atan(($x - $offset) / ($Y - $y)) + acos($D/(2 * $L))]
	   #    angle1 = PI + acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))] ; # radians, clockwise from vertical
	   puts "angle1 = $angle1"

	   # set angle2 [expr $pi – atan(($x - $offset) / ($Y - $y)) – acos($D/(2 * $L))]
	   #    angle2 = PI - acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))]
	   puts "angle2 = $angle2"

	} 
	
	# Convert to degrees and return
	return [list [expr $angle1 * $rad2deg ] [expr $angle2 * $rad2deg]]
}

    # Core functions
    namespace export 

    # Helper functions
    namespace export 
}

proc ::tclStepper::constructor {} {

}

proc ::tclStepper::destructor {} {

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

# Test data
# set x      209.99   ; # Cartesion coordinate of the destination point
# set y      0.0   ; # Cartesian coordinate of the destination point
# set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
# set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
# set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
# set result [::tclStepper::angle $x $y $offset $Y $L]
# puts "Result is:$result"

# # Full Step (CW)
# Orange   1 1000 
# Yellow   2 0100
# Pink     3 0010
# Blue     4 0001

# Half Step2 (CW)
# Orange 1 11000001
# Yellow 2 01110000
# Pink 3 00011100
# Blue 4 00000111

proc step {} {

	# 1. calculate the next location (x,y)> absolute angle
	# 2. calculate the relative rotation required from the current rotation 
	# 3. calculate the relative speed of the two motors needed to finish at the same moment, accounting for accelleration.
	# 4. loop through the steps.

}
