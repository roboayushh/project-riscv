
`timescale 1ns/1ps

package riscv_pkg;

    typedef enum logic [3:0] {
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_AND  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_XOR  = 4'd4,
        ALU_SLL  = 4'd5,
        ALU_SRL  = 4'd6,
        ALU_SRA  = 4'd7,
        ALU_SLT  = 4'd8,
        ALU_SLTU = 4'd9
    } alu_op_t;

    typedef enum logic [2:0] {
        IMM_I = 3'd0,
        IMM_S = 3'd1,
        IMM_B = 3'd2,
        IMM_U = 3'd3,
        IMM_J = 3'd4
    } imm_src_t;

    typedef enum logic [1:0] {
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC4 = 2'd2,
        WB_IMM = 2'd3
    } wb_src_t;

    /* verilator lint_off UNUSEDPARAM */
    localparam logic [6:0] OPCODE_LOAD     = 7'b0000011;
    localparam logic [6:0] OPCODE_MISC_MEM = 7'b0001111;
    localparam logic [6:0] OPCODE_OP_IMM   = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC    = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE    = 7'b0100011;
    localparam logic [6:0] OPCODE_OP       = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI      = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH   = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR     = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL      = 7'b1101111;
    /* verilator lint_on UNUSEDPARAM */

endpackage
