
module rv32_top
import rv32_types::*;
#(parameter int NUM_MMIO = 1)
(
    input logic clk, resetn,
    // MMIO
    output memory_request_t mmio_data_request,
    output memory_request_t core_instr_request,
    input logic mmio_request_done [NUM_MMIO],
    input rv32_word mmio_data [NUM_MMIO]
);

// Memory bus signals
logic instr_request_done /*verilator public*/;
rv32_word instr /*verilator public*/;

// Data bus signals
rv32_word core_data /*verilator public*/;
logic core_data_ready;

rv32_core core (
    .clk(clk), .resetn(resetn),
    // Instruction
    .instr_request(core_instr_request),
    .instr_request_done(instr_request_done),
    .instr(instr),
    // Data
    .data_request(mmio_data_request),
    .data_request_done(core_data_ready),
    .data(core_data)
);

logic mem_data_ready /*verilator public*/;
rv32_word memory_data /*verilator public*/;

`ifndef CPP_MEMORY_SIM

rv32_main_memory memory (
    .clk(clk), .resetn(resetn),

    .instr_request(core_instr_request),
    .instr_ready(instr_request_done),
    .instr(instr),

    .data_request(mmio_data_request),
    .data_ready(mem_data_ready),
    .data(memory_data)
);

`endif

// Setup ready flag for core memory stage
always_comb begin
    core_data_ready = mem_data_ready;
    for(int idx = 0; idx < NUM_MMIO; idx = idx + 1) begin
        if (mmio_request_done[idx]) core_data_ready = 1;
    end
end

logic select_main_memory;
logic mmio_bus_selector [NUM_MMIO];

// Bus controller
always_ff @(posedge clk) begin
    if (!resetn) begin
        select_main_memory <= 0;
        mmio_bus_selector <= '{default: 0};
    end
    else begin
        select_main_memory <= mem_data_ready;
        for(int idx = 0; idx < NUM_MMIO; idx = idx + 1) begin
            mmio_bus_selector[idx] <= mmio_request_done[idx];
        end
    end
end

always_comb begin
    // Default behaviour
    core_data = memory_data;
    // Memory is top priority
    // Then MMIO N, MMIO N-1, ... MMIO 0
    if (!select_main_memory) begin
        for(int idx = 0; idx < NUM_MMIO; idx = idx + 1) begin
            if (mmio_bus_selector[idx]) core_data = mmio_data[idx];
        end
    end
end

endmodule
