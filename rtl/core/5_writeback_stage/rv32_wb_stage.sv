/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_wb_stage(
    // Pipeline I/O
    input mem_wb_buffer_t mem_wb_buff,
    // Mem data input
    input rv32_word mem_data,
    // Register File I/O
    output logic reg_write,
    output rv_reg_id_t rd,
    output rv32_word wb_data
);

rv32_word fixed_load;

rv32_load_fix load_fix(
    .op(mem_wb_buff.decoded_instr.mem_op),
    .addr(mem_wb_buff.mem_addr),
    .raw_load(mem_data),
    .fixed_load(fixed_load)
);

always_comb begin
    reg_write = mem_wb_buff.decoded_instr.register_wb;
    rd = mem_wb_buff.instr.rd;

    // Set mem load result if required
    case (mem_wb_buff.decoded_instr.wb_result_src)
        WB_MEM_DATA: wb_data = fixed_load;
        default: wb_data = mem_wb_buff.wb_result;
    endcase
end

endmodule
