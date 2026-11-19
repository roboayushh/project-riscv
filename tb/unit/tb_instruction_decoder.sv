`timescale 1ns/1ps

module tb_instruction_decoder;

    logic [31:0] instruction;

logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    int passed = 0;

instruction_decoder dut (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

task automatic check_decode(
        input string name,
        input logic [31:0] inst,
        input logic [6:0] exp_opcode,
        input logic [4:0] exp_rd,
        input logic [2:0] exp_funct3,
        input logic [4:0] exp_rs1,
        input logic [4:0] exp_rs2,
        input logic [6:0] exp_funct7
    );

instruction = inst;
        #1;

if (opcode !== exp_opcode ||
            rd     !== exp_rd ||
            funct3 !== exp_funct3 ||
            rs1    !== exp_rs1 ||
            rs2    !== exp_rs2 ||
            funct7 !== exp_funct7) begin

$fatal(1,
                "FAIL: %s, instruction=%08h",
                name, instruction
            );

        end

passed++;
        $display("PASS: %s", name);

    endtask

    initial begin

$dumpfile("build/waves/decoder.vcd");
        $dumpvars(0, tb_instruction_decoder);

// R-type: ADD x3, x1, x2
        check_decode(
            "ADD",
            32'h002081B3,
            7'h33, 5'd3, 3'd0,
            5'd1, 5'd2, 7'h00
        );

// R-type: SUB x3, x1, x2
        check_decode(
            "SUB",
            32'h402081B3,
            7'h33, 5'd3, 3'd0,
            5'd1, 5'd2, 7'h20
        );

// I-type: ADDI x5, x6, -12
        check_decode(
            "ADDI",
            32'hFF430293,
            7'h13, 5'd5, 3'd0,
            5'd6, 5'd20, 7'h7F
        );

// I-type: LW x9, 12(x10)
        check_decode(
            "LW",
            32'h00C52483,
            7'h03, 5'd9, 3'd2,
            5'd10, 5'd12, 7'h00
        );

// S-type: SW x7, 20(x8)
        check_decode(
            "SW",
            32'h00742A23,
            7'h23, 5'd20, 3'd2,
            5'd8, 5'd7, 7'h00
        );

// B-type: BEQ x1, x2, 8
        check_decode(
            "BEQ",
            32'h00208463,
            7'h63, 5'd8, 3'd0,
            5'd1, 5'd2, 7'h00
        );

// U-type: LUI x10, 0x12345
        check_decode(
            "LUI",
            32'h12345537,
            7'h37, 5'd10, 3'd5,
            5'd8, 5'd3, 7'h09
        );

// J-type: JAL x1, 16
        check_decode(
            "JAL",
            32'h010000EF,
            7'h6F, 5'd1, 3'd0,
            5'd0, 5'd16, 7'h00
        );

$display("========================");
        $display("Passed: %0d", passed);
        $display("ALL DECODER TESTS PASSED");
        $display("========================");

        $finish;

    end

endmodule
