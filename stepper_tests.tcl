# stepper_tests.tcl
# A collection of development tests for the stepper scripts.
# 3 Mar 2019, vh

# Add the current folder to the current auto_path so that we can load this package
set auto_path [append auto_path " [pwd]"]
# puts $auto_path

package require tclStepper

# Test data
set x      209.99   ; # Cartesion coordinate of the destination point
set y      0.0   ; # Cartesian coordinate of the destination point
set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
set result [::tclStepper::angle $x $y $offset $Y $L]
puts "Result is:$result"

