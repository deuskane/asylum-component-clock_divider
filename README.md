# Asylum Component - Clock Divider

A flexible and configurable clock divider component with multiple division algorithms for FPGA designs.

## Table of Contents

- [Asylum Component - Clock Divider](#asylum-component---clock-divider)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [HDL Modules](#hdl-modules)
    - [clock\_divider](#clock_divider)
      - [Generics](#generics)
      - [Ports](#ports)
      - [Operation](#operation)
  - [Verification](#verification)
    - [Testbench](#testbench)
    - [Simulation Targets](#simulation-targets)
  - [FuseSoC Integration](#fusesoc-integration)

---

## Introduction

The **Clock Divider** component is a configurable VHDL module designed to divide an input clock signal by a fixed ratio. It supports multiple division algorithms to meet different timing requirements:

- **Pulse mode** (`"pulse"`): Generates a single-cycle pulse at every RATIO clock cycles
- **50% Duty Cycle mode** (`"50%"`): Generates a clock signal with the closest possible 50% duty cycle

The component is parameterizable, allowing the division ratio and algorithm to be specified at instantiation time. It includes clock enable (`cke_i`) and asynchronous reset (`arstn_i`) inputs for flexible control.

**Key Features:**
- Static division ratio configuration (1 to N)
- Two algorithm modes: pulse and 50% duty cycle
- Clock enable support for conditional operation
- Asynchronous active-low reset
- Integrated clock buffer for signal distribution

---

## HDL Modules

### clock_divider

**File:** `hdl/clock_divider.vhd`

**Description:**
The main clock divider module that performs clock division based on a static configuration ratio and algorithm selection. The module implements a counter-based approach to divide the input clock.

#### Generics

| Generic | Type | Default | Description |
|---------|------|---------|-------------|
| `RATIO` | positive | 2 | Static clock division ratio. When RATIO=1, the output clock equals the input clock without division. |
| `ALGO` | string | `"pulse"` | Clock division algorithm. Supported values: `"pulse"` or `"50%"` |

#### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | Input clock signal |
| `cke_i` | in | std_logic | Clock enable (active high). When low, the divider does not advance. |
| `arstn_i` | in | std_logic | Asynchronous reset (active low). Resets the divider counter to its initial state. |
| `clk_div_o` | out | std_logic | Divided output clock signal |

#### Operation

**Ratio = 1:**
When RATIO is 1, the output clock is directly connected to the input clock (no division).

**Pulse Mode (ALGO = "pulse"):**
- Uses a counter that counts from RATIO down to 1
- Generates a one-cycle pulse (high) when the counter reaches 0
- The counter resets to RATIO-1 and begins counting down again
- Output frequency = Input frequency / RATIO
- Output duty cycle depends on RATIO value

**50% Duty Cycle Mode (ALGO = "50%"):**
- Implements a counter-based divider that attempts to maintain a 50% duty cycle
- For even ratios: Generates a clock that is high for RATIO/2 cycles and low for RATIO/2 cycles
- For odd ratios: Combines positive and negative edge sampling to achieve the closest 50% duty cycle
- More suitable for applications requiring balanced clock distribution

**Clock Enable Behavior:**
When `cke_i` is asserted (high), the counter advances and the divider operates normally. When `cke_i` is deasserted (low), the counter and output remain frozen in their current state, effectively pausing the divider.

**Reset Behavior:**
The asynchronous active-low reset (`arstn_i`) initializes the counter to RATIO_MAX-1 and clears the output flip-flops. This ensures the divider starts from a known state.

**Clock Buffer:**
An integrated clock buffer (CBUFG) is instantiated to ensure proper clock distribution and drive strength for the divided clock output.

---

## Verification

### Testbench

**File:** `sim/tb_clock_divider.vhd`

The testbench (`tb_clock_divider`) provides comprehensive verification of the clock divider module across various configurations:

**Test Coverage:**
- Division ratios from 1 to 8 (pulse mode)
- Division ratio 25 with both pulse and 50% algorithms
- Division ratio 24 with 50% algorithm
- Clock enable control
- Asynchronous reset behavior

**Test Stimulus:**
1. Power-up initialization
2. Asynchronous reset assertion and deassertion
3. Extended clock cycles (1000 cycles) to verify stable operation across multiple division periods
4. Clock enable signal management

**Simulation Parameters:**
- Clock period: 10 ns (5 ns high, 5 ns low)
- Test duration: 1000+ clock cycles after reset
- Test framework: GHDL VHDL testbench

### Simulation Targets

The project supports simulation via FuseSoC with the following target:

| Target | Description | Top-level Entity |
|--------|-------------|------------------|
| `sim_basic` | Simulation of all test cases | `tb_clock_divider` |

---

## FuseSoC Integration

**Core File:** `clock_divider.core`

The component is integrated with FuseSoC using the CAPI 2.0 core description format.

**Core Identity:**
- Name: `asylum:component:clock_divider:2.0.2`
- Vendor: `asylum`
- Library: `component`
- Name: `clock_divider`
- Version: `2.0.2`

**File Sets:**

1. **files_hdl** - Hardware description files
   - `hdl/clock_divider_pkg.vhd` (Package with component declaration)
   - `hdl/clock_divider.vhd` (Main module implementation)
   - Dependencies: `asylum:utils:pkg`, `asylum:target:techmap`

2. **files_sim** - Simulation files
   - `sim/tb_clock_divider.vhd` (Testbench)

**Build Targets:**

- **default**: Synthesis target (default tool: GHDL)
  - Files: HDL only
  - Top-level: `clock_divider`

- **sim_basic**: Simulation target (default tool: GHDL)
  - Files: HDL + Testbench
  - Top-level: `tb_clock_divider`
  - Generates VCD waveform file: `dut.vcd`

**Parameterization:**

Parameters can be configured at instantiation:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RATIO` | int | 2 | Fixed clock division ratio |
| `ALGO` | str | `"pulse"` | Division algorithm: `"pulse"` or `"50%"` |

**Example Usage:**

```bash
# Run simulation with default parameters (RATIO=2, ALGO="pulse")
fusesoc run --build-root ./build asylum:component:clock_divider:2.0.2 sim_basic
```
