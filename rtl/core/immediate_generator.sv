`timescale 1ns/1ps

module immediate_generator (
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0]          instruction,
    /* verilator lint_on UNUSEDSIGNAL */
    input  riscv_pkg::imm_src_t  imm_src,
    output logic [31:0]          immediate
);

    import riscv_pkg::*;

    always_comb begin
        case (imm_src)
            IMM_I: immediate = {{20{instruction[31]}}, instruction[31:20]};
            IMM_S: immediate = {{20{instruction[31]}}, instruction[31:25],
                               instruction[11:7]};
            IMM_B: immediate = {{19{instruction[31]}}, instruction[31],
                               instruction[7], instruction[30:25],
                               instruction[11:8], 1'b0};
            IMM_U: immediate = {instruction[31:12], 12'b0};
            IMM_J: immediate = {{11{instruction[31]}}, instruction[31],
                               instruction[19:12], instruction[20],
                               instruction[30:21], 1'b0};
            default: immediate = 32'b0;
        endcase
    end

endmodule
