// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "rv32_test_utils.h"

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

    uint8_t* program_code = rv32_test::read_elf("build/mainrv.elf");
    uint32_t raw_instr = 0;
    uint32_t pc = 0;

    // Testbench simulation loop
    while (sim_time < MAX_SIM_TIME) {
        // Clk signal
        dut->clk ^= 1;
        

        // Reset signal
        if(sim_time > 0 && sim_time < 5){
            dut->resetn = 0;
        } else {
            dut->resetn = 1;
            pc = dut->instr_addr;
            
            // Protect against mem array overflow
            if (pc < 40) {
                raw_instr = rv32_test::read_instr(program_code, pc);
                dut->instr_bus = raw_instr;
                dut->instr_ready = 1;
            }
        }

        // Simulate signals
        dut->eval();

        // Debug
        // Only on high clk and after reset
        if (dut->clk == 0 && sim_time >= 5) {
            rv32_test::trace_stages(dut);
        }

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

