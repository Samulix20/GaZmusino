RUN_PARAMS ?=

# Custom verilator instalation
#VERILATOR_ROOT := /home/samuelpp/opt/verilator
#VV := ${VERILATOR_ROOT}/bin/verilator

# Package manager verilator instalation
VV := verilator

# Config flag for CPP simulated memory
CPP_MEMORY_SIM := -DCPP_MEMORY_SIM

# Config flag for optimized verilator
# !! Increases compile time
VVOPT := -O3

TOP_MODULE := rv32_top
TOP_MODULE_SRC := rtl/${TOP_MODULE}.sv
VERILATED_MODULE := V${TOP_MODULE}
VERILOG_MODULES := rtl/rv32_types.sv \
	$(shell find rtl/core -name '*.sv') \
	$(shell find rtl/memory -name '*.sv')

CPP_SRC := $(shell find testbench -name '*.cpp')
CPP_HDR := $(shell find testbench -name '*.h')

RV_BSP_PATH := $(realpath bsp)
PWD := $(shell pwd)

.PHONY: test clean run

obj_dir/${VERILATED_MODULE}: obj_dir/.verilator.stamp
	make -C obj_dir -f ${VERILATED_MODULE}.mk

# Verilator trace flags
# --trace --trace-structs

obj_dir/.verilator.stamp: \
	$(CPP_SRC) $(CPP_HDR) ${TOP_MODULE_SRC} $(VERILOG_MODULES) \
	$(VERILOG_HEADERS)
	${VV} -I $(VERILOG_MODULES) \
	-Wall --top-module ${TOP_MODULE} \
	$(CPP_MEMORY_SIM) $(VVOPT) \
	--x-assign unique --x-initial unique \
	--cc -CFLAGS "-I$(RV_BSP_PATH) -I$(PWD) $(CPP_MEMORY_SIM) -march=native -std=c++20 -Wall -Wextra" \
	--exe ${TOP_MODULE_SRC} $(CPP_SRC)

	@touch obj_dir/.verilator.stamp

verilate: obj_dir/.verilator.stamp

wave:
	gtkwave waveform.vcd >/dev/null 2>/dev/null &

bear: clean
	bear -- make

test: clean
	python modules/basic_test.py

bringup: clean
	python modules/bringup_bench_test.py --short

clean:
	rm -rf obj_dir build waveform.vcd
