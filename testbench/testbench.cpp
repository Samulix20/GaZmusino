// C standard includes
#include <cstdint>
#include <fstream>
#include <ostream>
#include <stdlib.h>
#include <iostream>

#include <chrono>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vrv32_top.h"

#include "rv32_test_utils.h"
#include "rv32_memory_utils.h"
#include "rv_instr_simulation.h"
#include "testbench/rv32_trace_stages.h"

int main(int argc, char** argv) {

    std::string rv_elf_executable = "";

    rv32_test::SimulationData sim_data;
    sim_data.prof_file_ptr = &std::cout;
    sim_data.stdout_file_ptr = &std::cout;

    uint64_t sim_time = 0;
    bool do_trace = false;

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
        else if (arg == "--out") {
            i++;
            if (i == argc) break;
            sim_data.stdout_file.open(argv[i]);
            sim_data.stdout_file_ptr = &sim_data.stdout_file;
        }
        else if (arg == "--prof") {
            i++;
            if (i == argc) break;
            sim_data.prof_file.open(argv[i]);
            sim_data.prof_file_ptr = &sim_data.prof_file;
        }
        else if (arg == "--trace") {
            i++;
            if (i == argc) break;
            sim_data.trace_file.open(argv[i]);
            do_trace = sim_data.trace_file.is_open();
        }
    }

    // Create device under test
    Vrv32_top *dut = new Vrv32_top;
    sim_data.dut = dut;
    sim_data.mem = rv32_test::load_elf(rv_elf_executable);

    // Waveform tracing
    // trace signals 5 levels under dut
    //Verilated::traceEverOn(true);
    //VerilatedVcdC *m_trace = new VerilatedVcdC;
    //dut->trace(m_trace, 5);
    //m_trace->open("waveform.vcd");

    rv32_test::init_profiler_counters();

    sim_data.sim_start = std::chrono::high_resolution_clock::now();

    // Testbench simulation loop
    while (1) {
        sim_data.sim_time = sim_time;

        // Clk signal
        dut->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time <= 4;
        dut->resetn = static_cast<uint8_t>(!reset_on);

        if (sim_time == 5) {
            // Set bram contents
            rv32_test::set_memory_banks(dut, sim_data.mem);
        }

        // Memory bus signals
        if(!reset_on) {
            rv32_test::handle_memory_request(sim_data);
        }

        // Iterrupt test
        if (!reset_on && (sim_time >= 200)) {
            dut->rv32_top->timer_interrupt = 1;
            if (sim_time >= 20000) {
                dut->rv32_top->timer_interrupt = 0;
            }
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

        // Trace waveform
        //m_trace->dump(sim_time);

        if (!reset_on && do_trace) {
            rv32_test::trace_stages(sim_data);
        }
        
        // Advance simulation loop
        sim_time++;
    }

    // Close waveform file
    //m_trace->close();

    // Exit end
    std::cerr << "Max sim time reached" << "\n";
    exit(255); 
}
