// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "rv32_test_utils.h"

vluint64_t sim_time = 0;
constexpr uint64_t max_sim_time = 10000;

// Bsp defines config
#include "../bsp/riscv/config.h"

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

    uint8_t* program_code = rv32_test::read_elf(rv_elf_executable);
    uint32_t raw_instr = 0;

    // Testbench simulation loop
    while (sim_time < max_sim_time) {

        // Clk signal
        dut->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time > 0 && sim_time < 5;
        dut->resetn = static_cast<uint8_t>(!reset_on);

        // I/O Singnals
        if(!reset_on) {
            // Instr
            rv32_test::memory_request_t instr_req;
            instr_req.set(dut->instr_request);
            // Protect against mem array overflow
            if (instr_req.addr <= 0xedc8) {
                raw_instr = rv32_test::read_instr(program_code, instr_req.addr);
                rv32_test::memory_response_t instr_res;
                instr_res.data = raw_instr;
                instr_res.ready = 1;
                dut->instr_response = instr_res.get();
            }

            // Data
            rv32_test::memory_request_t data_req;
            data_req.set(dut->data_request);

            if (data_req.addr == EXIT_STATUS_ADDR && data_req.op == rv32_test::RV32Core::MEM_SW) {
                if (print_trace) rv32_test::trace_stages(dut);
                std::cout << "Exit status " << data_req.data << '\n';
                exit(data_req.data);
            }
        }

        // Update signals
        dut->eval();

        // Debug
        // Only on high clk and after reset
        if (print_trace && !reset_on && dut->clk == 0) {
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
    std::cerr << "Max sim time reached\n";
    exit(255);
}

