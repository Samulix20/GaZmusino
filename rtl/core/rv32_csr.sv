
// Control and status registers bank

module rv32_csr
import rv32_types::*;
(
    input logic clk, resetn,
    // Read ports
    input rv_csr_id_t read_id,
    output rv32_word read_value,
    // Write ports
    input csr_write_request_t write_request,
    // Always available signals, mstatus...
    // TODO
    // Performance counters...
    input logic instr_retired,
    input logic dec_stall,
    input logic jump_taken
);

// CSR LIST
typedef enum logic [11:0] {    
    CSR_MCOUNTINHIBIT = 'h320,
    CSR_MSCRATCH = 'h340,
    CSR_MCYCLE = 'hB00,
    CSR_MCYCLEH = 'hB80,
    CSR_MINSTRET = 'hB02,
    CSR_MINSTRETH = 'hB82
} valid_opcodes_t /*verilator public*/;

rv32_word mscratch, next_mscratch;

// Performance counters

// Control
typedef struct packed {
    logic cy;
    logic ir;
} mcountinhibit_t; 
mcountinhibit_t mcountinhibit, next_mcountinhibit;

// Counters
rv64_word mcycle /*verilator public*/;
rv64_word minstret /*verilator public*/;
rv64_word next_mcycle, next_minstret;

// TODO make them standard hardware counters
rv64_word mdecstall /*verilator public*/;
rv64_word mjmp /*verilator public*/;
rv64_word next_mdecstall, next_mjmp;

always_comb begin
    read_value = 0;

    // Output control
    case (read_id)
        CSR_MCOUNTINHIBIT: begin 
            read_value[0] = mcountinhibit.cy;
            read_value[2] = mcountinhibit.ir;
        end
        CSR_MSCRATCH: begin 
            read_value = mscratch;
        end
        CSR_MCYCLE: begin
            read_value = mcycle[0];
        end
        CSR_MCYCLEH: begin
            read_value = mcycle[1];
        end
        CSR_MINSTRET: begin
            read_value = minstret[0];
        end
        CSR_MINSTRETH: begin
            read_value = minstret[1];
        end
        default: read_value = 0; 
    endcase
end

// Write logic
always_comb begin

    // Special counters for simulation
    if (jump_taken) next_mjmp = mjmp + 1;
    else if (dec_stall) next_mdecstall = mdecstall + 1;

    // Counters default behaviour
    if (!mcountinhibit.cy) next_mcycle = mcycle + 1;
    if (!mcountinhibit.ir && instr_retired) next_minstret = minstret + 1;

    // User write logic
    if (write_request.write) begin
        case (write_request.id)
            CSR_MCOUNTINHIBIT: begin 
                next_mcountinhibit.cy = write_request.value[0];
                next_mcountinhibit.ir = write_request.value[2];
            end
            CSR_MSCRATCH: begin 
                next_mscratch = write_request.value;
            end
            CSR_MCYCLE: begin
                next_mcycle[0] = write_request.value;
            end
            CSR_MCYCLEH: begin
                next_mcycle[1] = write_request.value;
            end
            CSR_MINSTRET: begin
                next_minstret[0] = write_request.value;
            end
            CSR_MINSTRETH: begin
                next_minstret[1] = write_request.value;
            end
            default: ;
        endcase
    end
end

// Register control
always_ff @(posedge clk) begin
    if(!resetn) begin 
        mcycle <= 0;
        minstret <= 0;
        mcountinhibit <= 0;
    end else begin
        mcycle <= next_mcycle;
        minstret <= next_minstret;
        mcountinhibit <= next_mcountinhibit;
        mscratch <= next_mscratch;
        
        mdecstall <= next_mdecstall;
        mjmp <= next_mjmp;
    end
end

endmodule;
