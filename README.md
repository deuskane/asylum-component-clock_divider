<!--
  README GENERATION INSTRUCTIONS (for the next regeneration run)
  ----------------------------------------------------------------
  This README follows the common Asylum IP model. Regenerate it from the
  sources, never from the previous README text alone.

  Sources of truth (in priority order):
    1. hdl/*.vhd            : entities, generics, ports, packages
    2. hdl/csr/*.hjson      : register map (regtool); *_csr.md/.h are generated
    3. <IP>.core            : VLNV (name), filesets, targets, depends, revisions
    4. mk/targets.txt       : target list shown by `make help`; mk/defs.mk
    5. sim/, syn/, esw/, boards/ : testbenches, constraints, software
  Section order (keep it, same headings in every IP):
    CI badge / Title + one-line description + VLNV / Table of Contents /
    Introduction (Key Features) / Block Diagram / Top-Level (Parameters,
    Ports, Instantiation Example) / HDL Modules / Register Map /
    Verification / Synthesis / Design Notes (optional) /
    Directory Structure / Dependencies
  Rules:
    - Language: English. Tables: Parameters = Name|Type|Default|Description,
      Ports = Name|Direction|Type|Description (grouped by interface).
    - Register Map: link to the generated hdl/csr/<X>_csr.md (plus the
      .hjson source and _csr.h header); never copy register tables here.
    - Top-Level = sbi_* wrapper if present, else the entity used by the
      `default` target, else the main entity (libraries: list packages).
    - Write "This IP has no software-visible registers." / "No dedicated
      synthesis target ..." instead of removing a section.
    - Keep still-accurate hand-written content (ISA tables, results,
      images) in "Design Notes"; drop anything not backed by the sources.
    - Block diagram: doc/<NAME>.drawio (NAME = 4th field of the VLNV),
      top entity box with generics on top, inputs left, outputs right,
      bus interfaces as bold arrows, internal blocks colour-coded
      (CSR yellow, FIFO/memory green, core logic blue, external grey).
      Update it whenever ports/generics/sub-blocks change.
    - Do not edit generated files (hdl/csr/*_csr.*) or the CI badge URL.
-->
[![CI](https://github.com/deuskane/asylum-component-clock_divider/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-component-clock_divider/actions/workflows/ci.yml)

# asylum-component-clock_divider

**Static-ratio clock divider with "pulse" and "50%" duty-cycle algorithms, clock enable and technology clock buffer.**

VLNV: `asylum:component:clock_divider:2.0.3`

## Table of Contents

1. [Introduction](#introduction)
2. [Block Diagram](#block-diagram)
3. [Top-Level](#top-level)
4. [HDL Modules](#hdl-modules)
5. [Register Map](#register-map)
6. [Verification](#verification)
7. [Synthesis](#synthesis)
8. [Design Notes](#design-notes)
9. [Directory Structure](#directory-structure)
10. [Dependencies](#dependencies)

## Introduction

This IP divides an input clock by a ratio fixed at elaboration time (`RATIO` generic). A down-counter clocked on the rising edge of `clk_i` produces either a one-cycle pulse every `RATIO` cycles (`ALGO = "pulse"`) or a clock of period `RATIO` with a 50 % duty cycle (`ALGO = "50%"`, using an additional falling-edge register for odd ratios). The result is driven through the `cbufg` clock buffer of `asylum:target:techmap`, so it can be mapped on a global clock resource of the target technology.

### Key Features

- Static division ratio (`RATIO : positive`), `RATIO = 1` bypasses the divider (`clk_div_o <= clk_i`)
- `"pulse"` algorithm: one `clk_i` cycle high every `RATIO` cycles
- `"50%"` algorithm: period `RATIO` cycles, `RATIO/2` cycles high and low (half-cycle correction with a falling-edge register when `RATIO` is odd)
- Clock enable `cke_i`: counter and output registers freeze when low
- Asynchronous active-low reset `arstn_i`
- Output driven through the technology clock buffer `cbufg` (generic pass-through or NanoXplore NG-Medium cell, selected by `asylum:target:techmap`)
- Component declaration available in `asylum.clock_divider_pkg`

## Block Diagram

Diagram: [doc/clock_divider.drawio](doc/clock_divider.drawio) (open with diagrams.net or the VS Code Draw.io extension).

- `clk_counter_r` counts down from `RATIO-1` to 0 and reloads (period `RATIO` for both algorithms).
- `clk_div_pos_r` (rising edge) is `1` when the counter is 0 (`"pulse"`) or when the counter is `>= RATIO - RATIO/2` (`"50%"`, i.e. `RATIO/2` cycles high).
- `clk_div_neg_r` samples `clk_div_pos_r` on the falling edge; it is ORed with `clk_div_pos_r` only for `"50%"` with an odd `RATIO`.
- The selected signal (`clk_div`) goes through `cbufg` to `clk_div_o`.
- All registers are gated by `cke_i` and asynchronously reset by `arstn_i`; with `RATIO = 1` none of them is generated.

## Top-Level

Top-level entity: **`clock_divider`** ([hdl/clock_divider.vhd](hdl/clock_divider.vhd)), library `asylum`, component declared in `asylum.clock_divider_pkg`.

### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `RATIO` | positive | `2` | Static division ratio; `1` = no division (`clk_div_o` connected to `clk_i`) |
| `ALGO` | string | `"pulse"` | Division algorithm: `"pulse"` (one-cycle pulse) or `"50%"` (50 % duty cycle). Any other value triggers an assertion (severity failure); tools that ignore it build the `"pulse"` divider |

### Ports

#### Clock & Reset

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | Input clock |
| `cke_i` | in | std_logic | Clock enable, active high: the divider advances only when `1` |
| `arstn_i` | in | std_logic | Asynchronous reset, active low |

#### Divided Clock

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_div_o` | out | std_logic | Divided clock (through `cbufg` when `RATIO > 1`) |

### Instantiation Example

```vhdl
library asylum;
use     asylum.clock_divider_pkg.all;

  ins_clock_divider : entity asylum.clock_divider
    generic map
    ( RATIO     => 4
     ,ALGO      => "50%"
    )
    port map
    ( clk_i     => clk
     ,cke_i     => '1'
     ,arstn_i   => arst_b
     ,clk_div_o => clk_div4
    );
```

## HDL Modules

| File | Unit | Kind | Role |
|------|------|------|------|
| [hdl/clock_divider_pkg.vhd](hdl/clock_divider_pkg.vhd) | `clock_divider_pkg` | package | Component declaration of `clock_divider` |
| [hdl/clock_divider.vhd](hdl/clock_divider.vhd) | `clock_divider` | entity | Top-level: counter, pulse / 50 % generation, falling-edge register, `cbufg` instance |

There is no secondary entity in this IP.

## Register Map

This IP has no software-visible registers.

## Verification

### Testbenches

| File | DUT | Description |
|------|-----|-------------|
| [sim/tb_clock_divider.vhd](sim/tb_clock_divider.vhd) | `clock_divider` (20 instances) | UVVM self-checking testbench (609 checks), 10 ns clock. One instance per `RATIO` in {1, 2, 3, 4, 5, 6, 7, 8, 24, 25} and per `ALGO` in {`"pulse"`, `"50%"`}. (1) `clk_div_o` low during reset and first rising edge at the expected `clk_i` edge after the release (`RATIO` for pulse, 1 for 50 %); (2) period (`RATIO*T`) and high time (`T` for pulse, `RATIO*T/2` for 50 %, `T/2` for `RATIO = 1`) measured on 3 periods; (3) `cke_i = 0` at 4 different phases: every output frozen during 30 cycles (`RATIO = 1` still follows `clk_i`), then period / high time measured again; (4) `cke_i` active one cycle out of 2: period `2*RATIO*T` (and high time `2*T` for pulse); (5) asynchronous reset while running clears the outputs |

### Targets

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | `clock_divider` | HDL fileset only (not a simulation) |
| `sim_basic` | `tb_clock_divider` | Simulation of all `RATIO` / `ALGO` cases (UVVM, self-checking, GHDL) |

### How to Run

The default tool is GHDL (`mk/defs.mk`: `TOOL ?= ghdl`, `TARGET ?= sim_basic`).

```bash
make help                 # variables, rules and target list (mk/targets.txt)
make sim_basic            # run one target (log in log/)
make nonreg_sim           # run every sim_* target
make clean                # remove build/
```

Equivalent FuseSoC command:

```bash
fusesoc --cores-root . run --build-root build --target sim_basic asylum:component:clock_divider:2.0.3
```

### Simulation Features

- `sim_basic` passes `--fst=dut.fst --ieee-asserts=disable` to the GHDL run.

## Synthesis

No dedicated synthesis target. The HDL of the `default` target contains no simulation-only construct (no `textio`, file access, `report` or `wait`) and is synthesizable. The clock buffer is taken from `asylum:target:techmap`: a pass-through (`hdl/generic/cbufg.vhd`) by default, or the NanoXplore NG-Medium cell when `TARGET_NANOXPLORE_NG_MEDIUM` is set. The divided output is a generated clock: declare it as such in the timing constraints of the design that instantiates it. For odd ratios with `"50%"` the output combines rising- and falling-edge registers.

## Design Notes

### Operation

- **`RATIO = 1`**: `clk_div_o <= clk_i`; `cke_i` and `arstn_i` have no effect and no `cbufg` is instantiated.
- **Reset**: the counter is loaded with `RATIO-1`, `clk_div_pos_r` and `clk_div_neg_r` are cleared (`clk_div_o = 0`).
- **`"pulse"`**: the counter runs from `RATIO-1` down to 0; `clk_div_pos_r` is set for one cycle after the counter reaches 0. Output frequency `f_clk / RATIO`, high time one `clk_i` period.
- **`"50%"`, even `RATIO`**: the counter period is `RATIO`; `clk_div_pos_r` is high while the counter is `>= RATIO/2`, i.e. `RATIO/2` cycles high and `RATIO/2` low (exact 50 %, rising-edge logic only). The first rising edge of `clk_div_o` follows the first `clk_i` rising edge after reset.
- **`"50%"`, odd `RATIO`**: the counter period is `RATIO`; `clk_div_pos_r` is high during `(RATIO-1)/2` cycles (counter `>= (RATIO+1)/2`), and ORing with its falling-edge copy `clk_div_neg_r` extends the high phase by half a cycle: `RATIO/2` cycles high and `RATIO/2` low (e.g. 12.5 / 12.5 cycles for `RATIO = 25`). The duty cycle is exactly 50 % when `clk_i` has a 50 % duty cycle; it follows the `clk_i` duty cycle error otherwise. A rising-edge-only implementation would give `(RATIO-1)/2` / `(RATIO+1)/2` cycles.
- **Clock enable**: when `cke_i = 0` the counter, `clk_div_pos_r` and `clk_div_neg_r` hold their value (`clk_div_o` frozen); the period is counted in enabled `clk_i` cycles.
- **Invalid `ALGO`**: an assertion (severity failure) reports any value other than `"pulse"` or `"50%"`; the `"pulse"` logic is generated in that case.

## Directory Structure

```
asylum-component-clock_divider/
├── clock_divider.core          # FuseSoC core (asylum:component:clock_divider)
├── Makefile                    # Common Asylum Makefile (FuseSoC wrapper)
├── mk/
│   ├── defs.mk                 # FILE_CORE, default TARGET and TOOL
│   └── targets.txt             # Target list (generated from the .core)
├── doc/
│   └── clock_divider.drawio    # Block diagram
├── hdl/
│   ├── clock_divider_pkg.vhd
│   └── clock_divider.vhd
├── sim/
│   └── tb_clock_divider.vhd    # UVVM self-checking testbench
└── .github/workflows/ci.yml    # CI (sim_basic)
```

## Dependencies

| Core | Used by (fileset) | Purpose |
|------|-------------------|---------|
| `asylum:utils:pkg` | `files_hdl` | Common packages (`math_pkg` is imported by `clock_divider`) |
| `asylum:target:techmap` | `files_hdl` | `techmap_pkg` and the `cbufg` clock buffer cell |
| `bitvis:verification:uvvm` | `files_sim` | UVVM utility library (testbench only) |
