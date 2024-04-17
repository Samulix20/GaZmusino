VERILATOR_ROOT = /home/samuelpp/opt/verilator
VV = ${VERILATOR_ROOT}/bin/verilator
TOP_MODULE = rv32_core
VERILATED_MODULE = V${TOP_MODULE}

test:
	rm -rf obj_dir waveform.vcd
	${VV} -I rtl/modules/* -Wall --top-module ${TOP_MODULE} --trace --trace-structs --x-assign unique --x-initial unique -cc rtl/${TOP_MODULE}.sv --exe testbench.cpp
	make -C obj_dir -f ${VERILATED_MODULE}.mk
	./obj_dir/${VERILATED_MODULE} +verilator+rand+reset+2
	gtkwave waveform.vcd >/dev/null 2>/dev/null &
