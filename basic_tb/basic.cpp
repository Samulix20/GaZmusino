#include <iostream>

// Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>

// Testbench
#include "Vtestbench.h"

#include "test_vector.h"

constexpr uint64_t MAX_SIM_TIME = 1000;
constexpr uint8_t INIT_RESET_NUM_CYCLES = 4;

int main(int argc, char** argv) {

    uint64_t sim_time = 0;

    // Evaluate Verilator comand args
    Verilated::commandArgs(argc, argv);

    // Create testbench
    Vtestbench* tb = new Vtestbench;

    // Trace signals
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    tb->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    // Testbench vars
    uint64_t setup_cyles = 0;

    // Simulation loop
    while(sim_time < MAX_SIM_TIME) {
        // Clk
        tb->clk ^= 1;

        // Reset signal
        bool reset_on = sim_time <= INIT_RESET_NUM_CYCLES;
        tb->resetn = static_cast<uint8_t>(!reset_on);

        // Eval clk and reset
        tb->eval();

        // Eval any combinational logic c++ simulated
        tb->eval();

        // Testbench
        if(!reset_on && tb->clk == 1) {
            setup_cyles++;
            uint64_t idx = setup_cyles - 4;
            if (setup_cyles > 3 && idx < TEST_VECTOR.size()) {
                if (tb->r != TEST_VECTOR[idx]) {
                    std::cerr << "Test failed on " << idx << '\n';
                    exit(1);
                }
            } 
        }

        // Trace
        m_trace->dump(sim_time);
        // Advance simulation
        sim_time++;
    }

    m_trace->close();
    delete tb;

    return 0;
}
