`timescale 1ns/1ps

module tb_riscv_core;

    /* verilator lint_off UNUSEDSIGNAL */
    logic clk;
    logic reset_n;
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0] dmem_wstrb;
    logic [31:0] dmem_rdata;
    logic [31:0] pc;
    logic illegal_instruction;
    logic misaligned_access;

    logic [31:0] instruction_memory [0:63];
    logic [31:0] data_memory [0:63];
    int cycles;

    riscv_core dut (.*);

    assign imem_rdata = instruction_memory[imem_addr[7:2]];
    assign dmem_rdata = data_memory[dmem_addr[7:2]];

    always_ff @(posedge clk) begin
        if (dmem_wstrb[0]) data_memory[dmem_addr[7:2]][7:0]   <= dmem_wdata[7:0];
        if (dmem_wstrb[1]) data_memory[dmem_addr[7:2]][15:8]  <= dmem_wdata[15:8];
        if (dmem_wstrb[2]) data_memory[dmem_addr[7:2]][23:16] <= dmem_wdata[23:16];
        if (dmem_wstrb[3]) data_memory[dmem_addr[7:2]][31:24] <= dmem_wdata[31:24];
    end

    function automatic logic [31:0] enc_r(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_i(
        input integer signed imm,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        logic [11:0] value;
        value = 12'(imm);
        return {value, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_s(
        input integer signed imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3
    );
        logic [11:0] value;
        value = 12'(imm);
        return {value[11:5], rs2, rs1, funct3, value[4:0], 7'b0100011};
    endfunction

    function automatic logic [31:0] enc_b(
        input integer signed imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3
    );
        logic [12:0] value;
        value = 13'(imm);
        return {value[12], value[10:5], rs2, rs1, funct3,
                value[4:1], value[11], 7'b1100011};
    endfunction

    function automatic logic [31:0] enc_u(
        input logic [19:0] upper,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        return {upper, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_j(
        input integer signed imm,
        input logic [4:0] rd
    );
        logic [20:0] value;
        value = 21'(imm);
        return {value[20], value[10:1], value[11], value[19:12], rd, 7'b1101111};
    endfunction

    task automatic expect_register(
        input int index,
        input logic [31:0] expected
    );
        if (dut.register_file.regs[index] !== expected)
            $fatal(1, "x%0d expected=%08h got=%08h", index, expected,
                   dut.register_file.regs[index]);
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_n = 1'b0;
        cycles = 0;
        for (int i = 0; i < 64; i++) begin
            instruction_memory[i] = enc_j(0, 0);
            data_memory[i] = 32'b0;
        end

        instruction_memory[0]  = enc_i(5,  0, 3'b000, 1, 7'b0010011); // addi x1,x0,5
        instruction_memory[1]  = enc_i(7,  0, 3'b000, 2, 7'b0010011); // addi x2,x0,7
        instruction_memory[2]  = enc_r(7'b0000000, 2, 1, 3'b000, 3, 7'b0110011); // add
        instruction_memory[3]  = enc_r(7'b0100000, 1, 2, 3'b000, 4, 7'b0110011); // sub
        instruction_memory[4]  = enc_i(2,  1, 3'b001, 5, 7'b0010011); // slli x5,x1,2
        instruction_memory[5]  = enc_r(7'b0000000, 2, 1, 3'b010, 6, 7'b0110011); // slt
        instruction_memory[6]  = enc_s(0,  3, 0, 3'b010); // sw x3,0(x0)
        instruction_memory[7]  = enc_i(0,  0, 3'b010, 7, 7'b0000011); // lw x7,0(x0)
        instruction_memory[8]  = enc_s(1,  2, 0, 3'b000); // sb x2,1(x0)
        instruction_memory[9]  = enc_i(1,  0, 3'b100, 8, 7'b0000011); // lbu x8,1(x0)
        instruction_memory[10] = enc_b(8, 1, 1, 3'b000); // beq, skip next
        instruction_memory[11] = enc_i(99, 0, 3'b000, 9, 7'b0010011);
        instruction_memory[12] = enc_j(8, 10); // jal x10,+8
        instruction_memory[13] = enc_i(99, 0, 3'b000, 9, 7'b0010011);
        instruction_memory[14] = enc_u(20'h00000, 11, 7'b0010111); // auipc x11,0
        instruction_memory[15] = enc_u(20'h12345, 12, 7'b0110111); // lui x12,0x12345
        instruction_memory[16] = enc_i(76, 0, 3'b000, 14, 7'b0010011);
        instruction_memory[17] = enc_i(0, 14, 3'b000, 13, 7'b1100111); // jalr x13,0(x14)
        instruction_memory[18] = enc_i(99, 0, 3'b000, 9, 7'b0010011);
        instruction_memory[19] = enc_i(3, 3, 3'b111, 15, 7'b0010011); // andi x15,x3,3
        instruction_memory[20] = enc_s(4, 15, 0, 3'b010); // signature store
        instruction_memory[21] = enc_j(0, 0); // halt loop

        $dumpfile("build/waves/riscv_core.vcd");
        $dumpvars(0, tb_riscv_core);

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset_n = 1'b1;

        while ((pc != 32'd84) && (cycles < 40)) begin
            @(posedge clk);
            #1;
            cycles++;
            if (illegal_instruction)
                $fatal(1, "Illegal instruction at PC=%08h", pc);
            if (misaligned_access)
                $fatal(1, "Misaligned access at PC=%08h", pc);
        end

        if (pc != 32'd84)
            $fatal(1, "Core did not reach halt loop, PC=%08h", pc);

        expect_register(1,  32'd5);
        expect_register(2,  32'd7);
        expect_register(3,  32'd12);
        expect_register(4,  32'd2);
        expect_register(5,  32'd20);
        expect_register(6,  32'd1);
        expect_register(7,  32'd12);
        expect_register(8,  32'd7);
        expect_register(10, 32'd52);
        expect_register(11, 32'd56);
        expect_register(12, 32'h1234_5000);
        expect_register(13, 32'd72);
        expect_register(15, 32'd0);

        if (data_memory[0] !== 32'h0000_070c)
            $fatal(1, "Store/load data mismatch: %08h", data_memory[0]);
        if (data_memory[1] !== 32'd0)
            $fatal(1, "Signature mismatch: %08h", data_memory[1]);

        $display("RV32I CORE INTEGRATION TEST PASSED (%0d cycles)", cycles);
        $finish;
    end

    /* verilator lint_on UNUSEDSIGNAL */

endmodule
