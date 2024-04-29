/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_load_store_unit (
    input exec_mem_buffer_t exec_mem_buff,
    output logic ready,
    // Memory I/O
    output memory_request_t data_request,
    input logic request_done
);

always_comb begin
    data_request.addr = exec_mem_buff.mem_addr;
    data_request.op = exec_mem_buff.decoded_instr.mem_op;
    data_request.data = exec_mem_buff.wb_result;
end

always_comb begin
    if (exec_mem_buff.decoded_instr.mem_op == MEM_NOP) ready = 1;
    else ready = request_done;
end

endmodule
