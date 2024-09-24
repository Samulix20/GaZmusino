/* verilator lint_off UNUSEDSIGNAL */

// Data Hazzard detection logic

module rv32_hazzard_detection_unit
import rv32_types::*;
(
    input logic use_rs [CORE_RF_NUM_READ],
    input rv_instr_t current_instr,
    input rv_control_t current_control,
    input decode_exec_buffer_t decode_exec_buff,
    input exec_mem_buffer_t exec_mem_buff,
    output logic stall,
    output bypass_t [CORE_RF_NUM_READ - 1:0] bypass_rs
);

always_comb begin
    // Data Hazzard detection
    logic stall_vec[CORE_RF_NUM_READ] = '{default: 0};
    rv_r4_instr_t r4_instr = current_instr;

    for(int idx = 0; idx < CORE_RF_NUM_READ; idx = idx + 1) begin
        rv_reg_id_t rs;
        bypass_rs[idx] = NO_BYPASS;

        // Encoding fields related to registers ids
        if (idx == 0) rs = current_instr.rs1;
        else if (idx == 1) rs = current_instr.rs2;
        else if (idx == 2) rs = r4_instr.rs3;
        else rs = current_instr.rd;

        // Check first mem cause it will get overwritten if required
        // rs dependency with instr at mem
        if(rs == exec_mem_buff.instr.rd && exec_mem_buff.control.register_wb)
            bypass_rs[idx] = BYPASS_MEM_BUFF;

        // rs dependency with instr at exec
        if (rs == decode_exec_buff.instr.rd &&
            decode_exec_buff.control.register_wb) begin

            bypass_rs[idx] = BYPASS_EXEC_BUFF;
            // Load use generates one nop bubble always
            if (decode_exec_buff.control.wb_result_src == WB_MEM_DATA)
                stall_vec[idx] = 1;
        end

        // No dependency
        if (!use_rs[idx]) begin
            bypass_rs[idx] = NO_BYPASS;
            stall_vec[idx] = 0;
        end
    end

    stall = stall_vec.or();

    // CSR Hazzard detection
    // Only 1 CSR instruction ins allowed in the pipeline
    if (current_control.wb_result_src == WB_CSR) begin
        stall = stall | (decode_exec_buff.control.wb_result_src == WB_CSR);
        stall = stall | (exec_mem_buff.control.wb_result_src == WB_CSR);
    end
end

endmodule
