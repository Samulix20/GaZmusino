// C standard includes
#include <cstdint>
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vrv32_top.h"

#include "rv32_test_utils.h"
#include "rv32_memory_utils.h"
#include "rv_instr_simulation.h"

int main(int argc, char** argv) {

    std::string rv_elf_executable = "";
    std::string rv_disassembly_file = "";

    constexpr uint64_t max_sim_time = 10000000;
    uint64_t sim_time = 0;
    bool print_trace = false;
    bool forever = true;

    // Evaluate Verilator comand args
    Verilated::commandArgs(argc, argv);

    // Evaluate our command args
    for(int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "-e") {
            i++;
            if (i == argc) break;
            rv_elf_executable = argv[i];
        }
        else if (arg == "-d") {
            i++;
            if (i == argc) break;
            rv_disassembly_file = argv[i];
        }
        else if (arg == "-t") print_trace = true;
    }

    auto diassembly_map = rv32_test::load_dissasembly(rv_disassembly_file);

    // Create device under test
    Vrv32_top *dut = new Vrv32_top;

    // Waveform tracing
    // trace signals 5 levels under dut
    //Verilated::traceEverOn(true);
    //VerilatedVcdC *m_trace = new VerilatedVcdC;
    //dut->trace(m_trace, 5);
    //m_trace->open("waveform.vcd");

    auto rvmem = rv32_test::load_elf(rv_elf_executable);

    rv32_test::init_profiler_counters();

    // Testbench simulation loop
    while (forever || sim_time < max_sim_time) {

        // Clk signal
        dut->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time <= 4;
        dut->resetn = static_cast<uint8_t>(!reset_on);

        if (sim_time == 5) {
            // Set bram contents
            rv32_test::set_memory_banks(dut, rvmem);
        }

        // Memory bus signals
        if(!reset_on) {
            rv32_test::handle_memory_request(dut, rvmem, sim_time);
        }

        // Update signals
        dut->eval();

        // Custom instruction DE stage sim
        if (!reset_on) {
            rv32_test::simulate_decode(dut);
        }

        // Custom instruction EX stage sim
        if (!reset_on) {
            rv32_test::simulate_execute(dut);
        } 

        dut->eval();

        // Debug
        // Only on high clk and after reset
        //if (print_trace && !reset_on && dut->clk == 0) {
        //    std::cout << rv32_test::trace_stages(dut, diassembly_map);
        //}

        // Trace waveform
        //m_trace->dump(sim_time);
        
        // Advance simulation loop
        sim_time++;
    }

    // Close waveform file
    //m_trace->close();
    // Free device under test
    delete dut;
    // Exit end
    std::cerr << "Max sim time reached" << "\n";
    exit(255); 
}
