/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */

// 1 byte wide
// 2 read ports
// 1 write ports

module bram #(
    parameter int NUM_BYTES = 1
)(
    input logic clk, resetn,
    input logic[29:0] addr_a, addr_b,
    input logic[7:0] data_in_b,
    input logic we_b,
    output logic[7:0] data_a, data_b
);

logic [7:0] ram [NUM_BYTES];

always_ff @(posedge clk) begin
    if (!resetn) begin
        ram <= '{default: 0};
        data_a <= 0;
        data_b <= 0;
    end else begin
        data_a <= ram[addr_a];
        data_b <= ram[addr_b];

        if (we_b) ram[addr_b] <= data_in_b;
    end

end

endmodule;
