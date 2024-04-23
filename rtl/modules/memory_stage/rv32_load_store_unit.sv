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
    data_request.data = exec_data.wb_result;
end

// Logic to setup and extend sign of byte, half
always_comb begin
    case (exec_data.decoded_instr.mem_op)
        MEM_LW: begin
            response.data = data_response.data;
        end
        MEM_LB: begin
            case(exec_data.mem_addr[1:0])
                0: response.data[7:0] = data_response.data[7:0];
                1: response.data[7:0] = data_response.data[15:8];
                2: response.data[7:0] = data_response.data[23:16];
                3: response.data[7:0] = data_response.data[31:24];
                default: response.data[7:0] = 0;
            endcase
            response.data[31:8] = '{default: response.data[7]};
        end
        MEM_LH: begin
            case(exec_data.mem_addr[1:0])
                0: response.data[15:0] = data_response.data[15:0];
                2: response.data[15:0] = data_response.data[31:16];
                default: response.data[15:0] = 0;
            endcase
            response.data[31:16] = '{default: response.data[15]};
        end
        MEM_LBU: begin
            case(exec_data.mem_addr[1:0])
                0: response.data[7:0] = data_response.data[7:0];
                1: response.data[7:0] = data_response.data[15:8];
                2: response.data[7:0] = data_response.data[23:16];
                3: response.data[7:0] = data_response.data[31:24];
                default: response.data[7:0] = 0;
            endcase
            response.data[31:8] = 0;
        end
        MEM_LHU: begin
            case(exec_data.mem_addr[1:0])
                0: response.data[15:0] = data_response.data[15:0];
                2: response.data[15:0] = data_response.data[31:16];
                default: response.data[15:0] = 0;
            endcase
            response.data[31:16] = 0;
        end
        default: response.data = 0;
    endcase

    response.ready = 1;
end

endmodule
