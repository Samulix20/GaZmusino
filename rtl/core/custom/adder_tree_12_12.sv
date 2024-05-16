module adder_tree_12_12 (
    input logic clk, enable,
    input logic[11:0][11:0] data,
    output logic[15:0] result
);

logic [5:0][12:0] buff_l0l1, out_l0;
logic [2:0][13:0] buff_l1l2, out_l1;
logic [1:0][14:0] buff_l2l3, out_l2;
logic [15:0] out_l3;

always_ff @(posedge clk) begin
    if (enable) begin 
        buff_l0l1 <= out_l0;
        buff_l1l2 <= out_l1;
        buff_l2l3 <= out_l2;
        result <= out_l3;
    end
end

always_comb begin
    // Level 0
    for(int i = 0; i < 6; i++) begin
        out_l0[i] = data[i*2] + data[i*2+1];
    end
    // Level 1
    for(int i = 0; i < 3; i++) begin
        out_l1[i] = buff_l0l1[i*2] + buff_l0l1[i*2+1];
    end
    // Level 2
    out_l2[0] = buff_l1l2[0] + buff_l1l2[1];
    out_l2[1] = {1'b0, buff_l1l2[2]};
    // Level 3
    out_l3 = buff_l2l3[0] + buff_l2l3[1];
end

endmodule
