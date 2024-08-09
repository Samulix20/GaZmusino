#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <elf.h>
#include <cassert>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <format>

// Device under test headers
#include "Vrv32_top_rv32_types.h"

#include "Vrv32_top.h"
#include "Vrv32_top_rv32_top.h"
#include "Vrv32_top_rv32_core.h"
#include "Vrv32_top_rv32_decode_stage.h"
#include "Vrv32_top_rv32_exec_stage.h"
#include "Vrv32_top_rv32_mem_stage.h"

#ifndef CPP_MEMORY_SIM
#include "Vrv32_top_rv32_main_memory.h"
#include "Vrv32_top_bram_2_port__N100000.h"
#endif

// Bsp defines config
#include "../bsp/include/riscv/config.h"

namespace rv32_test {

// Utilty using statements
using DecodeStageData = Vrv32_top_decode_exec_buffer_t__struct__0;
using ExecutionStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using MemoryStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using WritebackStageData = MemoryStageData;
using MemoryRequest = Vrv32_top_memory_request_t__struct__0;

using Instruction = Vrv32_top_rv_instr_t__struct__0;
using DecodedInstruction = Vrv32_top_decoded_instr_t__struct__0;
using RV32Types = Vrv32_top_rv32_types;

// Getters core internal data
inline DecodeStageData get_decode_stage_data(const Vrv32_top* rvtop) {
    DecodeStageData d;
    d.set(rvtop->rv32_top->core->decode_stage->internal_data);
    return d;
}

inline ExecutionStageData get_exec_stage_data(const Vrv32_top* rvtop) {
    ExecutionStageData d;
    d.set(rvtop->rv32_top->core->exec_stage->internal_data);
    return d;
}

inline MemoryStageData get_mem_stage_data(const Vrv32_top* rvtop) {
    MemoryStageData d;
    d.set(rvtop->rv32_top->core->mem_stage->internal_data);
    return d;
}

inline WritebackStageData get_wb_stage_data(const Vrv32_top* rvtop) {
    WritebackStageData d;
    d.set(rvtop->rv32_top->core->mem_wb_buff);
    return d;
}

inline uint32_t get_wb_result_data(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->wb_data;
}

inline uint32_t get_next_pc(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->next_pc;
}

inline MemoryRequest get_instruction_request(const Vrv32_top* rvtop) {
    MemoryRequest instruction_request;
    instruction_request.set(rvtop->core_instr_request);
    return instruction_request;
}

inline uint32_t get_instruction_response(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->instr;
}

inline MemoryRequest get_memory_request(const Vrv32_top* rvtop) {
    MemoryRequest request;
    request.set(rvtop->mmio_data_request);
    return request;
}

inline uint32_t get_memory_response(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core_data;
}

inline uint8_t get_memory_stall(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->mem_stall;
}

inline uint8_t get_decode_stall(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->dec_stall;
}

inline uint8_t get_exec_jump(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->exec_jump;
}

using DissasemblyMap = std::unordered_map<uint32_t, std::string>;

inline DissasemblyMap load_dissasembly(std::string filename) {
    DissasemblyMap m;
    std::stringstream ss;
    std::string line = "", pc_token = "", instr_token = "";

    std::ifstream f = std::ifstream(filename);
    if (!f.is_open()) return m;

    while(!f.eof()) {
        getline(f, line);
        if (line == "") continue; // Guard for empty lines
        ss.clear();
        ss << line;
        getline(ss, pc_token, ';');
        getline(ss, instr_token, ';');
        m[std::stoi(pc_token)] = instr_token;
    }

    return m;
}

}

#endif
