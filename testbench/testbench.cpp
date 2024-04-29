// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "rv32_test_utils.h"
#include "rv32_trace_stages.h"

constexpr uint64_t max_sim_time = 10000;

int main(int argc, char** argv) {

    std::string rv_elf_executable = "";
    bool print_trace = false;

    // Evaluate Verilator comand args
    Verilated::commandArgs(argc, argv);

    // Evaluate our command args
    for(size_t i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "-e") {
            i++;
            rv_elf_executable = argv[i];
        }
        else if (arg == "-t") print_trace = true;
    }

    // Create device under test
    Vrv32_core *dut = new Vrv32_core;

    // Waveform tracing
    // trace signals 5 levels under dut
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    rv32_test::RVMemory memory(rv_elf_executable);
    vluint64_t sim_time = 0;

    // Testbench simulation loop
    while (sim_time < max_sim_time) {

        // Clk signal
        dut->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time < 5;
        dut->resetn = static_cast<uint8_t>(!reset_on);

        // Memory bus signals
        if(!reset_on && dut->clk == 1) {
            // Instr
            dut->instr_response = memory.handle_request(
                rv32_test::get_instruction_request(dut)).get();

            // Data
            dut->data_response = memory.handle_request(
                rv32_test::get_memory_request(dut)).get();
        }

        // Update signals
        dut->eval();

        // Debug
        // Only on high clk and after reset
        if (print_trace && !reset_on && dut->clk == 1) {
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
    std::cerr << "Max sim time reached" << "\n";
    exit(255); 
}
