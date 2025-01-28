/* verilator lint_off UNUSEDSIGNAL */

/*
 CPU 4 memory stage
 - Consolidation point
 - Memory requests
*/


module rv32_mem_stage
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic mtip,
    input exec_mem_buffer_t exec_mem_buff,
    output mem_wb_buffer_t mem_wb_buff,
    output logic stall,
    output interrupt_request_t interrupt_request,
    // Data Mem I/O
    output memory_request_t data_request,
    input logic request_done,
    // CSR file O
    output csr_write_request_t csr_write_request,
    output logic instr_retired
);

mem_wb_buffer_t internal_data /*verilator public*/;

// CSR instructions commit at memory
always_comb begin 
    csr_write_request.id = exec_mem_buff.instr[31:20];
    csr_write_request.value = exec_mem_buff.data_result[1];
    csr_write_request.write = exec_mem_buff.control.csr_wb;
end

// Send data request to memory bus
always_comb begin
    data_request.addr = exec_mem_buff.data_result[1];
    data_request.op = exec_mem_buff.control.mem_op;
    data_request.data = exec_mem_buff.data_result[0];
end

always_comb begin
    // Forward signals
    internal_data = exec_mem_buff;
    if (exec_mem_buff.control.mem_op == MEM_NOP) stall = 0;
    else stall = ~request_done;

    // Consolidation Point
    if (mtip) begin
        interrupt_request.do_interrupt = 1;
        interrupt_request.from = exec_mem_buff.pc;
    end 
    else begin 
        interrupt_request.do_interrupt = 0;
    end

    // Check if instruction is retiring for counters
    instr_retired = ~(internal_data.control.is_bubble | stall);
end

always_ff @(posedge clk) begin
    if(!resetn) begin
        mem_wb_buff.instr <= RV_NOP;
        mem_wb_buff.control <= create_bubble_ctrl();
        mem_wb_buff.pc <= 0;
    end

    else if (!stall) mem_wb_buff <= internal_data;
    
    else begin 
        mem_wb_buff.control.is_bubble <= 1;
    end
end

endmodule
