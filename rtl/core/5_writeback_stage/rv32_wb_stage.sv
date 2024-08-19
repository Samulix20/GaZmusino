/* verilator lint_off UNUSEDSIGNAL */

/*
 CPU 5 writeback stage
 - Load data fixing
 - Register file write
*/

module rv32_wb_stage
import rv32_types::*;
(
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
    .op(mem_wb_buff.control.mem_op),
    .addr(mem_wb_buff.data_result[1]),
    .raw_load(mem_data),
    .fixed_load(fixed_load)
);

always_comb begin
    // Register file write control
    reg_write = mem_wb_buff.control.register_wb;
    rd = mem_wb_buff.instr.rd;

    // Writeback data
    // Set mem load result if required
    case (mem_wb_buff.control.wb_result_src)
        WB_MEM_DATA: wb_data = fixed_load;
        default: wb_data = mem_wb_buff.data_result[0];
    endcase
end

endmodule
