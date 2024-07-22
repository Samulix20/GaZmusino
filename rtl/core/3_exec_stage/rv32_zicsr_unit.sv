
// Zicsr unit

module rv32_zicsr_unit
import rv32_types::*;
(
    input rv32_word csr, operand,
    zicsr_op_t opsel,
    output rv32_word reg_result,
    output rv32_word csr_result
);

always_comb begin
    reg_result = csr;
    case (opsel)
        CSR_RW: begin
            csr_result = operand;
        end
        CSR_RS: begin 
            csr_result = csr | operand;
        end
        CSR_RC: begin
            csr_result = csr & (~operand);
        end
        default: csr_result = csr; 
    endcase
end

endmodule
