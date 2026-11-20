`timescale 1ns/1ps

module load_store_unit (
    input  logic [2:0]  funct3,
    input  logic [1:0]  address_low,
    input  logic [31:0] store_data,
    input  logic [31:0] memory_read_data,

    output logic [31:0] load_data,
    output logic [31:0] memory_write_data,
    output logic [3:0]  memory_write_strobe,
    output logic        misaligned
);

    logic [15:0] shifted_read_data;
    logic [4:0]  shift_amount;

    always_comb begin
        shift_amount       = {address_low, 3'b000};
        shifted_read_data  = 16'(memory_read_data >> shift_amount);
        load_data          = 32'b0;
        memory_write_data  = 32'b0;
        memory_write_strobe = 4'b0000;
        misaligned         = 1'b0;

        case (funct3)
            3'b000: load_data = {{24{shifted_read_data[7]}}, shifted_read_data[7:0]};
            3'b001: begin
                load_data  = {{16{shifted_read_data[15]}}, shifted_read_data[15:0]};
                misaligned = address_low[0];
            end
            3'b010: begin
                load_data  = memory_read_data;
                misaligned = (address_low != 2'b00);
            end
            3'b100: load_data = {24'b0, shifted_read_data[7:0]};
            3'b101: begin
                load_data  = {16'b0, shifted_read_data[15:0]};
                misaligned = address_low[0];
            end
            default: load_data = 32'b0;
        endcase

        case (funct3)
            3'b000: begin
                memory_write_strobe = 4'b0001 << address_low;
                memory_write_data   = {4{store_data[7:0]}};
            end
            3'b001: begin
                memory_write_strobe = address_low[1] ? 4'b1100 : 4'b0011;
                memory_write_data   = {2{store_data[15:0]}};
                misaligned          = address_low[0];
            end
            3'b010: begin
                memory_write_strobe = 4'b1111;
                memory_write_data   = store_data;
                misaligned          = (address_low != 2'b00);
            end
            default: begin
                memory_write_strobe = 4'b0000;
                memory_write_data   = 32'b0;
            end
        endcase
    end

endmodule
