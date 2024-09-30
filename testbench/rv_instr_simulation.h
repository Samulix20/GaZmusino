#pragma once

#include "rv32_test_utils.h"
#include <cstdint>
#include <vector>

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
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data) = 0;
    };

    class Instr_Sum3 : public SimulatedInstruction {
      public:
        bool match(const Instruction& i) {
            (void) i;
            return true;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            return {
            {true, true, true}, true
            };
        }

        uint32_t execute(
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {
            (void) pipeline_input;
            return bypass_data.reg_data[0] + bypass_data.reg_data[1] + bypass_data.reg_data[2];
        }
    };

    static u8 scales_register_file[8] = {
        0, 1, 2, 3, 4, 5, 6, 7
    };

    class Instr_dsample_fxmadd : public SimulatedInstruction {
      public:
        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_2;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            InstructionR4 instr = instr_to_r4(i);
            bool use_rs1 = instr.fmt != 1;
            return {
                {use_rs1, true, true}, true
            };
        }

        uint32_t execute(
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {

            InstructionR4 instr = instr_to_r4(pipeline_input.instr);

            uint8_t s_id = instr.rm;

            i32 op_a;
            if (instr.fmt == 1) op_a = 7;
            else op_a = bypass_data.reg_data[0];


            int32_t m = op_a * bypass_data.reg_data[1];
            m = m >> scales_register_file[s_id];

            return m + bypass_data.reg_data[2];

        }

    };

    class Instr_fxmadd : public SimulatedInstruction {
      public:
        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_1;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            return {
                {true, true, true}, true
            };
        }

        uint32_t execute(
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {

            uint8_t s_id = pipeline_input.instr.funct3;

            int32_t m = bypass_data.reg_data[0] * bypass_data.reg_data[1];
            m = m >> scales_register_file[s_id];

            return m + bypass_data.reg_data[2];

        }
    };

    class Instr_genum : public SimulatedInstruction {
      public:
        bool match(const Instruction& i) {
            return i.opcode == RV32Types::OPCODE_CUSTOM_0;
        }

        SimulatedControlSignals decode(const Instruction& i) {
            return {
            {false, false, false}, true
            };
        }

        uint32_t execute(
            const DecodeStageData& pipeline_input, 
            const BypassRegisterData& bypass_data
        ) {

            return 7;

        }
    };

    std::vector<SimulatedInstruction*> simulated_instruction_list = {
        new Instr_fxmadd,
        new Instr_genum,
        new Instr_dsample_fxmadd
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
            uint32_t result = sim_instr->execute(exec_input, reg_data);

            // Setup core signals
            exec_output.data_result[0] = result;
            rvtop->rv32_top->core->exec_stage->tb_data = exec_output.get();

            break;
        }

    }

}