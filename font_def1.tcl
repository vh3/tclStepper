# font_def1.tcl
# Hand-crafted font definition for a line-drawing robot.
# line coordinates extracted by viewing 8X8 character patterns with the the viewer
# tool at: https://gurgleapps.com/tools/matrix
# character definitions are lists of 3-element groups with <penup=0, pendown=1> <destination x> <destination y> on an 8X8 grid.
set font_data [list \
{ } {} \
0 { 0 3 3 1 3 6 1 4 7 1 5 7 1 6 6 1 6 3 1 5 2 1 4 2 1 3 3 1 6 6} \
1 { 0 3 6 1 4 7 1 4 2 1 3 2 1 5 2} \
2 { 0 3 6 1 4 7 1 5 7 1 6 6 1 6 5 1 5 4 1 4 4 1 3 3 1 3 2 1 6 2} \
3 { 0 3 7 1 5 7 1 6 6 1 5 5 1 4 5 1 5 5 1 6 4 1 6 3 1 5 2 1 3 2} \
4 { 0 3 7 1 3 4 1 6 4 0 5 6 1 5 2} \
5 { 0 6 7 1 3 7 1 3 5 1 5 5 1 6 4 1 6 3 1 5 2 1 3 2} \
6 { 0 6 7 1 4 7 1 3 6 1 3 3 1 4 2 1 5 2 1 6 3 1 6 4 1 5 5 1 3 5} \
7 { 0 3 7 1 6 7 1 6 6 1 4 4 1 4 2} \
8 { 0 4 5 1 3 6 1 4 7 1 5 7 1 6 6 1 5 5 1 4 5 1 3 4 1 3 3 1 4 2 1 5 2 1 6 3 1 6 4 1 5 5} \
9 { 0 6 4 1 4 4 1 3 5 1 3 6 1 4 7 1 5 7 1 6 6 1 6 3 1 5 2 1 3 2} \
: { 0 4 7 1 4 7 0 4 3 1 4 3} \
@ { 0 5 3 1 5 6 1 4 6 1 3 5 1 3 4 1 4 3 1 7 3 1 7 7 1 6 8 1 2 8 1 1 7 1 1 3} \
A { 0 3 2 1 3 6 1 4 7 1 5 7 1 6 6 0 6 2 1 3 4 1 6 4} \
]
puts "Font character definitions loaded: [expr [llength $font_data] / 2]"
