/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_mem_stage(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input exec_buffer_data_t exec_data,
    output mem_buffer_data_t mem_data,
    output logic stall,
    // Data Mem I/O
    output memory_request_t data_request,
    input memory_response_t data_response
);

mem_buffer_data_t internal_data /*verilator public*/;

memory_response_t ld_st_res;

rv32_load_store_unit ld_st_unit(
    .exec_data(exec_data),
    .response(ld_st_res),
    .data_request(data_request),
    .data_response(data_response)
);

always_comb begin
    // Forward signals
    internal_data.instr = exec_data.instr;
    internal_data.pc = exec_data.pc;
    internal_data.decoded_instr = exec_data.decoded_instr;

    // Set mem load result if required
    case (exec_data.decoded_instr.wb_result_src)
        WB_MEM_DATA: internal_data.wb_result = ld_st_res.data;
        default: internal_data.wb_result = exec_data.wb_result;
    endcase

    //stall = ~ld_st_res.ready;
    stall = 0;

    if(!resetn | stall) begin
        internal_data.instr = `RV_NOP;
        internal_data.pc = 0;
        internal_data.decoded_instr = create_nop_ctrl();
    end

end

always_ff @(posedge clk) begin
    mem_data <= internal_data;
end

endmodule
