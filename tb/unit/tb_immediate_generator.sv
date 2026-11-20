`timescale 1ns/1ps

module tb_immediate_generator;

    import riscv_pkg::*;

    logic [31:0] instruction;
    imm_src_t imm_src;
    logic [31:0] immediate;
    int passed;

    immediate_generator dut (.*);

    task automatic check_imm(
        input string name,
        input logic [31:0] inst,
        input imm_src_t source,
        input logic [31:0] expected
    );
        instruction = inst;
        imm_src = source;
        #1;
        if (immediate !== expected)
            $fatal(1, "FAIL: %s expected=%08h got=%08h", name, expected, immediate);
        passed++;
        $display("PASS: %s", name);
    endtask

    initial begin
        passed = 0;
        $dumpfile("build/waves/immediate_generator.vcd");
        $dumpvars(0, tb_immediate_generator);

        check_imm("I positive", 32'h00c5_2483, IMM_I, 32'd12);
        check_imm("I negative", 32'hff43_0293, IMM_I, 32'hffff_fff4);
        check_imm("S positive", 32'h0074_2a23, IMM_S, 32'd20);
        check_imm("S negative", 32'hfe74_2c23, IMM_S, 32'hffff_fff8);
        check_imm("B forward",  32'h0020_8463, IMM_B, 32'd8);
        check_imm("B backward", 32'hfe20_8ce3, IMM_B, 32'hffff_fff8);
        check_imm("U",          32'h1234_5537, IMM_U, 32'h1234_5000);
        check_imm("J forward",  32'h0100_00ef, IMM_J, 32'd16);
        check_imm("J backward", 32'hff9f_f0ef, IMM_J, 32'hffff_fff8);

        $display("Passed: %0d", passed);
        $display("ALL IMMEDIATE GENERATOR TESTS PASSED");
        $finish;
    end

endmodule
