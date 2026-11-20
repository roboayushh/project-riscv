`timescale 1ns/1ps

module control_unit (
    input  logic [6:0]          opcode,
    input  logic [2:0]          funct3,
    input  logic [6:0]          funct7,

    output logic                reg_write,
    output logic                mem_write,
    output logic                alu_a_is_pc,
    output logic                alu_b_is_imm,
    output logic                branch,
    output logic                jump,
    output logic                jalr,
    output riscv_pkg::imm_src_t imm_src,
    output riscv_pkg::wb_src_t  wb_src,
    output riscv_pkg::alu_op_t  alu_op,
    output logic                illegal
);

    import riscv_pkg::*;

    always_comb begin
        reg_write    = 1'b0;
        mem_write    = 1'b0;
        alu_a_is_pc  = 1'b0;
        alu_b_is_imm = 1'b0;
        branch       = 1'b0;
        jump         = 1'b0;
        jalr         = 1'b0;
        imm_src      = IMM_I;
        wb_src       = WB_ALU;
        alu_op       = ALU_ADD;
        illegal      = 1'b0;

        case (opcode)
            OPCODE_OP: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000)      alu_op = ALU_ADD;
                        else if (funct7 == 7'b0100000) alu_op = ALU_SUB;
                        else                           illegal = 1'b1;
                    end
                    3'b001: begin alu_op = ALU_SLL;  illegal = (funct7 != 7'b0000000); end
                    3'b010: begin alu_op = ALU_SLT;  illegal = (funct7 != 7'b0000000); end
                    3'b011: begin alu_op = ALU_SLTU; illegal = (funct7 != 7'b0000000); end
                    3'b100: begin alu_op = ALU_XOR;  illegal = (funct7 != 7'b0000000); end
                    3'b101: begin
                        if (funct7 == 7'b0000000)      alu_op = ALU_SRL;
                        else if (funct7 == 7'b0100000) alu_op = ALU_SRA;
                        else                           illegal = 1'b1;
                    end
                    3'b110: begin alu_op = ALU_OR;   illegal = (funct7 != 7'b0000000); end
                    3'b111: begin alu_op = ALU_AND;  illegal = (funct7 != 7'b0000000); end
                    default: illegal = 1'b1;
                endcase
            end

            OPCODE_OP_IMM: begin
                reg_write    = 1'b1;
                alu_b_is_imm = 1'b1;
                imm_src      = IMM_I;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                    3'b001: begin
                        alu_op  = ALU_SLL;
                        illegal = (funct7 != 7'b0000000);
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000)      alu_op = ALU_SRL;
                        else if (funct7 == 7'b0100000) alu_op = ALU_SRA;
                        else                           illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end

            OPCODE_LOAD: begin
                reg_write    = 1'b1;
                alu_b_is_imm = 1'b1;
                imm_src      = IMM_I;
                wb_src       = WB_MEM;
                illegal      = !((funct3 == 3'b000) || (funct3 == 3'b001) ||
                                 (funct3 == 3'b010) || (funct3 == 3'b100) ||
                                 (funct3 == 3'b101));
            end

            OPCODE_STORE: begin
                mem_write    = 1'b1;
                alu_b_is_imm = 1'b1;
                imm_src      = IMM_S;
                illegal      = !((funct3 == 3'b000) || (funct3 == 3'b001) ||
                                 (funct3 == 3'b010));
            end

            OPCODE_BRANCH: begin
                branch  = 1'b1;
                imm_src = IMM_B;
                alu_op  = ALU_SUB;
                illegal = !((funct3 == 3'b000) || (funct3 == 3'b001) ||
                            (funct3 == 3'b100) || (funct3 == 3'b101) ||
                            (funct3 == 3'b110) || (funct3 == 3'b111));
            end

            OPCODE_LUI: begin
                reg_write = 1'b1;
                imm_src   = IMM_U;
                wb_src    = WB_IMM;
            end

            OPCODE_AUIPC: begin
                reg_write    = 1'b1;
                alu_a_is_pc  = 1'b1;
                alu_b_is_imm = 1'b1;
                imm_src      = IMM_U;
            end

            OPCODE_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_src   = IMM_J;
                wb_src    = WB_PC4;
            end

            OPCODE_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                imm_src   = IMM_I;
                wb_src    = WB_PC4;
                illegal   = (funct3 != 3'b000);
            end

            OPCODE_MISC_MEM: begin
                // In a simple, single-hart core with no caches, FENCE is a no-op.
                illegal = (funct3 != 3'b000);
            end

            default: illegal = 1'b1;
        endcase

        if (illegal) begin
            reg_write = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            jump      = 1'b0;
        end
    end

endmodule
