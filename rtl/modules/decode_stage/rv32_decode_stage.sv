/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_decode_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic set_nop, stop,
    input rv32_word set_nop_pc,
    input fetch_buffer_data_t instr_data,
    output decoded_buffer_data_t decode_data,
    output logic stall,
    // Register file read I/O
    output rv_reg_id_t rs1, rs2,
    input rv32_word reg1, reg2,
    // Hazzard detection I/O
    input exec_buffer_data_t exec_buff
);

decoded_buffer_data_t internal_data /*verilator public*/;
decoded_instr_t decoder_output;

logic [1:0] use_rs /*verilator public*/;
logic hazzard_stall;
bypass_t bypass_rs[2];

rv32_decoder decoder(
    .use_rs(use_rs),
    .instr(instr_data.instr),
    .decoded_instr(decoder_output)
);

rv32_hazzard_detection_unit hazzard_detection(
    .use_rs(use_rs),
    .current_instr(instr_data.instr),
    .decoded_buff(decode_data),
    .exec_buff(exec_buff),
    .stall(hazzard_stall),
    .bypass_rs(bypass_rs)
);

// Decode logic
always_comb begin
    // Forward signals
    internal_data.pc = instr_data.pc;
    internal_data.instr = instr_data.instr;

    // Register file data
    rs1 = instr_data.instr.rs1;
    rs2 = instr_data.instr.rs2;
    internal_data.reg1 = reg1;
    internal_data.reg2 = reg2;

    // Default decode
    internal_data.decoded_instr = decoder_output;

    // Hazard detection
    internal_data.decoded_instr.bypass_rs1 = bypass_rs[0];
    internal_data.decoded_instr.bypass_rs2 = bypass_rs[1];
    stall = hazzard_stall;

    if (stall | set_nop) begin
        internal_data.instr = `RV_NOP;
        internal_data.decoded_instr = create_nop_ctrl();
        if (set_nop) internal_data.pc = set_nop_pc;
    end

    if (stop) internal_data = decode_data;

    if(!resetn) begin
        internal_data.instr = `RV_NOP;
        internal_data.decoded_instr = create_nop_ctrl();
        internal_data.pc = 0;
    end
end

always_ff @(posedge clk) begin
    decode_data <= internal_data;
end

endmodule
