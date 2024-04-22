/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_load_store_unit (
    input exec_buffer_data_t exec_data,
    output memory_response_t response,
    // Memory I/O
    output memory_request_t data_request,
    input memory_response_t data_response
);

always_comb begin
    // TODO make ready logic and signed/unsigned load logic
    data_request.addr = exec_data.mem_addr;
    data_request.op = exec_data.decoded_instr.mem_op;

    response = data_response;
end

endmodule
