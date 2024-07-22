
// Control and status registers bank

module rv32_csr
import rv32_types::*;
(
    input logic clk, resetn,
    // Read ports
    input logic[11:0] id,
    output rv32_word value,
    // Always available signals, mstatus...
    // TODO
    // Performance counters...
    input logic instr_retired
);

// CSR LIST
typedef enum logic [11:0] {
    CSR_MCOUNTINHIBIT = 'h320,
    CSR_MCYCLE = 'hB00,
    CSR_MCYCLEH = 'hB80,
    CSR_MINSTRET = 'hB02,
    CSR_MINSTRETH = 'hB82
} valid_opcodes_t /*verilator public*/;

// Performance counters

// Control
typedef struct packed {
    logic cy;
    logic ir;
} mcountinhibit_t; 
mcountinhibit_t mcountinhibit;

// Counters
rv64_word mcycle;
rv64_word minstret;

always_comb begin
    value = 0;

    // Output control
    case (id)
        CSR_MCOUNTINHIBIT: begin 
            value[0] = mcountinhibit.cy;
            value[2] = mcountinhibit.ir;
        end
        CSR_MCYCLE: begin
            value = mcycle[0];
        end
        CSR_MCYCLEH: begin
            value = mcycle[1];
        end
        CSR_MINSTRET: begin
            value = minstret[0];
        end
        CSR_MINSTRETH: begin
            value = minstret[1];
        end
        default: value = 0; 
    endcase
end

always_ff @(posedge clk) begin
    if(!resetn) begin 
        mcycle <= 0;
        minstret <= 0;
        mcountinhibit <= 0;
    end else begin
        if (mcountinhibit.cy) mcycle <= mcycle + 1;
        if (mcountinhibit.ir && instr_retired) minstret <= minstret + 1;
    end
end

endmodule;
