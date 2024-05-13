module pipelined_adder_tree #(
    parameter int NUM_INPUTS = 12,
    parameter int INPUT_SIZE = 12,

    parameter int NUM_STAGES = $clog2(NUM_INPUTS),
    parameter int OUTPUT_SIZE = INPUT_SIZE + NUM_STAGES
) (
    input logic clk, advance,
    input logic[NUM_INPUTS-1:0][INPUT_SIZE-1:0] data,
    output logic[OUTPUT_SIZE-1:0] result
);

logic [NUM_STAGES-1:0][NUM_INPUTS-1:0][OUTPUT_SIZE-1:0] buffer;

genvar stage, i;
generate
    for(stage = 0; stage < NUM_STAGES; stage++) begin

        localparam STAGE_NUM_ADDERS = NUM_INPUTS >> stage;
        localparam STAGE_NUM_INPUTS = STAGE_NUM_ADDERS * 2;
        localparam STAGE_INPUT_WIDTH = INPUT_SIZE + stage;
        localparam STAGE_OUTPUT_WIDTH = INPUT_SIZE + stage + 1;

        logic [STAGE_NUM_INPUTS-1:0][STAGE_INPUT_WIDTH-1:0] stage_data;
        if (stage == 0) begin 
            for (i = 0; i < STAGE_NUM_INPUTS; i++) begin
                assign stage_data[i] = data[i];
            end
        end
        else begin 
            for (i = 0; i < STAGE_NUM_INPUTS; i++) begin
                assign stage_data[i] = buffer[stage - 1][i][STAGE_INPUT_WIDTH-1:0];
            end
        end

        always_ff @(posedge clk) begin
            if (advance) begin 
                for (i = 0; i < STAGE_NUM_ADDERS; i++) begin
                    buffer[stage][i][STAGE_OUTPUT_WIDTH-1:0] <= stage_data[2*i] + stage_data[2*i+1];
                end
            end
        end
    end
endgenerate

always_comb begin
    result = buffer[NUM_STAGES-1][0];
end

endmodule
