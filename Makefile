VERILATOR := verilator
COMMON_FLAGS := --timing -Wall
BUILD_FLAGS := --binary --trace $(COMMON_FLAGS)

PKG := rtl/pkg/riscv_pkg.sv
CORE_RTL := \
	rtl/core/instruction_decoder.sv \
	rtl/core/immediate_generator.sv \
	rtl/core/control_unit.sv \
	rtl/core/alu.sv \
	rtl/core/regfile.sv \
	rtl/core/load_store_unit.sv \
	rtl/core/riscv_core.sv

.PHONY: all lint test test-alu test-regfile test-decoder test-immediate test-core clean

all: test

build/waves:
	mkdir -p $@

lint:
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module riscv_core $(PKG) $(CORE_RTL)
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module tb_alu $(PKG) rtl/core/alu.sv tb/unit/tb_alu.sv
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module tb_regfile rtl/core/regfile.sv tb/unit/tb_regfile.sv
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module tb_instruction_decoder rtl/core/instruction_decoder.sv tb/unit/tb_instruction_decoder.sv
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module tb_immediate_generator $(PKG) rtl/core/immediate_generator.sv tb/unit/tb_immediate_generator.sv
	$(VERILATOR) --lint-only $(COMMON_FLAGS) --top-module tb_riscv_core $(PKG) $(CORE_RTL) tb/integration/tb_riscv_core.sv

test: lint test-alu test-regfile test-decoder test-immediate test-core

test-alu: build/waves
	$(VERILATOR) $(BUILD_FLAGS) --top-module tb_alu --Mdir build/obj_alu -o tb_alu $(PKG) rtl/core/alu.sv tb/unit/tb_alu.sv
	./build/obj_alu/tb_alu

test-regfile: build/waves
	$(VERILATOR) $(BUILD_FLAGS) --top-module tb_regfile --Mdir build/obj_regfile -o tb_regfile rtl/core/regfile.sv tb/unit/tb_regfile.sv
	./build/obj_regfile/tb_regfile

test-decoder: build/waves
	$(VERILATOR) $(BUILD_FLAGS) --top-module tb_instruction_decoder --Mdir build/obj_decoder -o tb_decoder rtl/core/instruction_decoder.sv tb/unit/tb_instruction_decoder.sv
	./build/obj_decoder/tb_decoder

test-immediate: build/waves
	$(VERILATOR) $(BUILD_FLAGS) --top-module tb_immediate_generator --Mdir build/obj_immediate -o tb_immediate $(PKG) rtl/core/immediate_generator.sv tb/unit/tb_immediate_generator.sv
	./build/obj_immediate/tb_immediate

test-core: build/waves
	$(VERILATOR) $(BUILD_FLAGS) --top-module tb_riscv_core --Mdir build/obj_core -o tb_core $(PKG) $(CORE_RTL) tb/integration/tb_riscv_core.sv
	./build/obj_core/tb_core

clean:
	rm -rf build
