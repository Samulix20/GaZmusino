#ifndef RV32_TRACE_STAGES
#define RV32_TRACE_STAGES

#include "rv32_test_utils.h"
#include <iostream>

namespace rv32_test {

inline void trace_stages(SimulationData& sim_data) {

    // Log only in 0
    if (sim_data.dut->clk == 1) return;

    sim_data.trace_file << "C;" << sim_data.sim_time / 2 << '\n';
    
    auto fetch_pc = get_pc(sim_data.dut);
    sim_data.trace_file << "F;" << fetch_pc << '\n';

    auto dec_data = get_decode_stage_data(sim_data.dut);
    sim_data.trace_file << "D;" << dec_data.pc << ";" << dec_data.instr.get() << ";" << (int) dec_data.control.is_bubble << '\n';

    auto exec_data = get_exec_stage_data(sim_data.dut);
    sim_data.trace_file << "E;" << exec_data.pc << ";" << exec_data.instr.get() << ";" << (int) exec_data.control.is_bubble << '\n';

    auto mem_data = get_mem_stage_data(sim_data.dut);
    sim_data.trace_file << "M;" << mem_data.pc << ";" << mem_data.instr.get() << ";" << (int) mem_data.control.is_bubble << '\n';

    auto wb_data = get_wb_stage_data(sim_data.dut);
    sim_data.trace_file << "W;" << wb_data.pc << ";" << wb_data.instr.get() << ";" << (int) wb_data.control.is_bubble << '\n';
}

}

#endif