/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_mem_stage(
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
mem_wb_buffer_t output_internal_data;
logic ready;

rv32_load_store_unit ld_st_unit(
    .exec_mem_buff(exec_mem_buff),
    .ready(ready),
    .data_request(data_request),
    .request_done(request_done)
);

always_comb begin
    // Forward signals
    internal_data = exec_mem_buff;
    stall = ~ready;
end

always_ff @(posedge clk) begin
    if(!resetn) begin
        mem_wb_buff.instr <= `RV_NOP;
        mem_wb_buff.decoded_instr <= create_nop_ctrl();
        mem_wb_buff.pc <= 0;
    end

    else if (!stall) mem_wb_buff <= internal_data;
end

endmodule
