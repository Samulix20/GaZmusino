/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_main_memory #(
    parameter int NUM_WORDS = 100
) (
    input logic clk, resetn,
    // PORT A
    input memory_request_t instr_request,
    output logic instr_ready,
    output rv32_word instr,
    // PORT B
    input memory_request_t data_request,
    output logic data_ready,
    output rv32_word data
);

logic [7:0] data_in_b [4];
logic [3:0] we_b;

bram #(.NUM_BYTES(NUM_WORDS)) b0(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr[31:2]), .addr_b(data_request.addr[31:2]),
    .data_in_b(data_in_b[0]), .we_b(we_b[0]),
    .data_a(instr[7:0]), .data_b(data[7:0])
);

bram #(.NUM_BYTES(NUM_WORDS)) b1(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr[31:2]), .addr_b(data_request.addr[31:2]),
    .data_in_b(data_in_b[1]), .we_b(we_b[1]),
    .data_a(instr[15:8]), .data_b(data[15:8])
);

bram #(.NUM_BYTES(NUM_WORDS)) b2(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr[31:2]), .addr_b(data_request.addr[31:2]),
    .data_in_b(data_in_b[2]), .we_b(we_b[2]),
    .data_a(instr[23:16]), .data_b(data[23:16])
);

bram #(.NUM_BYTES(NUM_WORDS)) b3(
    .clk(clk), .resetn(resetn),
    .addr_a(instr_request.addr[31:2]), .addr_b(data_request.addr[31:2]),
    .data_in_b(data_in_b[3]), .we_b(we_b[3]),
    .data_a(instr[31:24]), .data_b(data[31:24])
);

always_comb begin
    we_b = 0;

    // Default setup
    data_in_b[0] = data_request.data[7:0];
    data_in_b[1] = data_request.data[15:8];
    data_in_b[2] = data_request.data[23:16];
    data_in_b[3] = data_request.data[31:24];

    case(data_request.op)
        MEM_SB: begin
            case(data_request.addr[1:0])
                2'b00: we_b = 4'b0001;
                2'b01: begin
                    we_b = 4'b0010;
                    data_in_b[1] = data_in_b[0];
                end
                2'b10: begin
                    we_b = 4'b0100;
                    data_in_b[2] = data_in_b[0];
                end
                2'b11: begin
                    we_b = 4'b1000;
                    data_in_b[3] = data_in_b[0];
                end
                default: we_b = 0; // Unreacheable
            endcase
        end
        MEM_SH: begin
            case(data_request.addr[1:0])
                2'b00: we_b = 4'b0011;
                2'b10: begin
                    we_b = 4'b1100;
                    data_in_b[2] = data_in_b[0];
                    data_in_b[3] = data_in_b[1];
                end
                default: we_b = 0; // Dont write aligment error
            endcase
        end
        MEM_SW: we_b = 4'b1111; // Write all banks
        default: we_b = 0; // Dont write
    endcase
end

// TODO fix data ready for 1 cycle delay (I think its done)

always_comb begin
    data_ready = 0;
    instr_ready = 0;

    if ({2'b00, instr_request.addr[31:2]} < NUM_WORDS) instr_ready = 1;
    if ({2'b00, data_request.addr[31:2]} < NUM_WORDS) data_ready = 1;
end

endmodule
