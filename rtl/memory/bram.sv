/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */

// 1 byte wide
// 2 read ports
// 1 write ports

// TODO change name to 2_port_bram
module bram #(
    parameter int ADDR_WIDTH = 1
)(
    input logic clk, resetn,
    input logic read_a, read_b,
    input logic[2**ADDR_WIDTH - 1:0] addr_a, addr_b,
    input logic[7:0] data_in_a, data_in_b,
    input logic we_a, we_b,
    output logic[7:0] data_a, data_b
);

logic [7:0] ram [2**ADDR_WIDTH] /* verilator public */ = '{default: 0};

always_ff @(posedge clk) begin
    // Reset only affects the registers
    if (!resetn) begin
        data_a <= 0;
    end else begin
        if (read_a) data_a <= ram[addr_a];
        if (we_a) ram[addr_a] <= data_in_a;
    end
end

always_ff @(posedge clk) begin
    // Reset only affects the registers
    if (!resetn) begin
        data_b <= 0;
    end else begin
        if (read_b) data_b <= ram[addr_b];
        if (we_b) ram[addr_b] <= data_in_b;
    end
end

endmodule
