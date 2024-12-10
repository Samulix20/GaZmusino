#pragma once

#include "rv32_test_utils.h"
#include <cstdint>
#include <vector>

#include <iostream>

namespace rv32_test {

    struct SimulatedControlSignals {
        bool use_rs[RV32Types::CORE_RF_NUM_READ];
        bool wb;
    };

    class SimulatedInstruction {
      public:
        virtual bool match(const Instruction& i) = 0;

        virtual SimulatedControlSignals decode(const Instruction& i) = 0;

        virtual uint32_t execute(
            const u8 clk,
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) = 0;
    };

    class Instr_genum : public SimulatedInstruction {

        u32 rng_seed = 0xDEADBEEF;

        // https://en.wikipedia.org/wiki/Xorshift
        u32 xorshift32(u32 seed) {
            u32 x = seed;
            x ^= x << 13;
            x ^= x >> 17;
            x ^= x << 5;
            return x;
        }

      public:
        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_0;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            (void) i;
            return {
            {false, false, false}, true
            };
        }

        uint32_t execute(
            const u8 clk,
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {
            (void) pipeline_input;
            (void) bypass_data;
            if (clk == 1) rng_seed = xorshift32(rng_seed);
            return rng_seed >> (32 - 10);
        }
    };

    class Instr_fxmadd : public SimulatedInstruction {

        u8 scales[8];

      public: 

        Instr_fxmadd() {
            scales[0] = 10;
        }

        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_1;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            (void) i;
            return {
                {true, true, true}, true
            };
        }

        u32 execute(
            const u8 clk,
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {
            (void) pipeline_input;
            (void) bypass_data;
            (void) clk;

            i32 aux = (i32) bypass_data.reg_data[0] * (i32) bypass_data.reg_data[1];
            aux = aux >> scales[0];
            return aux + (i32) bypass_data.reg_data[2];
        }

    };

    class Instr_dsample : public SimulatedInstruction {
        u8 scales[8];

        u32 rng_seed = 0xDEADBEEF;

        // https://en.wikipedia.org/wiki/Xorshift
        u32 xorshift32(u32 seed) {
            u32 x = seed;
            x ^= x << 13;
            x ^= x >> 17;
            x ^= x << 5;
            return x;
        }

      public:

        Instr_dsample() {
            scales[0] = 10;
        }

        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_2;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            (void) i;
            return {
                {true, true, false}, true
            };
        }

        u32 execute(
            const u8 clk,
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {
            (void) pipeline_input;
            (void) bypass_data;
            (void) clk;

            if (clk == 1) rng_seed = xorshift32(rng_seed);
            u32 u = rng_seed >> (32 - scales[0]);
            i32 aux = (i32) u * (i32) bypass_data.reg_data[0];
            aux = aux >> scales[0];
            return aux + (i32) bypass_data.reg_data[1];
        }
    };

    static std::vector<SimulatedInstruction*> simulated_instruction_list = {
        new Instr_genum,
        new Instr_fxmadd
    };

    inline bool invalid_decode(const Vrv32_top* rvtop) {
        return get_decoder_output(rvtop).invalid == 1;
    }

    inline bool invalid_execute(const Vrv32_top* rvtop) {
        return get_exec_stage_input(rvtop).control.invalid == 1;
    }

    inline void simulate_decode(Vrv32_top* rvtop) {
        // Default do not simulate
        rvtop->rv32_top->core->decode_stage->tb_dec = 0;

        // Check invalid instruction
        if (!invalid_decode(rvtop)) return;

        Instruction instr = get_decoder_input(rvtop);
        CoreControlSignals core_ctrl = get_decoder_output(rvtop);

        for (SimulatedInstruction* sim_instr : simulated_instruction_list) {
            if (!sim_instr->match(instr)) continue; 

            // Simulated instruction match
            rvtop->rv32_top->core->decode_stage->tb_dec = 1;

            // Get control signals
            SimulatedControlSignals ctrl = sim_instr->decode(instr);

            // Setup core control signals
            for(size_t i = 0; i < RV32Types::CORE_RF_NUM_READ; i++) {
                rvtop->rv32_top->core->decode_stage->tb_use_rs[i] = ctrl.use_rs[i]; 
            }
            core_ctrl.register_wb = ctrl.wb;
            rvtop->rv32_top->core->decode_stage->tb_control = core_ctrl.get();
            
            break;
        }
    }

    inline void simulate_execute(Vrv32_top* rvtop) {
        // Default do not simulate
        rvtop->rv32_top->core->exec_stage->tb_exec = 0;

        // Check invalid instruction
        if (!invalid_execute(rvtop)) return;

        // Stage Input/Output
        DecodeStageData exec_input = get_exec_stage_input(rvtop);
        ExecutionStageData exec_output = get_exec_stage_data(rvtop);

        for (SimulatedInstruction* sim_instr : simulated_instruction_list) {
            if (!sim_instr->match(exec_input.instr)) continue;

            // Simulated instruction match
            rvtop->rv32_top->core->exec_stage->tb_exec = 1;

            // Get data
            BypassRegisterData reg_data = get_exec_bypass_register_data(rvtop);

            // Run instruction function
            uint32_t result = sim_instr->execute(rvtop->clk, exec_input, reg_data);

            // Setup core signals
            exec_output.data_result[0] = result;
            rvtop->rv32_top->core->exec_stage->tb_data = exec_output.get();

            break;
        }

    }

}