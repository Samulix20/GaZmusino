/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_load_store_unit (
    input exec_mem_buffer_t exec_mem_buff,
    output memory_response_t response,
    // Memory I/O
    output memory_request_t data_request,
    input memory_response_t data_response
);

always_comb begin
    data_request.addr = exec_mem_buff.mem_addr;
    data_request.op = exec_mem_buff.decoded_instr.mem_op;
    data_request.data = exec_mem_buff.wb_result;
end

// Logic to setup and extend sign of byte, half
always_comb begin
    case (exec_mem_buff.decoded_instr.mem_op)
        MEM_LW: begin
            response.data = data_response.data;
            response.ready = data_response.ready;
        end
        MEM_LB: begin
            case(exec_mem_buff.mem_addr[1:0])
                0: response.data[7:0] = data_response.data[7:0];
                1: response.data[7:0] = data_response.data[15:8];
                2: response.data[7:0] = data_response.data[23:16];
                3: response.data[7:0] = data_response.data[31:24];
                default: response.data[7:0] = 0;
            endcase
            response.data[31:8] = '{default: response.data[7]};
            response.ready = data_response.ready;
        end
        MEM_LH: begin
            case(exec_mem_buff.mem_addr[1:0])
                0: response.data[15:0] = data_response.data[15:0];
                2: response.data[15:0] = data_response.data[31:16];
                default: response.data[15:0] = 0;
            endcase
            response.data[31:16] = '{default: response.data[15]};
            response.ready = data_response.ready;
        end
        MEM_LBU: begin
            case(exec_mem_buff.mem_addr[1:0])
                0: response.data[7:0] = data_response.data[7:0];
                1: response.data[7:0] = data_response.data[15:8];
                2: response.data[7:0] = data_response.data[23:16];
                3: response.data[7:0] = data_response.data[31:24];
                default: response.data[7:0] = 0;
            endcase
            response.data[31:8] = 0;
            response.ready = data_response.ready;
        end
        MEM_LHU: begin
            case(exec_mem_buff.mem_addr[1:0])
                0: response.data[15:0] = data_response.data[15:0];
                2: response.data[15:0] = data_response.data[31:16];
                default: response.data[15:0] = 0;
            endcase
            response.data[31:16] = 0;
            response.ready = data_response.ready;
        end
        MEM_NOP: begin
            response.ready = 1;
            response.data = 0;
        end
        default: begin
            response.data = 0;
            response.ready = data_response.ready;
        end
    endcase
end

endmodule
