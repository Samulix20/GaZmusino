VERILATOR_ROOT := /home/samuelpp/opt/verilator
VV := ${VERILATOR_ROOT}/bin/verilator

DUT_FILES := $(shell find dut -name '*.sv')

all:
	${VV} -Wall --top-module testbench \
	-I ${DUT_FILES} \
	--trace --trace-structs \
	--x-assign unique --x-initial unique \
	--cc -CFLAGS "-std=c++20 -Wall -Wextra" \
	--exe testbench.sv basic.cpp
	
	make -C obj_dir -f Vtestbench.mk
	./obj_dir/Vtestbench +verilator+rand+reset+2
	gtkwave waveform.vcd >/dev/null 2>/dev/null & 
