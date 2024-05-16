/* verilator lint_off UNUSEDSIGNAL */

module clt_grng_16 
import rv32_types::*;
(
    input logic clk, resetn, enable,
    input rv32_word seed,
    output rv32_word sample
);

const logic [150:0] RESET_SEED = 151'b0111001100100100110011101101000111101000001000100001000111001100011000101110010111111111011101101110110110110000100001000010010110001101000011111001000;

// Control logic
logic [1:0] current_state, next_state;
logic __enable, __set, state_change;
always_comb begin 
    __set = 0;
    __enable = 0;
    state_change = 0;
    next_state = current_state;

    if (!resetn) begin 
        state_change = 1;
        next_state = 3;
        __set = 1;
    end
    else if (current_state > 0) begin
        state_change = 1;
        next_state = current_state - 1;
        __enable = 1;
    end 
    else begin 
        __enable = enable;
    end
end
always_ff @(posedge clk) begin
    if (state_change) begin
        current_state <= next_state;
    end
end

logic [150:0] urng_state;
lfsr_151_144 urng(
    .clk(clk), .enable(__enable),
    .set(__set), .seed(RESET_SEED),
    .current_state(urng_state)
);

logic [15:0] __sample;
adder_tree_12_12 adder_tree(
    .clk(clk), .data(urng_state[143:0]),
    .enable(__enable),
    .result(__sample)
);

always_comb begin
    rv32_word aux;
    aux = rv32_word'({1'b0, __sample});
    sample = $signed(aux) - $signed(6);
end

endmodule
