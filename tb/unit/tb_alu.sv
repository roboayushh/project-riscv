`timescale 1ns/1ps

module tb_alu;

    import riscv_pkg::*;

    // Inputs to the ALU
    logic [31:0] a;
    logic [31:0] b;
    alu_op_t op;

    // Outputs from the ALU
    logic [31:0] result;
    logic zero;

    // Test counters
    int passed;
    int failed;

    // Instantiate the actual ALU
    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero)
    );

    // Reusable test procedure
    task automatic run_test(
        input string test_name,
        input alu_op_t operation,
        input logic [31:0] input_a,
        input logic [31:0] input_b,
        input logic [31:0] expected_result
    );

        logic expected_zero;

        begin

            a = input_a;
            b = input_b;
            op = operation;

            // Allow combinational logic to settle
            #1;

            expected_zero = (expected_result == 32'd0);

            if ((result === expected_result) &&
                (zero === expected_zero)) begin

                passed++;

                $display(
                    "PASS: %-28s A=%08h B=%08h Result=%08h",
                    test_name, a, b, result
                );

            end else begin

                failed++;

                $display(
                    "FAIL: %-28s A=%08h B=%08h Expected=%08h Got=%08h Zero=%b",
                    test_name, a, b,
                    expected_result, result, zero
                );

            end
        end

    endtask

    initial begin

        passed = 0;
        failed = 0;

        a = 32'd0;
        b = 32'd0;
        op = ALU_ADD;

        // Enable waveform recording
        $dumpfile("build/waves/alu.vcd");
        $dumpvars(0, tb_alu);

        $display("================================");
        $display("     RV32I ALU TEST SUITE");
        $display("================================");

        // --------------------------------
        // ADD TESTS
        // --------------------------------

        run_test("ADD basic",
            ALU_ADD, 32'd10, 32'd20, 32'd30);

        run_test("ADD negative operand",
            ALU_ADD, 32'hFFFF_FFFB, 32'd3,
            32'hFFFF_FFFE);

        run_test("ADD overflow wrap",
            ALU_ADD, 32'hFFFF_FFFF, 32'd1,
            32'd0);

        run_test("ADD signed boundary",
            ALU_ADD, 32'h7FFF_FFFF, 32'd1,
            32'h8000_0000);

        // --------------------------------
        // SUB TESTS
        // --------------------------------

        run_test("SUB basic",
            ALU_SUB, 32'd20, 32'd10, 32'd10);

        run_test("SUB negative result",
            ALU_SUB, 32'd0, 32'd1,
            32'hFFFF_FFFF);

        run_test("SUB equal operands",
            ALU_SUB, 32'd123, 32'd123,
            32'd0);

        run_test("SUB wraparound",
            ALU_SUB, 32'h8000_0000, 32'd1,
            32'h7FFF_FFFF);

        // --------------------------------
        // BITWISE TESTS
        // --------------------------------

        run_test("AND basic",
            ALU_AND, 32'd12, 32'd10,
            32'd8);

        run_test("AND with zero",
            ALU_AND, 32'hFFFF_FFFF, 32'd0,
            32'd0);

        run_test("OR basic",
            ALU_OR, 32'd12, 32'd10,
            32'd14);

        run_test("OR all bits",
            ALU_OR, 32'hF000_0000,
            32'h0FFF_FFFF, 32'hFFFF_FFFF);

        run_test("XOR basic",
            ALU_XOR, 32'd12, 32'd10,
            32'd6);

        run_test("XOR identical",
            ALU_XOR, 32'hF0F0_F0F0,
            32'hF0F0_F0F0, 32'd0);

        // --------------------------------
        // SHIFT LEFT TESTS
        // --------------------------------

        run_test("SLL basic",
            ALU_SLL, 32'd3, 32'd2,
            32'd12);

        run_test("SLL by 31",
            ALU_SLL, 32'd1, 32'd31,
            32'h8000_0000);

        run_test("SLL lower five bits",
            ALU_SLL, 32'd1, 32'd33,
            32'd2);

        // --------------------------------
        // LOGICAL RIGHT SHIFT TESTS
        // --------------------------------

        run_test("SRL basic",
            ALU_SRL, 32'hF000_0000,
            32'd4, 32'h0F00_0000);

        run_test("SRL by 31",
            ALU_SRL, 32'h8000_0000,
            32'd31, 32'd1);

        run_test("SRL lower five bits",
            ALU_SRL, 32'h8000_0000,
            32'd32, 32'h8000_0000);

        // --------------------------------
        // ARITHMETIC RIGHT SHIFT TESTS
        // --------------------------------

        run_test("SRA negative",
            ALU_SRA, 32'hF000_0000,
            32'd4, 32'hFF00_0000);

        run_test("SRA by 31",
            ALU_SRA, 32'h8000_0000,
            32'd31, 32'hFFFF_FFFF);

        run_test("SRA positive",
            ALU_SRA, 32'h7FFF_FFFF,
            32'd1, 32'h3FFF_FFFF);

        run_test("SRA lower five bits",
            ALU_SRA, 32'h8000_0000,
            32'd32, 32'h8000_0000);

        // --------------------------------
        // SIGNED LESS-THAN TESTS
        // --------------------------------

        run_test("SLT negative vs positive",
            ALU_SLT, 32'hFFFF_FFFB,
            32'd2, 32'd1);

        run_test("SLT positive vs negative",
            ALU_SLT, 32'd2,
            32'hFFFF_FFFF, 32'd0);

        run_test("SLT equal",
            ALU_SLT, 32'd5, 32'd5,
            32'd0);

        run_test("SLT positive order",
            ALU_SLT, 32'd2, 32'd5,
            32'd1);

        // --------------------------------
        // UNSIGNED LESS-THAN TESTS
        // --------------------------------

        run_test("SLTU large vs small",
            ALU_SLTU, 32'hFFFF_FFFF,
            32'd1, 32'd0);

        run_test("SLTU small vs large",
            ALU_SLTU, 32'd1,
            32'hFFFF_FFFF, 32'd1);

        run_test("SLTU equal",
            ALU_SLTU, 32'd5, 32'd5,
            32'd0);

        run_test("SLTU unsigned boundary",
            ALU_SLTU, 32'h7FFF_FFFF,
            32'h8000_0000, 32'd1);

        // --------------------------------
        // TEST SUMMARY
        // --------------------------------

        $display("================================");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("================================");

        if (failed > 0) begin
            $fatal(1, "ALU verification FAILED");
        end

        $display("ALL ALU TESTS PASSED!");

        $finish;

    end

endmodule
