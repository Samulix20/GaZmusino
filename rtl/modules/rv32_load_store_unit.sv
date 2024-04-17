/*
`include "rtl/rv32_types"

typedef enum logic {
    NO_OP,
    OP_ISSUED
} internal_state_t;

typedef enum logic [2:0] {
    WRITE_BYTE = 3'b100,
    WRITE_HALF = 3'b101,
    WRITE_WORD = 3'b110
} write_mode_t;

module rv32_load_store_unit (
    // Clk, Reset signals
    input logic clk, resetn,

    // Core input port
    input rv32_word addr,
    input load_store_op_t op,

    // Bus I/O
    output logic[29:0] bus_addr,
    output write_mode_t w_mode,
    input logic bus_done,

    // Core output port
    output rv32_word read_value,
    output logic done
);

internal_state_t internal_state;
logic[29:0] issued_addr;
load_store_op_t issued_op;

always_ff @(posedge clk) begin
    if (!resetn) begin
        internal_state <= NO_OP;
        issued_op <= MEM_NOP;
        issued_addr <= 0;
    end

    else begin
        case(internal_state)
            NO_OP: begin
                if (op != MEM_NOP) begin
                    internal_state <= OP_ISSUED;
                    // Store new op and addr
                    issued_addr <= addr[31:2];
                    issued_op <= op;
                end
            end
            OP_ISSUED: begin
                if (bus_done) begin
                    internal_state <= NO_OP;
                    issued_op <= MEM_NOP;
                    issued_addr <= 0;
                end
            end
            default: begin end
        endcase
    end
end

always_comb begin
    case(internal_state)
        NO_OP: begin
            if (op != MEM_NOP) begin
                bus_addr = ddr[31:2];
            end
        end
        OP_ISSUED: begin
        end
        default: begin end
    endcase
end

endmodule

typedef enum {
    MEM_LB = 4'b0000,
    MEM_LH = 4'b0001,
    MEM_LW = 4'b0010,
    MEM_LBU = 4'b0100,
    MEM_LHU = 4'b0101,
    MEM_SB = 4'b1000,
    MEM_SH = 4'b1001,
    MEM_SW = 4'b1010,
    MEM_NOP = 4'b1111
} load_store_op_t;

*/
