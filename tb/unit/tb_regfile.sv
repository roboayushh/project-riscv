
`timescale 1ns/1ps

module tb_regfile;

    logic clk;
    logic we;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] wd;
    logic [31:0] rd1, rd2;

    int passed = 0;


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Device Under Test (DUT)
    regfile dut (
        .clk(clk),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Write to a register
    task automatic write_reg(
        input logic [4:0] addr,
        input logic [31:0] data
    );
        @(negedge clk);

        we = 1;
        rd = addr;
        wd = data;

        @(posedge clk);
        #1;
        we = 0;
    endtask

    // Check both read ports
    task automatic check_read(
        input string test_name,
        input logic [4:0] addr1,
        input logic [4:0] addr2,
        input logic [31:0] expected1,
        input logic [31:0] expected2
    );

        rs1 = addr1;
        rs2 = addr2;

        #1;

        if (rd1 !== expected1 ||
            rd2 !== expected2) begin

            $fatal(1,
                "FAIL: %s | Expected: %h %h | Got: %h %h",
                test_name, expected1, expected2, rd1, rd2
            );

        end else begin
            passed++;
            $display("PASS: %s", test_name);
        end

    endtask

    initial begin

        // Initialize inputs
        we = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        wd = 0;

        // Waveform generation
        $dumpfile("build/waves/regfile.vcd");
        $dumpvars(0, tb_regfile);

        $display("==============================");
        $display("     REGISTER FILE TESTS");
        $display("==============================");

        // TEST 1: x0 always equals zero
        check_read("x0 reads zero",
            0, 0, 0, 0);

        // TEST 2: Write and read two registers
        write_reg(1, 32'd100);
        write_reg(2, 32'd200);

        check_read("Two simultaneous reads",
            1, 2, 100, 200);

        // TEST 3: Both ports read same register
        check_read("Same register on both ports",
            1, 1, 100, 100);

        // TEST 4: x0 cannot be modified
        write_reg(0, 32'd999);

        check_read("x0 is immutable",
            0, 1, 0, 100);

        // TEST 5: Overwrite register value
        write_reg(1, 32'd500);

        check_read("Register overwrite",
            1, 2, 500, 200);

        // TEST 6: Write enable disabled
        @(negedge clk);
        we = 0;
        rd = 2;
        wd = 32'd999;

        @(posedge clk);
        #1;

        check_read("Write enable disabled",
            2, 1, 200, 500);

        // TEST 7-37: Test every writable register
        for (int i = 1; i < 32; i++) begin
            write_reg(i[4:0], i * 32'd17);
        end

        for (int i = 1; i < 32; i++) begin
            check_read(
                $sformatf("Register x%0d", i),
                i[4:0],
                5'd0,
                i * 32'd17,
                32'd0
            );
        end

        $display("==============================");
        $display("Passed: %0d", passed);
        $display("ALL REGISTER FILE TESTS PASSED");
        $display("==============================");

        $finish;

    end

endmodule
