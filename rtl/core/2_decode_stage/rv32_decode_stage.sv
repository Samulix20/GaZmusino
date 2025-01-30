/* verilator lint_off UNUSEDSIGNAL */

/*
 CPU 2 decode stage
 - Decode
 - Data Hazzard detection
*/

module rv32_decode_stage
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic stop,
    input jump_request_t jump_request,
    input interrupt_request_t interrupt_request,
    input fetch_decode_buffer_t fetch_decode_buff,
    output decode_exec_buffer_t decode_exec_buff,
    output logic stall,
    // Memory I
    input rv_instr_t instr,
    // Register file data input
    input rv32_word [CORE_RF_NUM_READ - 1:0] reg_data,
    // CSR file data input
    input rv32_word csr_data,
    // Hazzard detection I/O
    input exec_mem_buffer_t exec_mem_buff
);

decode_exec_buffer_t internal_data /*verilator public*/;
decode_exec_buffer_t output_internal_data /*verilator public*/;

// Small logic to support fetch bubbles
rv_instr_t internal_instr /*verilator public*/;
always_comb begin
    if (fetch_decode_buff.generate_nop) internal_instr = RV_NOP;
    else internal_instr = instr;
end

logic tb_dec /*verilator public*/;
logic tb_use_rs [CORE_RF_NUM_READ] /*verilator public*/;
rv_control_t tb_control /*verilator public*/;

logic decoder_use_rs [CORE_RF_NUM_READ];
rv_control_t decoder_output /*verilator public*/;

rv32_decoder decoder(
    .instr(internal_instr),
    .use_rs(decoder_use_rs),
    .control(decoder_output)
);

logic use_rs  [CORE_RF_NUM_READ] /*verilator public*/;
rv_control_t control_signals /*verilator public*/;
always_comb begin
    if (tb_dec) begin 
        use_rs = tb_use_rs;
        control_signals = tb_control;
    end else begin 
        use_rs = decoder_use_rs;
        control_signals = decoder_output;
    end
end

bypass_t [CORE_RF_NUM_READ - 1:0] bypass_rs;
logic hazzard_stall;

rv32_hazzard_detection_unit hazzard_detection(
    .use_rs(use_rs),
    .current_instr(internal_instr),
    .current_control(control_signals),
    .decode_exec_buff(decode_exec_buff),
    .exec_mem_buff(exec_mem_buff),
    .stall(hazzard_stall),
    .bypass_rs(bypass_rs)
);

// Decode logic
// Final stall control and register write
always_comb begin
    // Forward signals
    internal_data.pc = fetch_decode_buff.pc;
    internal_data.instr = internal_instr;

    // Register file data
    internal_data.reg_data = reg_data;

    // Default decode
    internal_data.control = control_signals;

    // Hazard detection
    internal_data.control.bypass_rs = bypass_rs;
    stall = hazzard_stall;

    // If CSR instruction advance read csr
    if (internal_data.control.wb_result_src == WB_CSR) begin
        internal_data.reg_data[2] = csr_data;
    end

    // Generate NOP control also
    if (fetch_decode_buff.generate_nop) begin
        internal_data.control = create_bubble_ctrl();
    end

    output_internal_data = internal_data;

    if (stall | jump_request.do_jump) begin
        output_internal_data.instr = RV_NOP;
        output_internal_data.control = create_bubble_ctrl();
        if (jump_request.do_jump) output_internal_data.pc = jump_request.from;
    end

    if (interrupt_request.do_interrupt) begin 
        output_internal_data.instr = RV_NOP;
        output_internal_data.control = create_bubble_ctrl();
        output_internal_data.pc = interrupt_request.from;
    end

end

always_ff @(posedge clk) begin
    if (!resetn) begin
        decode_exec_buff.instr <= RV_NOP;
        decode_exec_buff.control <= create_bubble_ctrl();
        decode_exec_buff.pc <= 0;
    end
    else if (!stop) begin
        decode_exec_buff <= output_internal_data;
    end
end

endmodule
