# stepper_tests.tcl
# A collection of development tests for the stepper scripts.
# Intended for use on a raspberry pi
#  3 Mar 2019, vh, first version
# 16 Mar 2019, vh, added scripts for Motor object

# Add the current folder to the current auto_path so that we can load this package
# we assume that this package was retrieved with the command "git clone https://github.com/vh3/tclStepper.git"
set auto_path [append auto_path " [pwd]"]
# puts $auto_path

package require tclStepper

# ----------------------------------------------------------------------
# Test out the time-delay procedures.  
set time1 [time {::delay::delay-ev 2}]
puts "$time1"

set time2 [time {::delay::delay-bw 2}]
puts "$time2"

# ----------------------------------------------------------------------
# Test out the angular calculations

set x      209.99   ; # Cartesion coordinate of the destination point
set y      0.0   ; # Cartesian coordinate of the destination point
set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
set result [::tclStepper::angle $x $y $offset $Y $L]
puts "(x,y)($x,$y) >> (angle1,angle2)([lindex $result 0],[lindex $result 1])"

# ----------------------------------------------------------------------
# set up a simple stepper motor
set motor1 [::tclStepper::Motor new [list 10 11 12 13] "28BJY-48"]
puts "motor1=$motor1"

$motor1 step 10
$motor1 step -4
$motor1 step 12

$motor1 destroy

