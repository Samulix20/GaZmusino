/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_hazzard_detection_unit (
    input logic[1:0] use_rs,
    input rv_instr_t current_instr,
    input decoded_buffer_data_t decoded_buff,
    input exec_buffer_data_t exec_buff,
    output logic stall,
    output bypass_t bypass_rs[2]
);

always_comb begin
    stall = 0;

    for(int idx = 0; idx < 2; idx = idx + 1) begin
        rv_reg_id_t rs;
        bypass_rs[idx] = NO_BYPASS;

        if (idx == 0) rs = current_instr.rs1;
        else rs = current_instr.rs2;

        // Mem instructions always generate a bubble, structural hazzard
        if (decoded_buff.decoded_instr.mem_op != MEM_NOP) begin
            stall = 1;
        end

        // Check first mem cause it will get overwritten if required
        // rs dependency with instr at mem
        if(rs == exec_buff.instr.rd && exec_buff.decoded_instr.register_wb)
            bypass_rs[idx] = BYPASS_MEM_BUFF;

        // rs dependency with instr at exec
        if (rs == decoded_buff.instr.rd && decoded_buff.decoded_instr.register_wb) begin
            bypass_rs[idx] = BYPASS_EXEC_BUFF;
        end

        // No dependency
        if (!use_rs[idx]) begin
            bypass_rs[idx] = NO_BYPASS;
        end
    end
end

endmodule
