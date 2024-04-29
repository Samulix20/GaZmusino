// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vrv32_main_memory.h"

constexpr uint64_t max_sim_time = 200;

int main(int argc, char** argv) {
    // Evaluate Verilator comand args
    Verilated::commandArgs(argc, argv);

    // Create device under test
    Vrv32_main_memory *dut = new Vrv32_main_memory;

    // Waveform tracing
    // trace signals 5 levels under dut
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    vluint64_t sim_time = 0;

    // Testbench simulation loop
    while (sim_time < max_sim_time) {

        // Clk signal
        dut->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time < 5;
        dut->resetn = static_cast<uint8_t>(!reset_on);

        // Memory bus signals

        // Update signals
        dut->eval();

        // Debug
    
        // Trace waveform
        m_trace->dump(sim_time);
        
        // Advance simulation loop
        sim_time++;
    }

    // Close waveform file
    m_trace->close();
    // Free device under test
    delete dut;
    return 0;
}
