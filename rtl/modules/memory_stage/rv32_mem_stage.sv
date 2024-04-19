/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_mem_stage(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input exec_buffer_data_t exec_data,
    output mem_buffer_data_t mem_data,
    output logic stall
    // TODO Data Mem I/O
);

mem_buffer_data_t internal_data /*verilator public*/;

always_comb begin
    internal_data.instr = exec_data.instr;
    internal_data.pc = exec_data.pc;
    internal_data.decoded_instr = exec_data.decoded_instr;
    // TODO setup memory stuff
    internal_data.wb_result = exec_data.wb_result;
    stall = 0;

    if(!resetn) begin
        internal_data.instr = `RV_NOP;
        internal_data.pc = 0;
        internal_data.decoded_instr = create_nop_ctrl();
    end

end

always_ff @(posedge clk) begin
    mem_data <= internal_data;
end

endmodule
