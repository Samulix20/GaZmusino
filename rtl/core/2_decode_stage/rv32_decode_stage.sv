/* verilator lint_off UNUSEDSIGNAL */

module rv32_decode_stage
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic set_nop, stop,
    input rv32_word set_nop_pc,
    input fetch_decode_buffer_t fetch_decode_buff,
    output decode_exec_buffer_t decode_exec_buff,
    output logic stall,
    // Memory I
    input rv_instr_t instr,
    // Register file data input
    input rv32_word reg_data[3],
    // Hazzard detection I/O
    input exec_mem_buffer_t exec_mem_buff
);

decode_exec_buffer_t internal_data /*verilator public*/;
decode_exec_buffer_t output_internal_data /*verilator public*/;
decoded_instr_t decoder_output;

// Small logic to support fetch bubbles
rv_instr_t internal_instr;
always_comb begin
    if (fetch_decode_buff.generate_nop) internal_instr = RV_NOP;
    else internal_instr = instr;
end

logic use_rs[3] /*verilator public*/;
bypass_t bypass_rs[3];
logic hazzard_stall;

rv32_decoder decoder(
    .use_rs(use_rs),
    .instr(internal_instr),
    .decoded_instr(decoder_output)
);

rv32_hazzard_detection_unit hazzard_detection(
    .use_rs(use_rs),
    .current_instr(internal_instr),
    .decode_exec_buff(decode_exec_buff),
    .exec_mem_buff(exec_mem_buff),
    .stall(hazzard_stall),
    .bypass_rs(bypass_rs)
);

// Decode logic
always_comb begin
    // Forward signals
    internal_data.pc = fetch_decode_buff.pc;
    internal_data.instr = internal_instr;

    // Register file data
    internal_data.reg1 = reg_data[0];
    internal_data.reg2 = reg_data[1];

    // Default decode
    internal_data.decoded_instr = decoder_output;

    // Hazard detection
    internal_data.decoded_instr.bypass_rs1 = bypass_rs[0];
    internal_data.decoded_instr.bypass_rs2 = bypass_rs[1];
    stall = hazzard_stall;
end

always_comb begin
    output_internal_data = internal_data;

    if (stall | set_nop) begin
        output_internal_data.instr = RV_NOP;
        output_internal_data.decoded_instr = create_nop_ctrl();
        if (set_nop) output_internal_data.pc = set_nop_pc;
    end

end

always_ff @(posedge clk) begin
    if (!resetn) begin
        decode_exec_buff.instr <= RV_NOP;
        decode_exec_buff.decoded_instr <= create_nop_ctrl();
        decode_exec_buff.pc <= 0;
    end
    else if (!stop) begin
        decode_exec_buff <= output_internal_data;
    end
end

endmodule
