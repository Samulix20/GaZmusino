/* verilator lint_off UNUSEDSIGNAL */

module testbench (
    input logic clk, resetn,
    output [31:0] r
);

clt_grng_16 grng(
    .clk(clk), .resetn(resetn), .enable(1), .seed(0), .sample(r)
);

endmodule
