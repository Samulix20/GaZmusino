RUN_PARAMS ?=

VERILATOR_ROOT := /home/samuelpp/opt/verilator
VV := ${VERILATOR_ROOT}/bin/verilator
TOP_MODULE := rv32_top
TOP_MODULE_SRC := rtl/${TOP_MODULE}.sv
VERILATED_MODULE := V${TOP_MODULE}
VERILOG_MODULES := rtl/rv32_types.sv \
	$(shell find rtl/core -name '*.sv')\
	$(shell find rtl/memory -name '*.sv')

CPP_SRC := $(shell find testbench -name '*.cpp')
CPP_HDR := $(shell find testbench -name '*.h')

.PHONY: test

obj_dir/${VERILATED_MODULE}: obj_dir/.verilator.stamp
	make -C obj_dir -f ${VERILATED_MODULE}.mk

obj_dir/.verilator.stamp: \
	$(CPP_SRC) $(CPP_HDR) ${TOP_MODULE_SRC} $(VERILOG_MODULES) \
	$(VERILOG_HEADERS)

	${VV} -I $(VERILOG_MODULES) -Wall --top-module ${TOP_MODULE} \
	--trace --trace-structs \
	--x-assign unique --x-initial unique \
	--cc -CFLAGS "-std=c++20 -Wall -Wextra" --exe ${TOP_MODULE_SRC} $(CPP_SRC)
	@touch obj_dir/.verilator.stamp

verilate: obj_dir/.verilator.stamp

clean:
	rm -rf obj_dir build waveform.vcd

wave:
	gtkwave waveform.vcd >/dev/null 2>/dev/null &

run: obj_dir/${VERILATED_MODULE}
	./obj_dir/${VERILATED_MODULE} +verilator+rand+reset+2 $(RUN_PARAMS)

test: obj_dir/${VERILATED_MODULE}
	@cd test && bash test.sh

memory:
	${VV} -I rtl/fpga/bram.sv -Wall \
	--top-module rv32_main_memory --trace --trace-structs \
	--x-assign unique --x-initial unique \
	--cc -CFLAGS "-std=c++20 -Wall -Wextra" rtl/fpga/rv32_main_memory.sv \
	--exe testbench/memory_tb.cpp
	make -C obj_dir -f Vrv32_main_memory.mk
	./obj_dir/Vrv32_main_memory +verilator+rand+reset+2
	gtkwave waveform.vcd >/dev/null 2>/dev/null &
