#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cassert>
#include <fstream>
#include <string>
#include <map>

#include <elf.h>
#include <unistd.h>

// Device under test headers
#include "Vrv32_top_rv32_types.h"

#include "Vrv32_top.h"
#include "Vrv32_top_rv32_top.h"
#include "Vrv32_top_rv32_core.h"
#include "Vrv32_top_rv32_csr.h"
#include "Vrv32_top_rv32_decode_stage.h"
#include "Vrv32_top_rv32_exec_stage.h"
#include "Vrv32_top_rv32_mem_stage.h"

#ifndef CPP_MEMORY_SIM
#include "Vrv32_top_rv32_main_memory.h"
#include "Vrv32_top_bram_2_port__N100000.h"
#endif

namespace rv32_test {

// Shorter type definitions
using i32 = int32_t;
using u32 = uint32_t;
using i8 = int8_t;
using u8 = uint8_t;

// Pre-declare this function reuquired by exit
std::string profiler_counters_yaml();

// Time point in nanoseconds
using time_point_ns = std::chrono::time_point<std::chrono::system_clock, std::chrono::nanoseconds>;

struct rv32_memory {
    uint32_t max_addr;
    std::unique_ptr<uint8_t> memory;
};

struct rv32_block_cache {
    u32 block_words_size = 4;
    u32 tag;
    uint64_t last_access = 0;
    std::vector<u32> data;

    rv32_block_cache(u32 tag = 0, u32 value = 0)
        : tag(tag), data(block_words_size, value) {}
};

u32 size_cache = 4096; //Bytes
u32 block_size = 16; //Bytes
u32 num_ways = 4;
u32 offset_bits = 2;
bool cache_enable = true;
enum Policy {RANDOM, LRU};

struct rv32_cache_mem {
    uint64_t num_requests = 0, num_hits = 0, num_replaces = 0;
    u32 index_bits, word_bits, mask_index;
    uint8_t delay;
    Policy policy;
    
    std::vector<std::map<uint8_t, rv32_block_cache>> ways;
    
    bool request_active = false;

    rv32_cache_mem() {
        ways.resize(num_ways);
        index_bits = log2(size_cache/block_size) - log2(num_ways);
        word_bits = log2(block_size / 4);
        mask_index = (1 << index_bits) - 1;
        delay = 2;
        policy = LRU;
        srand(time(NULL));
    }

    u8 get_lru_way(u8 index) {
        // Replace line in the least recently used way
        u8 lru_way = 0;
        uint64_t lru_access = ways[0][index].last_access;
        for(int i = 1; i < num_ways; i++){
            if(ways[i][index].last_access < lru_access){
                lru_access = ways[i][index].last_access;
                lru_way = i;
            }
        }
        return lru_way;
    }

    u32 set_request(u32 addr) {
        int free_way = -1;
        int way_index = -1;
        u8 write_way = -1;

        if(!request_active) {
            num_requests++;
            request_active = true;
            u8 index = (addr >> (word_bits + offset_bits)) & mask_index;
            u32 tag = (addr >> (index_bits + word_bits + offset_bits));

            // Check if line exists in any block
            for(auto& way : ways) {
                way_index++;
                if(way.find(index) != way.end()) {
                    if(way[index].tag == tag){
                        num_hits++;
                        way[index].last_access = num_requests;
                        return 0;
                    } 
                } else if (free_way == -1) {
                    free_way = way_index;
                }
            }
             
            if (free_way != -1) {
                write_way = free_way;
            } else {
                switch (policy) {
                    case RANDOM:
                        // Replace line in a random way
                        write_way = rand() % num_ways;
                        break;
                    
                    case LRU:
                        write_way = get_lru_way(index);
                        break;

                    default:
                        break;
                }
                num_replaces++;
            }
            ways[write_way][index].tag = tag;
            ways[write_way][index].last_access = num_requests;
            return delay;
        }
        return delay;
    }

    uint32_t free_request(){
        request_active = false;
        return 0;
    }

    void print_cache_utilization() {
        u32 ways_total_size = (size_cache/block_size) / num_ways;
        for(int i = 0; i < num_ways; i++) {
            printf("Way %d: %d/%d used entries\n", i + 1, ways[0].size(), ways_total_size);
        }
    }
};

struct SimulationData {
    Vrv32_top *dut;
    rv32_memory mem;
    rv32_cache_mem cache_mem;

    // Time measures
    uint64_t sim_time; 
    time_point_ns sim_start;

    // Setup default outputs to std::cout
    std::ofstream stdout_file;
    std::ostream* stdout_file_ptr;

    std::ofstream prof_file;
    std::ostream* prof_file_ptr;

    std::ofstream trace_file;
};

// Simulation Exit code
inline void simulation_exit(SimulationData& sim_data, uint32_t exit_code) {
    // Measure simulation time
    auto sim_end = std::chrono::high_resolution_clock::now();
    auto time_elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(sim_end - sim_data.sim_start);

    // Print profiling counters information in yaml format
    std::ostream& prof_file = *sim_data.prof_file_ptr;
    prof_file << "---\n";
    prof_file << "runtime: " << std::format("\"{:%T}\"", time_elapsed) << "\n";
    prof_file << "exit_status: " << exit_code << '\n';
    prof_file << "sim_cycles: " << sim_data.sim_time / 2 << '\n';
    prof_file << "cache_profiling: \n";
    prof_file << "\trequests: " << sim_data.cache_mem.num_requests << '\n';
    prof_file << "\thits: " << sim_data.cache_mem.num_hits << '\n';
    prof_file << "\tmisses: " << sim_data.cache_mem.num_requests - sim_data.cache_mem.num_hits << '\n';
    prof_file << "\treplaces: " << sim_data.cache_mem.num_replaces << '\n';
    prof_file << "\thit_rate: " << (float)sim_data.cache_mem.num_hits / sim_data.cache_mem.num_requests << '\n';
    prof_file << "\tmiss_rate: " << 1 - (float)sim_data.cache_mem.num_hits / sim_data.cache_mem.num_requests << '\n';
    prof_file << profiler_counters_yaml();

    sim_data.cache_mem.print_cache_utilization();

    // Close log files if open
    if(sim_data.stdout_file.is_open()) sim_data.stdout_file.close();
    if(sim_data.prof_file.is_open()) sim_data.prof_file.close();
    if(sim_data.trace_file.is_open()) sim_data.trace_file.close();

    exit(exit_code);
}

// Utilty using statements
using DecodeStageData = Vrv32_top_decode_exec_buffer_t__struct__0;
using ExecutionStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using MemoryStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using WritebackStageData = MemoryStageData;
using MemoryRequest = Vrv32_top_memory_request_t__struct__0;

using RegisterFileWriteRequest = Vrv32_top_register_write_request_t__struct__0;

using Instruction = Vrv32_top_rv_instr_t__struct__0;
using InstructionR4 = Vrv32_top_rv_r4_instr_t__struct__0;
using CoreControlSignals = Vrv32_top_rv_control_t__struct__0;
using RV32Types = Vrv32_top_rv32_types;

// Instruction format 
inline InstructionR4 instr_to_r4(const Instruction& instr) {
    InstructionR4 r;
    r.set(instr.get());
    return r;
}


// Getters core internal data

// Fetch Stage 
inline uint32_t get_pc(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->pc;
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

// Decode stage

inline Instruction get_decoder_input(const Vrv32_top* rvtop) {
    Instruction i;
    i.set(rvtop->rv32_top->core->decode_stage->internal_instr);
    return i;
}

inline CoreControlSignals get_decoder_output(const Vrv32_top* rvtop) {
    CoreControlSignals decoder_output;
    decoder_output.set(rvtop->rv32_top->core->decode_stage->decoder_output);
    return decoder_output;
}

inline DecodeStageData get_decode_stage_data(const Vrv32_top* rvtop) {
    DecodeStageData d;
    d.set(rvtop->rv32_top->core->decode_stage->internal_data);
    return d;
}

inline uint8_t get_decode_stall(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->dec_stall;
}

// Exec stage

inline DecodeStageData get_exec_stage_input(const Vrv32_top* rvtop) {
    DecodeStageData d;
    d.set(rvtop->rv32_top->core->decode_exec_buff);
    return d;
}

struct BypassRegisterData {
    uint32_t reg_data[RV32Types::CORE_RF_NUM_READ];
};
inline BypassRegisterData get_exec_bypass_register_data(const Vrv32_top* rvtop) {
    BypassRegisterData r;
    for(size_t i = 0; i < RV32Types::CORE_RF_NUM_READ; i++) {
        r.reg_data[i] = rvtop->rv32_top->core->exec_stage->reg_data[i];
    }
    return r;
}

inline ExecutionStageData get_exec_stage_data(const Vrv32_top* rvtop) {
    ExecutionStageData d;
    d.set(rvtop->rv32_top->core->exec_stage->internal_data);
    return d;
}

// Memory stage

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


// Writeback stage

inline uint32_t get_wb_result_data(const Vrv32_top* rvtop) {
    RegisterFileWriteRequest rfwr;
    rfwr.set(rvtop->rv32_top->core->rf_write_request);
    return rfwr.data;
}

// Internal profiler counters
// Standard ISA

inline uint64_t get_mcycle(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->csr_file->mcycle;
}

inline uint64_t get_minstret (const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->csr_file->minstret;
}

// Custom counters

inline uint64_t get_mjmp (const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->csr_file->mjmp;
}

inline uint64_t get_mdecstall (const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->csr_file->mdecstall;
}

}

#endif