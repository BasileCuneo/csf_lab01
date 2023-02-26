#!/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc vhdl_compile { student } {
  global Path_VHDL
  global Path_TB

  set Path_VHDL ../../../../$student/code/hard/src_vhdl

  puts "\nPath_VHDL => ../../../../$student/code/hard/src_vhdl"

  puts "\nVHDL compilation :"

  vcom -2008 $Path_VHDL/IP_Qsys/avalon_bus_bridge.vhd
  vcom -2008 $Path_VHDL/avl_counter.vhd
  vlog -sv $Path_TB/avl_counter_tb.sv
}

#------------------------------------------------------------------------------
proc sim_start { testcase } {

  vsim -t 1ns -GTESTCASE=$testcase work.avl_counter_tb
  add wave -r *
  wave refresh
  run -all
}

#------------------------------------------------------------------------------
proc do_all { student testcase } {
  vhdl_compile $student
  sim_start  $testcase
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

set Path_TB ../../../../basile/code/hard/src_tb

global Path_VHDL
global Path_TB

# start of sequence -------------------------------------------------

if {$argc == 2} {
  if {[string compare $1 "kristina"] == 0 || [string compare $1 "jeremy"] == 0} {
    do_all $1 $2
  } else {
    puts "Usage: $argv0 <kristina|jeremy> <testcase>"
  }
} else {
  #print usage
  puts "Usage: $argv0 <kristina|jeremy> <testcase>"
}
