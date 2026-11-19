# project-riscv

A SystemVerilog implementation of RV32I processor components, currently including
an ALU and a 32-register integer register file. Unit testbenches are built and run
with Verilator.

## Repository layout

```text
rtl/
  core/                  Core RTL modules
  pkg/                   Shared RISC-V types and constants
tb/
  unit/                  Unit testbenches
build/                   Generated binaries, C++, and waveforms (ignored by Git)
```

## macOS setup (Apple Silicon/M3 Pro)

These instructions are for an Apple Silicon Mac and should report `arm64` from
`uname -m`.

### 1. Install Apple's command-line developer tools

The tools provide Clang and `make`, which Verilator uses to compile generated C++:

```bash
xcode-select --install
```

If macOS says the tools are already installed, continue to the next step.

### 2. Install Homebrew

Install Homebrew using the command on [brew.sh](https://brew.sh/). On Apple
Silicon, its default prefix is `/opt/homebrew`. After installation, follow the
shell configuration command printed by the installer so that `brew` is on your
`PATH`.

Check the installation:

```bash
brew --version
```

### 3. Install Verilator

```bash
brew install verilator
verilator --version
```

Homebrew provides a native Apple Silicon Verilator package. No Rosetta setup is
needed.

Optionally install [Surfer](https://surfer-project.org/) to inspect VCD waveform
files:

```bash
brew install surfer
```

### 4. Get and prepare the repository

```bash
git clone <repository-url> project-riscv
cd project-riscv
mkdir -p build/waves
```

Run all commands below from the repository root. Source-file order matters for
the ALU because `riscv_pkg.sv` defines the `alu_op_t` type used by the module and
testbench.

## Lint

Lint the synthesizable RTL:

```bash
verilator --lint-only --timing -Wall --top-module alu \
  rtl/pkg/riscv_pkg.sv \
  rtl/core/alu.sv

verilator --lint-only --timing -Wall --top-module regfile \
  rtl/core/regfile.sv
```

Lint the complete unit-test designs:

```bash
verilator --lint-only --timing -Wall --top-module tb_alu \
  rtl/pkg/riscv_pkg.sv \
  rtl/core/alu.sv \
  tb/unit/tb_alu.sv

verilator --lint-only --timing -Wall --top-module tb_regfile \
  rtl/core/regfile.sv \
  tb/unit/tb_regfile.sv
```

`-Wall` enables useful diagnostics. Verilator treats these warnings as build
failures, which keeps lint problems from being overlooked.

## Build and test

Create the waveform output directory once per clean build:

```bash
mkdir -p build/waves
```

### ALU

Build the testbench:

```bash
verilator --binary --timing --trace -Wall \
  --top-module tb_alu \
  --Mdir build/obj_alu \
  -o tb_alu \
  rtl/pkg/riscv_pkg.sv \
  rtl/core/alu.sv \
  tb/unit/tb_alu.sv
```

Run it:

```bash
./build/obj_alu/tb_alu
```

A successful run reports 32 passed tests and writes
`build/waves/alu.vcd`.

### Register file

Build the testbench:

```bash
verilator --binary --timing --trace -Wall \
  --top-module tb_regfile \
  --Mdir build/obj_regfile \
  -o tb_regfile \
  rtl/core/regfile.sv \
  tb/unit/tb_regfile.sv
```

Run it:

```bash
./build/obj_regfile/tb_regfile
```

A successful run reports 37 passed checks and writes
`build/waves/regfile.vcd`.

## View waveforms

With Surfer installed:

```bash
surfer build/waves/alu.vcd
surfer build/waves/regfile.vcd
```

The `--trace` build option is required for Verilator to enable the `$dumpfile`
and `$dumpvars` calls used by the testbenches.

## Clean generated files

All generated files are kept under `build/`, so a clean build can be started
with:

```bash
rm -rf build
mkdir -p build/waves
```
