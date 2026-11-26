if {![file isdirectory work]} {
    vlib work
}

vlog -work work toll_booth.v
vlog -work work toll_booth_tb.v
vsim work.toll_booth_tb
add wave -r sim:/toll_booth_tb/*
run -all
