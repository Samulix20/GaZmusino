/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_wb_stage(
    // Pipeline I/O
    input mem_buffer_data_t mem_data,
    // Register File I/O
    output logic reg_write,
    output rv_reg_id_t rd,
    output rv32_word wb_data
);

always_comb begin
    reg_write = mem_data.decoded_instr.register_wb;
    rd = mem_data.instr.rd;
    wb_data = mem_data.wb_result;
end

endmodule
