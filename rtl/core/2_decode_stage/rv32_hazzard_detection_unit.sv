/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_hazzard_detection_unit (
    input logic[1:0] use_rs,
    input rv_instr_t current_instr,
    input decode_exec_buffer_t decode_exec_buff,
    input exec_mem_buffer_t exec_mem_buff,
    output logic stall,
    output bypass_t bypass_rs[2]
);

always_comb begin
    logic stall_vec [2];
    stall_vec[0] = 0;
    stall_vec[1] = 0;

    for(int idx = 0; idx < 2; idx = idx + 1) begin
        rv_reg_id_t rs;
        bypass_rs[idx] = NO_BYPASS;

        if (idx == 0) rs = current_instr.rs1;
        else rs = current_instr.rs2;

        // Check first mem cause it will get overwritten if required
        // rs dependency with instr at mem
        if(rs == exec_mem_buff.instr.rd && exec_mem_buff.decoded_instr.register_wb)
            bypass_rs[idx] = BYPASS_MEM_BUFF;

        // rs dependency with instr at exec
        if (rs == decode_exec_buff.instr.rd &&
            decode_exec_buff.decoded_instr.register_wb) begin

            bypass_rs[idx] = BYPASS_EXEC_BUFF;
            // Load use generates one nop bubble always
            if (decode_exec_buff.decoded_instr.wb_result_src == WB_MEM_DATA)
                stall_vec[idx] = 1;
        end

        // No dependency
        if (!use_rs[idx]) begin
            bypass_rs[idx] = NO_BYPASS;
            stall_vec[idx] = 0;
        end
    end

    stall = stall_vec[0] | stall_vec[1];
end

endmodule
