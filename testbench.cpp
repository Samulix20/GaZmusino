// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

// Device under test header
#include "Vrv32_core.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char** argv) {

	// Evaluate Verilator comand args
	Verilated::commandArgs(argc, argv);

	// Create device under test
	Vrv32_core *dut = new Vrv32_core;

	// Waveform tracing
	// trace signals 5 levels under dut
	Verilated::traceEverOn(true);
	VerilatedVcdC *m_trace = new VerilatedVcdC;
	dut->trace(m_trace, 5);
	m_trace->open("waveform.vcd");
	
	// Testbench simulation loop
	while (sim_time < MAX_SIM_TIME) {
		// Clk signal
		dut->clk ^= 1;

		// Reset signal
		if(sim_time > 0 && sim_time < 5){
			dut->resetn = 0;
		} else {
			dut->resetn = 1;
		}

		// Simulate signals
		dut->eval();
		
		// Trace waveform
		m_trace->dump(sim_time);
		
		// Advance simulation loop
		sim_time++;
	}

	// Close waveform file
	m_trace->close();
	// Free device under test
	delete dut;
	// Exit end
	exit(EXIT_SUCCESS);
}

