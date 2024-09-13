
/* 
 Register file, 32 registers
 - x0 is readonly 0
 - Generic number of read ports (default 4)
 - 1 Write port
*/

module rv32_register_file
import rv32_types::*;
#(
    parameter int NUM_READ_PORTS = 4
) (
    input logic clk,
    // Read ports
    input rv_reg_id_t [NUM_READ_PORTS - 1:0] rs,
    output rv32_word [NUM_READ_PORTS - 1:0] o,
    // Write port
    input register_write_request_t write_request
);

rv32_word register_file [32];

// Write logic
always_ff @(negedge clk) begin
    if (write_request.write) begin
        register_file[write_request.id] <= write_request.data;
        // x0 is always 0
        register_file[0] <= 0;
    end
end

// Read logic
always_comb begin
    for(int idx = 0; idx < NUM_READ_PORTS; idx = idx + 1) begin
        o[idx] = register_file[rs[idx]];
    end
end

endmodule

