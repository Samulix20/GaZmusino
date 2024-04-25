/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_wb_stage(
    // Pipeline I/O
    input mem_wb_buffer_t mem_wb_buff,
    // Register File I/O
    output logic reg_write,
    output rv_reg_id_t rd,
    output rv32_word wb_data
);

always_comb begin
    reg_write = mem_wb_buff.decoded_instr.register_wb;
    rd = mem_wb_buff.instr.rd;
    wb_data = mem_wb_buff.wb_result;
end

endmodule
