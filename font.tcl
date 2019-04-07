# font.tcl
# package for creating font graphics
#
# -----------------------------------------------------------------------------

package require Tcl 8.6
package provide font 0.1.0

namespace eval ::font {

proc load_font {font_varname} {

	upvar $font_varname font_data
	set filename "font_def1.tcl"
	source $filename
	return 1
}

# A procedure to convert input text to a list of (pen,x,y) drawing actions
proc geometry {text font_var insertion_pt size} {

	upvar $font_var font_def
	# puts $font_def

	puts "Mapping text to font 'glyphs': '$text'"

	# cycle through each individual character and map the character to the font
	set result ""
	for {set char_counter 0} {$char_counter <[string length $text]} {incr char_counter} {

		set character [string index $text $char_counter]
		puts "working on character: $character"

		# Add it to the list
		set result [lappend result [string map $font_def $character]]
	}

	puts "   input text has [llength $result] character definitions"
	puts "    result = $result"

	#puts "Converting glyphs to absolute coordinates"
	set geometry_list ""
	set counter 0

	# iterate over each character
	foreach i $result {

		# iterate over each stroke that makes up the character
		foreach {pen x y} $i {

			append geometry_list " " $pen " " [expr [lindex $insertion_pt 0] + $size * $counter + $x / 8.0 * $size] " " [expr [lindex $insertion_pt 1] + $y / 8.0 * $size ]
		}

		# increase the x-offset for the next character
		incr counter
	}
	
	# puts "geometry_list = $geometry_list"
	puts "   text_xy has [expr [llength $geometry_list] / 3] points" 
	return $geometry_list 
}; # End of procedure definion: geometry


proc angle {x y offset Y L} {

	set pi [expr acos(-1.0)]
	set rad2deg [expr 180 / $pi]

	if {$x >= $offset} {

	   # puts "x ($x) >= offset ($offset)"
	   set D      [expr sqrt(($offset - $x) * ($offset - $x) + ($Y - $y) * ($Y - $y))]
	   # angle1 = PI + acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))] ; #radians, clockwise from vertical
    	   # angle2 = PI - acos(distance / (2 * LENGTH)) - atan((x - OFFSET) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) - atan(($x - $offset) / ($Y - $y))]

	} else {

	   # puts "x ($x) < offset ($offset)"
	   set D      [expr sqrt(($x - $offset)*($x - $offset) + ($Y - $y) * ($Y - $y))]
	   # puts "D=$D"
	   # puts "D/2L = [expr $D / (2 * $L)]"
	   # angle1 = PI + acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
	   set angle1 [expr $pi + acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))] ; # radians, clockwise from vertical
	   # puts "angle1 = $angle1"
	   # angle2 = PI - acos(distance / (2 * LENGTH)) + atan((OFFSET - x) / (YAXIS - y)); //radians
    	   set angle2 [expr $pi - acos($D / (2 * $L)) + atan(($offset - $x) / ($Y - $y))]
	   # puts "angle2 = $angle2"
	} 

	# Convert to degrees and return
	return [list [expr $angle1 * $rad2deg ] [expr $angle2 * $rad2deg]]
}

# Convert font definition from xy to rotation basis
proc xy2rot {text_xy offset Y L} {

	# The input text is a list of triples (pen_down_flag x y)

	set text_angles ""

	foreach {i j k} $text_xy {

		set rot [angle $j $k $offset $Y $L]
		# puts "rot=$rot"
		append text_angles " $i $rot"
	}

	puts "   text_rot has [expr [llength $text_angles]/3] points."	
	return $text_angles
}

# Convert font definition from xy to rotation basis
proc xy2rot2 {text_xy offset1 offset2 y_axis length} {

	# The input text is a list of triples (pen_down_flag x y)

	set text_angles ""

	foreach {i j k} $text_xy {

		set rot [angle2 $j $k $offset1 $offset2 $y_axis $length]
		# puts "rot=$rot"
		append text_angles " $i $rot"
	}

	puts "   text_rot has [expr [llength $text_angles]/3] points."	
	return $text_angles
}


# 
proc step {rot steps_per_rot step_var} {

	upvar $step_var step_var

	set steps [expr 360.0 / $steps_per_rot * $rot]
	puts "completing $steps steps"s

	set gpio [list 10 11 12 13] 
	set steps [ list {1 0 0 0} {0 1 0 0 } {0 0 1 0} {0 0 0 1}]

	set counter 0
	while {$counter > 0} {

		if {$rot > 0} {
		
			# CW
		
		} else {
		
			# CCW

		}

		incr counter -1

	}
}

}; # END OF NAMESPACE DEFINITION


return 

# Test data
set x      209.99   ; # Cartesion coordinate of the destination point
set y      0.0   ; # Cartesian coordinate of the destination point
set offset 210.0 ; # The horizontal distance from the origin point (0,0) to the spindle mount of the arm, mm
set Y      465.0 ; # The vertical distance from the origin point(0,0) to the spindle mount of the arm, mm
set L      300.0  ; # the length of the plotting arm(s).  The plotting arm linkages are all of equal length.
# set result [::tclStepper::angle $x $y $offset $Y $L]
# puts "Result is:$result"

# Load the font data
::font::load_font font_data

# Create some test text
set insertion_pt [list 100.0 100.0]
set size 10.0
set text "10:00 @"
set text_xy [::font::geometry $text font_data $insertion_pt $size]
# puts "text_xy=$text_xy"

set text_rot [::font::xy2rot $text_xy $offset $Y $L]
# puts "text_rot=$text_rot"
