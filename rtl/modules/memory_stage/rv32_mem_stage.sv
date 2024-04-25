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
    input memory_response_t data_response
);

mem_wb_buffer_t internal_data /*verilator public*/;
mem_wb_buffer_t output_internal_data;

memory_response_t ld_st_res;

rv32_load_store_unit ld_st_unit(
    .exec_mem_buff(exec_mem_buff),
    .response(ld_st_res),
    .data_request(data_request),
    .data_response(data_response)
);

always_comb begin
    // Forward signals
    internal_data.instr = exec_mem_buff.instr;
    internal_data.pc = exec_mem_buff.pc;
    internal_data.decoded_instr = exec_mem_buff.decoded_instr;

    // Set mem load result if required
    case (exec_mem_buff.decoded_instr.wb_result_src)
        WB_MEM_DATA: internal_data.wb_result = ld_st_res.data;
        default: internal_data.wb_result = exec_mem_buff.wb_result;
    endcase

    stall = ~ld_st_res.ready;
end

always_comb begin
    output_internal_data = internal_data;
end

always_ff @(posedge clk) begin
    if(!resetn) begin
        mem_wb_buff.instr <= `RV_NOP;
        mem_wb_buff.decoded_instr <= create_nop_ctrl();
        mem_wb_buff.pc <= 0;
    end

    else if (!stall) mem_wb_buff <= output_internal_data;
end

endmodule
