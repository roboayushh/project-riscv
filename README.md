# project-riscv

A single-cycle RV32I processor core written in SystemVerilog and verified with
Verilator.

The core implements the user-mode integer execution path: RV32I register and
immediate ALU operations, branches, `JAL`, `JALR`, `LUI`, `AUIPC`, and signed or
unsigned byte/halfword/word memory accesses. `FENCE` is a no-op, which is valid
for this single-hart core without caches. Privileged state, CSRs, interrupts,
exceptions, and the execution-environment behavior of `ECALL`/`EBREAK` are
outside the current scope; unsupported encodings assert `illegal_instruction`.

## Repository layout

```text
rtl/
  core/                  Core RTL modules
  pkg/                   Shared RISC-V types and constants
tb/
  unit/                  Unit testbenches
  integration/           Complete-core program test
build/                   Generated binaries, C++, and waveforms (ignored by Git)
```

## Core architecture

```text
 instruction memory
         |
         v
 PC -> decoder -> control + immediate generator
         |                    |
         v                    v
    register file ---------> ALU -----> data memory
         ^                    |              |
         |                    +--------------+
         +-------- writeback mux (ALU/memory/PC+4/immediate)
```

`riscv_core` uses separate combinational instruction and data-memory read
interfaces. Stores provide four byte write strobes. The PC and register-file
writes update on the rising clock edge.

### Top-level interface

| Signal | Direction | Purpose |
|---|---|---|
| `clk`, `reset_n` | input | Clock and synchronous active-low reset |
| `imem_addr` | output | Byte address of the current instruction |
| `imem_rdata` | input | 32-bit instruction returned by instruction memory |
| `dmem_addr` | output | Effective byte address for a load/store |
| `dmem_wdata` | output | Store data arranged for the selected byte lanes |
| `dmem_wstrb[3:0]` | output | One write enable per byte lane; zero for no store |
| `dmem_rdata` | input | Aligned 32-bit word returned by data memory |
| `pc` | output | Current program counter, also useful for debugging |
| `illegal_instruction` | output | Unsupported or invalid instruction encoding |
| `misaligned_access` | output | Misaligned data access or control-flow target |

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

The easiest way to lint the core and every testbench is:

```bash
make lint
```

The equivalent direct Verilator commands can be useful while developing an
individual module. For example, lint the complete core with:

```bash
verilator --lint-only --timing -Wall --top-module riscv_core \
  rtl/pkg/riscv_pkg.sv \
  rtl/core/instruction_decoder.sv \
  rtl/core/immediate_generator.sv \
  rtl/core/control_unit.sv \
  rtl/core/alu.sv \
  rtl/core/regfile.sv \
  rtl/core/load_store_unit.sv \
  rtl/core/riscv_core.sv
```

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

Run the entire lint and test suite:

```bash
make test
```

Individual targets are also available:

```bash
make test-alu
make test-regfile
make test-decoder
make test-immediate
make test-core
```

`make test-core` runs a small machine-code program through the complete datapath
and checks arithmetic, control flow, memory byte lanes, writeback, and final
architectural state.

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
surfer build/waves/decoder.vcd
surfer build/waves/immediate_generator.vcd
surfer build/waves/riscv_core.vcd
```

The `--trace` build option is required for Verilator to enable the `$dumpfile`
and `$dumpvars` calls used by the testbenches.

## Clean generated files

All generated files are kept under `build/`, so a clean build can be started
with:

```bash
make clean
```
