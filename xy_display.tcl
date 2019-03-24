# xy_display.tcl
# Made with help from: https://tkdocs.com/tutorial/canvas.html
# A script to display xy lines

# set data {0 110.0 112.5 1 107.5 115.0 1 110.0 117.5 1 112.5 117.5 1 115.0 115.0 1 112.5 112.5 1 110.0 112.5 1 107.5 110.0 1 107.5 107.5 1 110.0 105.0 1 112.5 105.0 1 115.0 107.5 1 115.0 110.0 1 112.5 112.5 0 130.0 112.5 1 127.5 115.0 1 130.0 117.5 1 132.5 117.5 1 135.0 115.0 1 132.5 112.5 1 130.0 112.5 1 127.5 110.0 1 127.5 107.5 1 130.0 105.0 1 132.5 105.0 1 135.0 107.5 1 135.0 110.0 1 132.5 112.5}
set data {0 107.5 115.0 1 110.0 117.5 1 110.0 105.0 1 107.5 105.0 1 112.5 105.0 0 127.5 107.5 1 127.5 115.0 1 130.0 117.5 1 132.5 117.5 1 135.0 115.0 1 135.0 107.5 1 132.5 105.0 1 130.0 105.0 1 127.5 107.5 1 135.0 115.0 0 150.0 117.5 1 150.0 117.5 0 150.0 107.5 1 150.0 107.5 0 167.5 107.5 1 167.5 115.0 1 170.0 117.5 1 172.5 117.5 1 175.0 115.0 1 175.0 107.5 1 172.5 105.0 1 170.0 105.0 1 167.5 107.5 1 175.0 115.0 0 190.0 112.5 1 187.5 115.0 1 190.0 117.5 1 192.5 117.5 1 195.0 115.0 1 192.5 112.5 1 190.0 112.5 1 187.5 110.0 1 187.5 107.5 1 190.0 105.0 1 192.5 105.0 1 195.0 107.5 1 195.0 110.0 1 192.5 112.5 0 232.5 107.5 1 232.5 115.0 1 230.0 115.0 1 227.5 112.5 1 227.5 110.0 1 230.0 107.5 1 237.5 107.5 1 237.5 117.5 1 235.0 120.0 1 225.0 120.0 1 222.5 117.5 1 222.5 107.5}

puts "There are [expr [llength $data] / 3] data points" 

# Reform the list into triplets
set data_xform ""
foreach {flag x y} $data {

	set data_xform [lappend data_xform [list $flag $x [expr 1000-$y] ]]
}

puts " There are [llength $data_xform] data points."
puts "data_xform=$data_xform"

# Find the limits of the data
set x_max [lindex [lindex [lsort -decreasing -index 1 $data_xform] 0] 1]
set x_min [lindex [lindex [lsort -increasing -index 1 $data_xform] 0] 1]
set x_breadth [expr $x_max - $x_min]
set y_max [lindex [lindex [lsort -decreasing -index 2 $data_xform] 0] 2]
set y_min [lindex [lindex [lsort -increasing -index 2 $data_xform] 0] 2]
set y_breadth [expr $y_max - $y_min]

puts "x_min=$x_min, x_max=$x_max (breadth = $x_breadth"
set x_low_bound [expr $x_min - .1*$x_breadth]
set x_high_bound [expr $x_max + .1*$x_breadth]

puts "y_min=$y_min, y_max=$y_max (breadth = $y_breadth)"
set y_low_bound [expr $y_min - .1*$y_breadth]
set y_high_bound [expr $y_max + .1*$y_breadth]

set counter 1
foreach i $data_xform {
	# puts "LINE($counter) ([lindex $i 0], [lindex $i 1], [lindex $i 2])"
	incr counter
}

#package require Tk

# grid [tk::canvas .canvas] -sticky nwes -column 0 -row 0
# grid columnconfigure . 0 -weight 1
# grid rowconfigure . 0 -weight 1

# bind .canvas <1> "set lastx %x; set lasty %y"
# bind .canvas <B1-Motion> "addLine %x %y"

# proc addLine {x y} {
#    .canvas create line $::lastx $::lasty $x $y
#    set ::lastx $x; set ::lasty $y
# }

package require Tk

puts "$x_low_bound $y_low_bound $x_high_bound $y_high_bound"
puts "$x_min $y_min $x_max $y_max"

grid [tk::canvas .canvas -scrollregion "$x_low_bound $y_low_bound $x_high_bound $y_high_bound" -yscrollcommand ".v set" -xscrollcommand ".h set"] -sticky nwes -column 0 -row 0
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

grid [tk::scrollbar .h -orient horizontal -command ".canvas xview"] -column 0 -row 1 -sticky we
grid [tk::scrollbar .v -orient vertical -command ".canvas yview"] -column 1 -row 0 -sticky ns
grid [ttk::sizegrip .sz] -column 1 -row 1 -sticky se

bind .canvas <1> {set lastx [.canvas canvasx %x]; set lasty [.canvas canvasy %y]}
bind .canvas <B1-Motion> {addLine [.canvas canvasx %x] [.canvas canvasy %y]}
bind .canvas <B1-ButtonRelease> "doneStroke"

# set id [.canvas create rectangle "$x_min $y_min $x_max $y_max" -fill red -tags "palette palettered"]
# .canvas bind $id <1> "setColor red"

set id [.canvas create rectangle 10 35 30 55 -fill blue -tags "palette paletteblue"]
.canvas bind $id <1> "setColor blue"

#set id [.canvas create rectangle 0 0 1000 1000 -fill black -tags "palette paletteblack paletteSelected"]
#.canvas bind $id <1> "setColor black"

proc setColor {color} {
    set ::color $color
    .canvas dtag all paletteSelected
    .canvas itemconfigure palette -outline white
    .canvas addtag paletteSelected withtag palette$color
    .canvas itemconfigure paletteSelected -outline #999999
}
proc addLine {x y} {
    .canvas create line $::lastx $::lasty $x $y -fill $::color -width 5 -tags currentline
    set ::lastx $x; set ::lasty $y
}
proc doneStroke {} {
    .canvas itemconfigure currentline -width 1
}

setColor black
.canvas itemconfigure palette -width 5

# Cycle through our data and create the lines

set pen 0

set x_first ""
set y_first ""
set scale 10

foreach i $data_xform {

	set pen [lindex $i 0]
	set x [lindex $i 1]
	set y [lindex $i 2]

	if {$pen=="0"} {

		# This is not a drawn line.  The pen is moving to a new position where a new line might be drawn.
		# Store these contents		

	} else {

		# we got here with a pen down.  Create a line
		set id [.canvas create line "$x_first $y_first $x $y" -fill red -tags "palette palettered"]
		
	}
	
		# Store the coordinates of this point in case the next drawing activity needs them
		set x_first $x
		set y_first $y	
}
