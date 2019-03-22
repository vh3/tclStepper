# motor_thread.tcl
# Attempt at threading two stepper motors

# Start two threads
proc reset_pins {pin_list} {
	source gpio.tcl
	package require tclGPIO
	foreach i $pin_list {tclGPIO::close_port $i}	
}

#  reset_pins [list 18 23 17 22 21 19 27 13]; return

set motor_pins1 [list 18 23 17 22]
set motor_pins2 [list 21 19 27 13]
package require Thread

namespace eval ::stop {global ::stop::stop_me}

set thread1 [thread::create {source tclStepper.tcl; package require tclStepper; global ::stop::stop_me; thread::wait}]
set script "::tclStepper::Motor new {$motor_pins1} \"28BJY-48_half\""
set motor1 [thread::send $thread1 $script]
puts "motor1=$motor1"

set thread2 [thread::create {source tclStepper.tcl; package require tclStepper; global ::stop::stop_me; thread::wait}]
set script "::tclStepper::Motor new {$motor_pins2} \"28BJY-48_half\""
set motor2 [thread::send $thread2 $script]
puts "motor2=$motor2"

proc wait_thread {num_threads} {

	set done_flag 0
	while {!$done_flag} {
		vwait ::stop::stop_me
		if {tsv::get done flag == $num_threads} {set done_flag 1}
		puts "::stop::stopme=$stop::stop_me"
	}
}

tsv::set flag done 0
thread::send -async $thread1 "$motor1 rotateto 180;tsv::incr flag done;set ::stop::stop_me 1"
thread::send -async $thread2 "$motor1 rotateto 90;tsv::incr flag done; set ::stop::stop_me 1"
wait_thread 2

return

thread::send  -async $thread1 "$motor1 rotateto 0"
thread::send  $thread2 "$motor1 rotateto 0"

thread::send $thread1 "$motor1 destroy"
thread::send $thread2 "$motor2 destroy"

tsv::unset flag

