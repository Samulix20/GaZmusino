/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_main_memory (
    input logic clk, resetn,
    input memory_request_t instr_request,
    output memory_response_t instr_response,
    input memory_request_t data_request,
    output memory_response_t data_response
);

logic [31:0] instr;
logic [31:0] data;
logic [3:0] we_b;

bram b0(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr), .addr_b(data_request.addr),
    .data_in_b(data_request.data), .we_b(we_b[0]),
    .data_a(data[7:0]), .data_b(instr[7:0])
);

bram b1(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr), .addr_b(data_request.addr),
    .data_in_b(data_request.data), .we_b(we_b[1]),
    .data_a(data[15:8]), .data_b(instr[15:8])
);

bram b2(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr), .addr_b(data_request.addr),
    .data_in_b(data_request.data), .we_b(we_b[2]),
    .data_a(data[23:16]), .data_b(instr[23:16])
);

bram b3(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr), .addr_b(data_request.addr),
    .data_in_b(data_request.data), .we_b(we_b[3]),
    .data_a(data[31:24]), .data_b(instr[31:24])
);

always_comb begin
    we_b = 0;
    case(data_request.op)
        MEM_SB: begin
            case(data_request.addr[1:0])
                2'b00: we_b = 4'b0001;
                2'b01: we_b = 4'b0010;
                2'b10: we_b = 4'b0100;
                2'b11: we_b = 4'b1000;
                default: we_b = 0; // Unreacheable
            endcase
        end
        MEM_SH: begin
            case(data_request.addr[1:0])
                2'b00: we_b = 4'b0011;
                2'b10: we_b = 4'b1100;
                default: we_b = 0; // Dont write aligment error
            endcase
        end
        MEM_SW: we_b = 4'b1111; // Write all banks
        default: we_b = 0; // Dont write
    endcase
end

// TODO fix data ready for 1 cycle delay

always_comb begin
    data_response.data = data;
    data_response.ready = 1;
    instr_response.data = instr;
    instr_response.ready = 1;
end

endmodule
