# stepper_tests.tcl
# A collection of development tests for the stepper scripts.
# Intended for use on a raspberry pi
# This package can be cloned to your rPI with "git clone https://github.com/vh3/tclStepper.git"
#  3 Mar 2019, vh, first version
# 16 Mar 2019, vh, added scripts for Motor object, delay

set delay_example   false
set angular_example false
set motor_example   false
set gpio_example    false
set text_example    true

# Add the current folder to the current auto_path so that we can load local packages
set auto_path [append auto_path " [pwd]"]

package require tclStepper

if {$delay_example} {
	# ----------------------------------------------------------------------
	# Test out the time-delay procedures with a delay of 1ms
	
	set delay_time 1
	Simple after+vwait. Calculate average time for 1000 attempts
	set time0 [time {::tclStepper::delay $delay_time} 1000]
	puts "$time0"

	# after-idle event loop method. Calculate average time for 1000 attempts
	set time1 [time {::tclStepper::delay-ev $delay_time} 1000]
	puts "$time1"

	# counting clock clicks in a while loop.  Calculate average time for 1000 attempts
	# This is the most accurate of the three methods on the Raspberry Pi.
	set time2 [time {::tclStepper::delay-bw $delay_time} 1000]
	puts "$time2"

}

if {$angular_example} {

	# ----------------------------------------------------------------------
	# Test out the angular calculations

	set x      209.99   ; # Cartesion coordinate of the destination point
	set y      0.0   ; # Cartesian coordinate of the destination point
	set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
	set Y      465.0 ; # The vertical distance from the origina point(0,0) to the spindle mount of the arm, mm
	set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
	set result [::tclStepper::angle $x $y $offset $Y $L]
	puts "(x,y)($x,$y) >> (angle1,angle2)([lindex $result 0],[lindex $result 1])"	
}

if {$motor_example} {
	# ----------------------------------------------------------------------
	# set up a simple stepper motor and rotate a fixed number of steps
	set motor1 [::tclStepper::Motor new [list 18 23 17 22] "28BJY-48A"]
	puts "motor1=$motor1"

	$motor1 rotateto 720
	$motor1 rotate -90
	$motor1 rotate 90

#	$motor1 step 100
#	$motor1 step -40
#	$motor1 step 50
#	$motor1 rotate 180
#	$motor1 rotate -180
#	$motor1 rotateto 0
#	$motor1 rotateto 90	
#	$motor1 rotateto 0
	$motor1 destroy
}

# ----------------------------------------------------------------------
if {$gpio_example} {

	# Try out the GPIO functions
	puts "Writing to gpio pins"
	
	set port_list [list 18 23 17 22]
	
	# open the ports and set them as output
	foreach i $port_list {
	
		catch {::tclGPIO::open_port $i "out"} err
		puts "port $i opened for writing"
		# set the port value to zero, initially
		::tclGPIO::write_port $i 0
		puts "port $i iniital value set to zero"
	}
	puts "ports opened for writing"
	
	# Turn them on
	foreach i $port_list {	
		::tclGPIO::write_port $i 1
		::tclStepper::delay 1000
	}	
	#	 turn them off
	foreach i $port_list { 
		::tclGPIO::write_port $i 0
		::tclStepper::delay 1000
	}

	# Close the ports
	foreach i $port_list {tclGPIO::close_port $i}
}

if {$text_example} {

	# A test of the 2-motor movement needed for the 2D robot arm at https://www.instructables.com/id/CNC-Drawing-Arm/
		
	# We will need the font definitions for this example.
	package require font

	# Load a font definition and draw some numbers.
	::font::load_font "font_data"; # Load a file of font definitions from a file called font_def1.tcl into variable font_data
	# Create some test text
	set insertion_pt [list 100.0 100.0]
	set size 10.0
	set text "88"

	# Robot arm setup geometry
	set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
	set Y      465.0 ; # The vertical distance from the origin point(0,0) to the spindle mount of the arm, mm
	set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.

	# Simple angular test
	set x      51.0
	set y      50.0
	set result [::tclStepper::angle $x $y $offset $Y $L]
	puts "Test result is:$result"
	
	# create a list of <pen> <x> <y> data for the given text
	set text_xy [::font::geometry $text font_data $insertion_pt $size]
	puts "text_xy=$text_xy"

	set text_rot [::font::xy2rot $text_xy $offset $Y $L]
	puts "text_rot=$text_rot"
	
	set motor1 [::tclStepper::Motor new [list 18 23 17 22] "28BJY-48A_half"]	
	set motor2 [::tclStepper::Motor new [list 21 19 27 13] "28BJY-48A_half"]

	# Initialize multimotor coordination object
	set multimotor [::tclStepper::Multimotor new [list $motor1 $motor2]]

	# cycle through each of the rotation angles
	set counter 0
	foreach {i angle1 angle2} $text_rot {
		incr counter

		puts "(LINE$counter):pen=$i, angle1=$angle1, angle2=$angle2"
		
		if {$i==1} {#pen down} else {#pen up}

		$multimotor rotateto "$angle1 $angle2"
	}
	
	# Rotate the motors back to zero before quitting.
	$multimotor rotateto {0 0}	

	$motor1 destroy
	$motor2 destroy
}
