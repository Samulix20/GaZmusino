/* verilator lint_off UNUSEDSIGNAL */

/*
 CPU 4 memory stage
 - Memory requests
*/


module rv32_mem_stage
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input exec_mem_buffer_t exec_mem_buff,
    output mem_wb_buffer_t mem_wb_buff,
    output logic stall,
    // Data Mem I/O
    output memory_request_t data_request,
    input logic request_done
);

mem_wb_buffer_t internal_data /*verilator public*/;

always_comb begin
    data_request.addr = exec_mem_buff.mem_addr;
    data_request.op = exec_mem_buff.decoded_instr.mem_op;
    data_request.data = exec_mem_buff.wb_result;
end

always_comb begin
    // Forward signals
    internal_data = exec_mem_buff;
    if (exec_mem_buff.decoded_instr.mem_op == MEM_NOP) stall = 0;
    else stall = ~request_done;
end

always_ff @(posedge clk) begin
    if(!resetn) begin
        mem_wb_buff.instr <= RV_NOP;
        mem_wb_buff.decoded_instr <= create_nop_ctrl();
        mem_wb_buff.pc <= 0;
    end

    else if (!stall) mem_wb_buff <= internal_data;
end

endmodule
