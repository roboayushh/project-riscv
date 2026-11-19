`timescale 1ns/1ps

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  riscv_pkg::alu_op_t op,

    output logic [31:0] result,
    output logic        zero
);

import riscv_pkg::*;

always_comb begin

    case (op)

        ALU_ADD: begin
            result = a + b;
        end

        ALU_SUB: begin
            result = a - b;
        end

        ALU_AND: begin
            result = a & b;
        end

        ALU_OR: begin
            result = a | b;
        end

        ALU_XOR: begin
            result = a ^ b;
        end

        ALU_SLL: begin
            result = a << b[4:0];
        end

        ALU_SRL: begin
            result = a >> b[4:0];
        end

        ALU_SRA: begin
            result = $signed(a) >>> b[4:0];
        end

        ALU_SLT: begin
            result = ($signed(a) < $signed(b))? 32'd1 : 32'd0;
        end

        ALU_SLTU: begin
            result = (a < b)? 32'd1 : 32'd0;
        end

        default: begin
            result = 32'd0;
        end

    endcase

end

assign zero = (result == 32'd0);

endmodule
