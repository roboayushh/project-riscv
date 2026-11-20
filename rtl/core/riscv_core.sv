`timescale 1ns/1ps

module riscv_core (
    input  logic        clk,
    input  logic        reset_n,

    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,
    input  logic [31:0] dmem_rdata,

    output logic [31:0] pc,
    output logic        illegal_instruction,
    output logic        misaligned_access
);

    import riscv_pkg::*;

    logic [31:0] next_pc;
    logic [31:0] pc_plus_four;
    logic [31:0] branch_target;
    logic [31:0] jalr_target;
    logic [31:0] jump_target;
    logic [31:0] immediate;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic [31:0] load_data;
    logic [31:0] writeback_data;

    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    logic       reg_write;
    logic       mem_write;
    logic       alu_a_is_pc;
    logic       alu_b_is_imm;
    logic       branch;
    logic       jump;
    logic       jalr;
    logic       branch_taken;
    logic       alu_zero;
    logic       control_illegal;
    logic       memory_misaligned;
    logic       instruction_misaligned;
    logic [3:0] raw_dmem_wstrb;
    imm_src_t   imm_src;
    wb_src_t    wb_src;
    alu_op_t    alu_op;

    assign imem_addr     = pc;
    assign pc_plus_four  = pc + 32'd4;
    assign branch_target = pc + immediate;
    assign jalr_target   = (rs1_data + immediate) & 32'hffff_fffe;
    assign jump_target   = jalr ? jalr_target : branch_target;

    instruction_decoder decoder (
        .instruction(imem_rdata),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    control_unit controller (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_a_is_pc(alu_a_is_pc),
        .alu_b_is_imm(alu_b_is_imm),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .imm_src(imm_src),
        .wb_src(wb_src),
        .alu_op(alu_op),
        .illegal(control_illegal)
    );

    immediate_generator immediate_gen (
        .instruction(imem_rdata),
        .imm_src(imm_src),
        .immediate(immediate)
    );

    regfile register_file (
        .clk(clk),
        .we(reg_write && reset_n && !illegal_instruction && !misaligned_access),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(writeback_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    assign alu_a = alu_a_is_pc  ? pc        : rs1_data;
    assign alu_b = alu_b_is_imm ? immediate : rs2_data;

    alu execution_alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    always_comb begin
        case (funct3)
            3'b000: branch_taken = alu_zero;                                  // BEQ
            3'b001: branch_taken = !alu_zero;                                 // BNE
            3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));   // BLT
            3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));  // BGE
            3'b110: branch_taken = (rs1_data < rs2_data);                     // BLTU
            3'b111: branch_taken = (rs1_data >= rs2_data);                    // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    load_store_unit load_store (
        .funct3(funct3),
        .address_low(alu_result[1:0]),
        .store_data(rs2_data),
        .memory_read_data(dmem_rdata),
        .load_data(load_data),
        .memory_write_data(dmem_wdata),
        .memory_write_strobe(raw_dmem_wstrb),
        .misaligned(memory_misaligned)
    );

    assign dmem_addr = alu_result;
    assign instruction_misaligned =
        (jump && (jump_target[1:0] != 2'b00)) ||
        (branch && branch_taken && (branch_target[1:0] != 2'b00));
    assign misaligned_access =
        ((((opcode == OPCODE_LOAD) || (opcode == OPCODE_STORE)) &&
          memory_misaligned) || instruction_misaligned);
    assign dmem_wstrb = raw_dmem_wstrb & {4{mem_write && reset_n &&
                                            !illegal_instruction &&
                                            !misaligned_access}};

    always_comb begin
        case (wb_src)
            WB_ALU: writeback_data = alu_result;
            WB_MEM: writeback_data = load_data;
            WB_PC4: writeback_data = pc_plus_four;
            WB_IMM: writeback_data = immediate;
            default: writeback_data = 32'b0;
        endcase
    end

    assign illegal_instruction = control_illegal;

    always_comb begin
        next_pc = pc_plus_four;
        if (branch && branch_taken)
            next_pc = branch_target;
        if (jump)
            next_pc = jump_target;
        if (illegal_instruction || misaligned_access)
            next_pc = pc;
    end

    always_ff @(posedge clk) begin
        if (!reset_n)
            pc <= 32'b0;
        else
            pc <= next_pc;
    end

endmodule
