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

        // rs dependency with instr at exec
        if (rs != 0 && rs == decoded_buff.instr.rd) begin
            bypass_rs[idx] = BYPASS_EXEC_BUFF;
            // Load use generates one nop bubble always
            if (decoded_buff.decoded_instr.wb_result_src == WB_MEM_DATA)
                stall = 1;
        end

        // rs dependency with instr at mem
        if(rs == exec_buff.instr.rd &&
            decoded_buff.decoded_instr.wb_result_src == WB_MEM_DATA)
                bypass_rs[idx] = BYPASS_MEM_BUFF;

        // No dependency
        if (!use_rs[idx]) bypass_rs[idx] = NO_BYPASS;
    end

end

endmodule
