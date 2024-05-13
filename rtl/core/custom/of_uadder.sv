module of_uadder # (
    parameter int size
) (
    input logic[size-1:0] a, b,
    output logic[size:0] r
);

always_comb begin
    r = {1'b0,a} + {1'b0,b};
end

endmodule
