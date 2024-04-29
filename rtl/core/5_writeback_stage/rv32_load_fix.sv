/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_load_fix (
    // Core I/O
    input mem_op_t op,
    input rv32_word addr,
    output rv32_word fixed_load,
    // Mem I
    input rv32_word raw_load
);

always_comb begin
    case (op)
        MEM_LW: begin
            fixed_load = raw_load;
        end
        MEM_LB: begin
            case(addr[1:0])
                0: fixed_load[7:0] = raw_load[7:0];
                1: fixed_load[7:0] = raw_load[15:8];
                2: fixed_load[7:0] = raw_load[23:16];
                3: fixed_load[7:0] = raw_load[31:24];
                default: fixed_load[7:0] = 0;
            endcase
            fixed_load[31:8] = '{default: fixed_load[7]};
        end
        MEM_LH: begin
            case(addr[1:0])
                0: fixed_load[15:0] = raw_load[15:0];
                2: fixed_load[15:0] = raw_load[31:16];
                default: fixed_load[15:0] = 0;
            endcase
            fixed_load[31:16] = '{default: fixed_load[15]};
        end
        MEM_LBU: begin
            case(addr[1:0])
                0: fixed_load[7:0] = raw_load[7:0];
                1: fixed_load[7:0] = raw_load[15:8];
                2: fixed_load[7:0] = raw_load[23:16];
                3: fixed_load[7:0] = raw_load[31:24];
                default: fixed_load[7:0] = 0;
            endcase
            fixed_load[31:8] = 0;
        end
        MEM_LHU: begin
            case(addr[1:0])
                0: fixed_load[15:0] = raw_load[15:0];
                2: fixed_load[15:0] = raw_load[31:16];
                default: fixed_load[15:0] = 0;
            endcase
            fixed_load[31:16] = 0;
        end
        default: begin
            fixed_load = 0;
        end
    endcase
end

endmodule;
