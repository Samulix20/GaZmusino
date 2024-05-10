
// 3 Read ports
// 1 Write port

module rv32_register_file
import rv32_types::*;
(
    input   logic clk,
    // Read ports
    input   rv_reg_id_t rs[3],
    output  rv32_word o[3],
    // Write port
    input logic   write,
    input   rv_reg_id_t rw,
    input   rv32_word d
);

rv32_word register_file [32];

always_ff @(negedge clk) begin
    if (write) begin
        register_file[rw] <= d;
        // x0 is always 0
        register_file[0] <= 0;
    end
end

// Read logic
always_comb begin
    o[0] = register_file[rs[0]];
    o[1] = register_file[rs[1]];
    o[2] = register_file[rs[2]];
end

endmodule

