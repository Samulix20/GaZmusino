// C standard includes
#include <stdlib.h>
#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vrv32_main_memory.h"
#include "Vrv32_main_memory___024unit.h"

using MemoryRequest = Vrv32_main_memory_memory_request_t__struct__0;
using MemoryResponse = Vrv32_main_memory_memory_response_t__struct__0;
using MemoryRV32 = Vrv32_main_memory___024unit;

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

        
        if(!reset_on) {

            if(sim_time >= 5 && sim_time <= 6) {
                MemoryRequest r0;
                r0.addr = 4;
                r0.data = 0xDEADBEEF;
                r0.op = MemoryRV32::MEM_SW;
                dut->data_request = r0.get();
            }

            else if (sim_time >= 7 && sim_time <= 8) {
                MemoryRequest r0;
                r0.addr = 4;
                r0.data = 0;
                r0.op = MemoryRV32::MEM_LW;
                dut->data_request = r0.get();
            }
            
        }

        // Update signals
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
    return 0;
}
