`ifndef RV_REGISTER_FILE
`define RV_REGISTER_FILE

typedef logic [4:0] reg_id_t;

module riscv_register_file (
	input	logic write, clk, resetn,
	input	reg_id_t r1, r2, rw,
	input 	logic [31:0] d,
	output	logic [31:0] o1, o2
);

logic [31:0] register_file [32];

always_ff @(negedge clk) begin
	if (!resetn) begin	
		register_file <= '{default: 0};
	end else if (write) begin
		register_file[rw] <= d;
	end
end

always_comb begin
	register_file[0] = 0;
end

always_comb begin
	o1 = register_file[r1];
	o2 = register_file[r2];
end

endmodule

`endif
