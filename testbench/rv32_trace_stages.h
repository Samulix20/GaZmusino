#ifndef RV32_TRACE_STAGES
#define RV32_TRACE_STAGES

#include "rv32_test_utils.h"
#include "verilated.h"

#include <cstdint>
#include <unordered_map>
#include <format>
#include <iostream>

namespace rv32_test {

inline std::string opcode_str(Instruction instr) {
    std::string str;
    static const std::unordered_map<RV32Types::valid_opcodes_t, std::string> str_map = {
        {RV32Types::OPCODE_LUI, "LUI"},
        {RV32Types::OPCODE_AUIPC, "AUIPC"},
        {RV32Types::OPCODE_JAL, "JAL"},
        {RV32Types::OPCODE_JALR, "JALR"},
        {RV32Types::OPCODE_BRANCH, "BRANCH"},
        {RV32Types::OPCODE_LOAD, "LOAD"},
        {RV32Types::OPCODE_STORE, "STORE"},
        {RV32Types::OPCODE_INTEGER_IMM, "INT IMM"},
        {RV32Types::OPCODE_INTEGER_REG, "INT REG"},
        {RV32Types::OPCODE_ZICSR, "ZICSR"},
        {RV32Types::OPCODE_BARRIER, "BARRIER"}
    };
    auto it = str_map.find(static_cast<RV32Types::valid_opcodes_t>(instr.opcode));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    return str;
}

inline std::string bypass_str(Instruction instr, DecodedInstruction dec_instr) {
    static const std::unordered_map<RV32Types::bypass_t, std::string> str_map = {
        {RV32Types::NO_BYPASS, "NO"},
        {RV32Types::BYPASS_EXEC_BUFF, "EXEC"},
        {RV32Types::BYPASS_MEM_BUFF, "MEM"}
    };

    std::string s = "";

    for (uint32_t i = 0; i < 2; i++) {
        RV32Types::bypass_t bypass;
        std::string rs, b_op;

        if (i == 0) {
            bypass = static_cast<RV32Types::bypass_t>(dec_instr.bypass_rs[0]);
            rs = "rs1(x" + std::to_string(instr.rs1) + ")";
        } else {
            bypass = static_cast<RV32Types::bypass_t>(dec_instr.bypass_rs[1]);
            rs = "rs2(x" + std::to_string(instr.rs2) + ")";
        }

        auto it = str_map.find(bypass);
        if (it != str_map.end()) b_op = it->second;
        else b_op = "NO";

        if (b_op == "NO") continue;

        s += "!" + b_op + " " + rs + " ";
    }

    return s;
}

inline std::string rename_imm_str(std::string op, DecodedInstruction dec_instr) {
    static const std::unordered_map<RV32Types::instr_type_t, std::string> str_map = {
        {RV32Types::INSTR_R_TYPE, "???"},
        {RV32Types::INSTR_I_TYPE, "I_IMM"},
        {RV32Types::INSTR_S_TYPE, "S_IMM"},
        {RV32Types::INSTR_B_TYPE, "B_IMM"},
        {RV32Types::INSTR_U_TYPE, "U_IMM"},
        {RV32Types::INSTR_J_TYPE, "J_IMM"}
    };

    if (op != "IMM") return op;

    auto it = str_map.find(static_cast<RV32Types::instr_type_t>(dec_instr.t));
    if (it != str_map.end()) op = it->second;
    else op = "???";
    return op;
}

inline std::string alu_input_str(Instruction instr, DecodedInstruction dec_instr) {
    std::string op1, op2;
    static const std::unordered_map<RV32Types::int_alu_input_t, std::string> str_map = {
        {RV32Types::ALU_IN_ZERO, "0"},
        {RV32Types::ALU_IN_REG_1, "R1"},
        {RV32Types::ALU_IN_REG_2, "R2"},
        {RV32Types::ALU_IN_PC, "PC"},
        {RV32Types::ALU_IN_IMM, "IMM"}
    };
    auto it = str_map.find(
        static_cast<RV32Types::int_alu_input_t>(dec_instr.int_alu_input[0]));
    if (it != str_map.end()) op1 = it->second;
    else op1 = "???";

    if(op1 == "R1") op1 = "rs1(x" + std::to_string(instr.rs1) + ")";
    else if(op1 == "R2") op1 = "rs2(x" + std::to_string(instr.rs2) + ")";

    it = str_map.find(
        static_cast<RV32Types::int_alu_input_t>(dec_instr.int_alu_input[1]));
    if (it != str_map.end()) op2 = it->second;
    else op2 = " ???";

    if(op2 == "R1") op2 = "rs1(x" + std::to_string(instr.rs1) + ")";
    else if(op2 == "R2") op2 = "rs2(x" + std::to_string(instr.rs2) + ")";

    op1 = rename_imm_str(op1, dec_instr);
    op2 = rename_imm_str(op2, dec_instr);

    return op1 + " " + op2;
}

inline std::string alu_op_str(DecodedInstruction instr) {
    std::string str;
    static const std::unordered_map<RV32Types::int_alu_op_t, std::string> str_map = {
        {RV32Types::ALU_OP_ADD, "ADD"},
        {RV32Types::ALU_OP_SLL, "SLL"},
        {RV32Types::ALU_OP_SLT, "SLT"},
        {RV32Types::ALU_OP_SLTU, "SLTU"},
        {RV32Types::ALU_OP_XOR, "XOR"},
        {RV32Types::ALU_OP_SRL, "SRL"},
        {RV32Types::ALU_OP_OR, "OR"},
        {RV32Types::ALU_OP_AND, "AND"},
        {RV32Types::ALU_OP_SRA, "SRA"},
        {RV32Types::ALU_OP_SUB, "SUB"}
    };
    auto it = str_map.find(static_cast<RV32Types::int_alu_op_t>(instr.int_alu_op));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    return str;
}

// If jump != NOP "[BRANCH_OP]"
inline std::string branch_op_str(DecodedInstruction instr) {
    std::string str;
    static const std::unordered_map<RV32Types::branch_op_t, std::string> str_map = {
        {RV32Types::OP_BEQ, "BEQ"},
        {RV32Types::OP_BNE, "BNE"},
        {RV32Types::OP_BLT, "BLT"},
        {RV32Types::OP_BGE, "BGE"},
        {RV32Types::OP_BLTU, "BLTU"},
        {RV32Types::OP_BGEU, "BGEU"},
        {RV32Types::OP_J, "J"},
        {RV32Types::OP_NOP, "NOP"}
    };
    auto it = str_map.find(static_cast<RV32Types::branch_op_t>(instr.branch_op));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    if(str == "NOP") str = "";
    return str;
}

// If writeback "[WB_SRC] -> x[rd]"
inline std::string wb_src_str(Instruction instr, DecodedInstruction dec_instr) {
    std::string s = "";

    static const std::unordered_map<RV32Types::wb_result_t, std::string> str_map = {
        {RV32Types::WB_PC4, "PC4"},
        {RV32Types::WB_INT_ALU, "ALU"},
        {RV32Types::WB_MEM_DATA, "MEM"}
    };
    auto it = str_map.find(
        static_cast<RV32Types::wb_result_t>(dec_instr.wb_result_src));
    if (it != str_map.end()) s = it->second;
    else s = "???";

    if (dec_instr.register_wb) {
        s += " -> x" + std::to_string(instr.rd);
    } else {
        s = "";
    }

    return s;
}

// If writeback "x[rd] <- [wb_result]"
inline std::string wb_write_str(const Vrv32_top* rvtop) {
    auto wbd = get_wb_stage_data(rvtop);
    auto wb_result = get_wb_result_data(rvtop);

    std::string s = "";
    if (wbd.decoded_instr.register_wb) {
        s += "x" + std::to_string(wbd.instr.rd) + 
            " <- " + std::format("{:<#10x}", wb_result);
    }
    return s;
}

inline std::string decode_register_usage_str(const Vrv32_top* rvtop) {
    std::string s = "";
    auto usage = rvtop->rv32_top->core->decode_stage->use_rs;
    Instruction instr = get_decode_stage_data(rvtop).instr;
    if(usage[0]) s += "rs1(x" + std::to_string(instr.rs1) + ") ";
    if(usage[1]) s += "rs2(x" + std::to_string(instr.rs2) + ") ";
    if(usage[2]) s += "rs3(x" + std::to_string(instr.rd) + ") ";
    if(s != "") s = "Uses " + s;
    return s;
}

inline std::string mem_op_str(const Vrv32_top* rvtop) {
    MemoryRequest request = get_memory_request(rvtop);

    std::string s = "";
    static const std::unordered_map<RV32Types::mem_op_t, std::string> str_map = {
        {RV32Types::MEM_LB, "LB"},
        {RV32Types::MEM_LH, "LH"},
        {RV32Types::MEM_LW, "LW"},
        {RV32Types::MEM_LBU, "LBU"},
        {RV32Types::MEM_LHU, "LHU"},
        {RV32Types::MEM_SB, "SB"},
        {RV32Types::MEM_SH, "SH"},
        {RV32Types::MEM_SW, "SW"},
        {RV32Types::MEM_NOP, "NO MEM"}
    };
    auto it = str_map.find(static_cast<RV32Types::mem_op_t>(request.op));
    if (it != str_map.end()) s = it->second;
    else s = "???";

    if (s == "NO MEM") s = "";
    else if (s[0] == 'S') {
        s = std::format("{} [{:#x}] <- {:#x}", s, request.addr, request.data);
    } else {
        s = std::format("{} [{:#x}]", s, request.addr);
    }

    return s;
}

inline std::string dissasembled_isntr(
    const DissasemblyMap& dmap, uint32_t pc, uint32_t instr) {

    if (instr == 0x33) return "asm nop";

    auto it = dmap.find(pc);
    if (it == dmap.end()) return "asm ???";
    else return "asm " + it->second;
}

class TraceCanvas {
  public:
    uint32_t stages;
    uint32_t lines;
    std::vector<std::vector<std::string>> canvas;

    TraceCanvas(uint32_t num_stages, uint32_t num_lines): 
        stages(num_stages), lines(num_lines) {

        for(uint32_t i = 0; i < stages; i++) {
            auto s = std::vector<std::string>();
            for(uint32_t j = 0; j < lines; j++) {
                s.push_back("");
            }
            canvas.push_back(s);
        }
    }

    void print() {
        std::string s = "";
        for(uint32_t j = 0; j < lines; j++) {
            for(uint32_t i = 0; i < stages; i++) {
                s += std::format("|{:<30}", canvas[i][j]);
            }
            s += "|\n";
        }

        for(uint32_t i = 0; i < stages; i++) {
            s += std::format("|{:=^30}", "");
        }
        s += "|\n";
        std::cout << s;
    }
};

inline void trace_stages(const Vrv32_top* rvtop, const DissasemblyMap& dmap) {
    auto tc = TraceCanvas(5, 6);

    auto instr_request = get_instruction_request(rvtop);

    tc.canvas[0][0] = 
        std::format("@ {:<#10x} ", instr_request.addr);
    tc.canvas[0][1] = std::format("@ <- {:<#10x}", get_next_pc(rvtop));

    auto decode_data = get_decode_stage_data(rvtop);
    tc.canvas[1][0] = std::format("@ {:<#10x} I {:<#10x}", 
        decode_data.pc, decode_data.instr.get());
    tc.canvas[1][1] = dissasembled_isntr(dmap, decode_data.pc, decode_data.instr.get());
    if (decode_data.instr.get() != 0x33) {
        tc.canvas[1][2] = "Opcode " + opcode_str(decode_data.instr);
        tc.canvas[1][3] = decode_register_usage_str(rvtop);
        tc.canvas[1][4] = bypass_str(decode_data.instr, decode_data.decoded_instr);
        tc.canvas[1][5] = get_decode_stall(rvtop) == 1 ? "STALL!" : "";
    }

    auto exec_data = get_exec_stage_data(rvtop);
    tc.canvas[2][0] = std::format("@ {:<#10x} I {:<#10x}", 
        exec_data.pc, exec_data.instr.get());
    tc.canvas[2][1] = dissasembled_isntr(dmap, exec_data.pc, exec_data.instr.get());
    if (exec_data.instr.get() != 0x33) {
        tc.canvas[2][2] = wb_src_str(exec_data.instr, exec_data.decoded_instr);
        tc.canvas[2][3] = alu_op_str(exec_data.decoded_instr) + " " +
            alu_input_str(exec_data.instr, exec_data.decoded_instr);
        tc.canvas[2][4] = branch_op_str(exec_data.decoded_instr) + " " +
            (get_exec_jump(rvtop) == 1 ? "JUMP!" : "");
    }

    auto mem_data = get_mem_stage_data(rvtop);
    tc.canvas[3][0] = 
        std::format("@ {:<#10x} I {:<#10x}", mem_data.pc, mem_data.instr.get());
    tc.canvas[3][1] = dissasembled_isntr(dmap, mem_data.pc, mem_data.instr.get());
    if (mem_data.instr.get() != 0x33) {
        tc.canvas[3][2] = wb_src_str(mem_data.instr, mem_data.decoded_instr);
        tc.canvas[3][3] = mem_op_str(rvtop);
        tc.canvas[3][5] = get_memory_stall(rvtop) == 1 ? "STALL!" : "";
    }

    auto wb_data = get_wb_stage_data(rvtop);
    tc.canvas[4][0] = 
        std::format("@ {:<#10x} I {:<#10x}", wb_data.pc, wb_data.instr.get());
    tc.canvas[4][1] = dissasembled_isntr(dmap, wb_data.pc, wb_data.instr.get());
    if (wb_data.instr.get() != 0x33) {
        tc.canvas[4][2] = wb_write_str(rvtop);
    }

    tc.print();
}
}

#endif