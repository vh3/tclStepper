# stepper_tests.tcl
# A collection of development tests for the stepper scripts.
# Intended for use on a raspberry pi
#  3 Mar 2019, vh, first version
# 16 Mar 2019, vh, added scripts for Motor object, delay

# Add the current folder to the current auto_path so that we can load this package
# we assume that this package was retrieved with the command "git clone https://github.com/vh3/tclStepper.git"
set auto_path [append auto_path " [pwd]"]
# puts $auto_path

package require tclStepper

# ----------------------------------------------------------------------
# Test out the time-delay procedures with a delay of 1ms

# set delay_time 1
# Simple after+vwait. Calculate average time for 1000 attempts
# set time0 [time {::tclStepper::delay $delay_time} 1000]
# puts "$time0"

# after-idle event loop method. Calculate average time for 1000 attempts
# set time1 [time {::tclStepper::delay-ev $delay_time} 1000]
# puts "$time1"

# counting clock clicks in a while loop.  Calculate average time for 1000 attempts
# This is the most accurate of the three methods on the Raspberry Pi.
# set time2 [time {::tclStepper::delay-bw $delay_time} 1000]
# puts "$time2"

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
# set up a simple stepper motor and rotate a fixed number of steps
set motor1 [::tclStepper::Motor new [list 18 23 17 22] "28BJY-48"]
puts "motor1=$motor1"

$motor1 step 10
$motor1 step -4
$motor1 step 12
$motor1 rotate 360
$motor1 rotate -360
$motor1 rotate 0

$motor1 destroy

# ----------------------------------------------------------------------
# Try out the GPIO functions
puts "Writing to gpio pins"

set port_list [list 18 23 17 22]
# source gpio.tcl
# package require tclGPIO

# open the ports and set them as output
foreach i $port_list {

	catch {tclGPIO::open_port $i "out"} err
	puts "port $i opened for writing"
	# set the port value to zero, initially
	tclGPIO::write_port $i 0
	puts "port $i iniital value set to zero"
}

puts "ports opened for writing"

# Turn them on
foreach i $port_list {	
	tclGPIO::write_port $i 1
	tclStepper::delay 1000
}
# turn them off
foreach i $port_list { 
	tclGPIO::write_port $i 0
	tclStepper::delay 1000
}

# Close the ports
foreach i $port_list {tclGPIO::close_port $i}
