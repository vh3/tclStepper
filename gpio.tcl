# gpio.tcl
# Scripts for controlling gpio pins on a Raspberry Pi through tcl-only code
# modified after code from: https://wiki.tcl-lang.org/page/Raspberry+Pi
# -----------------------------------------------------------------------

#   Raspberry Pi GPIO-Interface 
# 
# Contents: Interface to control the GPIO ports of the Raspberry Pi.
# Date: Sat Feb 17, 2013
#
# Abstract:
#   A tcl-only library for controlling the General Purpose In/Out ports
#   of the credit-card-sized single-board computer Raspberry Pi.
#   See: http://www.raspberrypi.org/
#
# Remark:
#   Please keep in mind, that usually only root is allowed to
#   read and write IO ports.
#
# COPYRIGHT AND PERMISSION NOTICE
#
# Copyright (C) 2013-02 Gerhard Reithofer <gerhard.reithofer@tech-edv.co.at>.
#
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, provided that the above
# copyright notice(s) and this permission notice appear in all copies of
# the Software and that both the above copyright notice(s) and this
# permission notice appear in supporting documentation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
# OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL
# INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING
# FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
# WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Except as contained in this notice, the name of a copyright holder
# shall not be used in advertising or otherwise to promote the sale, use
# or other dealings in this Software without prior written authorization
# of the copyright holder.
#
# Functions:
#   open_port $port $dir
#     Opens a GPIO port for reading (in) or writing (out): open_port 14 "out"
#   close_port $port
#     Closes an open port: close_port 14
#   write_port
#     Write a value (typically 0 or 1) to a GPIO: write_port 14 1
#   read_port
#     Read a value from a GPIO: set result [read_port 14]
# 
# Variables:
#     tclGPIO::debug       - enable/disable debugging output, def. 0
#     tclGPIO::raspi_rev   - define Raspberry Rev. (1 or 2), def. 2
#     tclGPIO::port_check  - enable/disable "valid port" checking, def. 1
#     tclGPIO::valid_ports - defines "valid ports" list depending on
#                           the setting of $tclGPIO::raspi_rev 
#
# Known bugs:
#   IO errors are not trapped inside the library.
#

package provide tclGPIO 0.1

namespace eval tclGPIO {
  
  variable debug 0
  variable sys_path "/sys/class/gpio"
  variable direction
  
  variable port_check 1
  # Use tcl command
  #    set tclGPIO::port_check 0
  # for disabling "valid port checking" (runtime costs)
  
  variable raspi_rev 2
  # I use Rasperry Pi  Rev. 2 as default, use tcl command
  #    set tclGPIO::raspi_rev 1
  # for Rasperry Pi  Rev. 1
  
  # *** Raspberry Pi Rev. 1 + 2 "valid port" definitions
  # Ports reference: http://elinux.org/RPi_Low-level_peripherals
  variable valid_ports
  array set valid_ports {
    1 {0 1 4 7 8 9 10 11 14 15 17 18 21 22 23 24 25}
    2 {2 3 4 7 8 9 10 11 14 15 17 18 22 23 24 25 27}
    3 {2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27}
  }

  # DEBUG output function
  proc debug_out {s} {
    variable debug   
    if {$debug} {
      puts "DEBUG: $s"
    }
  }
  
  # aux function to construct the direction port path
  proc direction_port {port} {
    variable sys_path
    
    set dir_port [file join $sys_path "gpio$port" "direction"]
    debug_out "direction_port $port => $dir_port"
    
    return $dir_port
  }
  
  # aux function to construct the value port path
  proc value_port {port} {
    variable sys_path
    
    set val_port [file join $sys_path "gpio$port" "value"]
    debug_out "value_port $port => $val_port"

    return $val_port
  }
  
  # internal - make port (un)accessible by (un)exporting
  proc activate_port {port {onoff "off"}} {
    variable sys_path
    
    if {![string is boolean $onoff]} {
      error "activate_port: parameter 'onoff' must be boolean"
    }
    if {$onoff} {
      set act_port [file join $sys_path "export"]
    } else {
      set act_port [file join $sys_path "unexport"]
    }
    put_line $act_port $port
    set portd [direction_port $port]
    set rval [file exists $portd] 
    debug_out "activate_port $port $onoff => $rval"

    return $rval
  }
  
  # aux function - read line from pseudo file ...
  proc get_line {path} {
    
    set inpf [open $path {RDONLY}]
    set line [gets $inpf]
    close $inpf
    debug_out "get_line $path => $line"
 
    return $line
  }
  
  # aux function - write line to pseudo file ...
  proc put_line {path line} {
    
    set outd [open $path {WRONLY}]
    puts $outd $line
    close $outd
    debug_out "put_line $path => $line"
  
    return $line
  }
  
  # exported - activate port for in/out
  proc open_port {port dir} {
    variable sys_path
    variable raspi_rev
    variable port_check
    variable valid_ports
    
    if {$port_check && [lsearch $valid_ports($raspi_rev) $port]<0} {
      set plist [join $valid_ports($raspi_rev) {, }]
      error "open_port: invalid port number '$port', valid are $plist"
    }
    if {$dir ne "in" && $dir ne "out"} {
      error "open_port: invalid port direction '$dir', valid is 'in' and 'out'"
    }
    
    set portd [direction_port $port]
    if {![file exists $portd]} {
      activate_port $port "on"
    }
    
    if {![file exists $portd]} {
      error "unable to initialize port communication"
    }
    
    set adir [get_line $portd]  
    if {$adir eq $dir} { 
      debug_out "port $port already set to '$dir'"
    } else  {
      debug_out "portd $portd present - (re)using it"
      put_line $portd $dir ;# it appears this is wrong, and should always output the direction in both parts of this if block 
    }
    
    set line [get_line $portd]
    debug_out "open_port $port $dir => $line"
   
    return $line
  }
  
  # exported - deactivate port for access
  proc close_port {port} {
    variable sys_path
    
    set portc [activate_port $port "off"]
    set res [file exists $portc]
    debug_out "close_port $port => $res"
  
    return $res
  }
  
  # exported - write value (0|1) to specific port 
  proc write_port {port value} {
    variable sys_path
    
    set outf [value_port $port]
    if {![file exists $outf]} {
      error "cannot not set port '$port' for writing '$value'"
    }
    
    put_line $outf $value
    set line [get_line $outf]
    debug_out "write_port $port $value => $line"
   
    return $line
  }
  
  # exported - read value from specific port (receive 0|1)
  proc read_port {port} {
    variable sys_path
    
    set inpf [value_port $port]
    if {![file exists $inpf]} {
      error "cannot not get port '$port' for read value"
    }
    
    set line [get_line $inpf]
    debug_out "read_value $port => $line"
   
    return $line
  }

  # direction_port, value_port, activate_port, get_line, put_line -- not exported
  namespace export open_port close_port write_port read_port

}; # end of namespace definition


proc delay {ms} {
	global stop_flag
	set stop_flag 0
	after $ms {set stop_flag 1}
	vwait stop_flag		
}

return

# ----------------------------------------------------------------------
# Try out the GPIO functions
puts "Writing to gpio pins"

set port_list [list 18 23 17 22]

# open the ports and set them as output
foreach i $port_list {

	if {[catch {tclGPIO::open_port $i "out"} err]} {puts $err}
	puts "port $i opened for writing"
	# set the port value to zero, initially
	if {[catch {tclGPIO::write_port $i 0} err]} {puts $err}
	puts "port $i iniital value set to zero"
}

puts "ports opened for writing"

# Turn them on
foreach i $port_list {	
	if {[catch {tclGPIO::write_port $i 1} err]} {puts $err}
	delay 1000
}
# turn them off
foreach i $port_list { 
	if {[catch {tclGPIO::write_port $i 0} err]} {puts $err}
	delay 1000
}

# Close the ports
foreach i $port_list {
	if {[catch {tclGPIO::close_port $i} err]} {puts $err}
}

# ----------------------------------------------------------------------
# Morse example  

if {1 & [info script] eq $argv0} {
  set port  18
  set long  300
  set short 100
  set wait -300
  set morse {
   H . . . . E . L . _ . . L . _ . . O _ _ _ *
   R . _ . A . _ S . . . P . _ _ . I . . 2 . . _ _ _ }
  tclGPIO::open_port $port "out"
  foreach {sig} $morse {
    switch -- $sig {
      "."     { set delay $short}
      "_"     { set delay $long }
      default { set delay $wait }
    
    }
    if {[string is alnum $sig]} {
      set c $sig
    } else {
      set c [expr {$sig eq "*"?" ":""}]
    }
    puts -nonewline $c; flush stdout
    if {$delay>0} { tclGPIO::write_port $port 1 }
    after [expr {abs($delay)}]
    if {$delay>0} { tclGPIO::write_port $port 0 }
    after $short
  }
  puts ""
  tclGPIO::close_port $port
}
