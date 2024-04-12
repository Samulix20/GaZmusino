`ifndef RV_REGISTER_FILE
`define RV_REGISTER_FILE

`include "rtl/rv32_types.sv"

module rv32_register_file (
    input   logic write, clk, resetn,
    input   reg_id_t r1, r2, rw,
    input   rv32_word d,
    output  rv32_word o1, o2
);

rv32_word register_file [32];

always_ff @(negedge clk) begin
    if (!resetn) begin
        // Set all values to 0
        register_file <= '{default: 0};
    end else if (write) begin
        register_file[rw] <= d;
    end
end

// x0 is always 0
always_comb begin
    register_file[0] = 0;
end

// Read logic
always_comb begin
    o1 = register_file[r1];
    o2 = register_file[r2];
end

endmodule

`endif
