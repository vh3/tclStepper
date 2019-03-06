# Font source: 	https://www.min.at/prinz/o/software/pixelfont/
# An 8x8 pixel ascii font definition file in Tcl list format
# Modified from fonts from:
# https://www.min.at/prinz/o/software/pixelfont/
# character data is organized by columns of pixels,
# intended for a horizontal scolling display
# line coordinates extracted by viewing the hex with the viewer
# tool at: https://gurgleapps.com/tools/matrix

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
