-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_bypass_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_bypass_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario bypass of tb_clock_divider, from reset :
--              period and high time of the instance with BYPASS_CBUFG =
--              true (cke_i = '1'). In every scenario, a monitor of the
--              testbench compares its clk_div_o with the one of the DUT.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_clock_divider 2.1)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_clock_divider_bfm_pkg.all;

package tb_clock_divider_bypass_pkg is

  -- period and high time of the instance with BYPASS_CBUFG =
  -- true (cke_i = '1'). In every scenario, a monitor of the
  -- testbench compares its clk_div_o with the one of the DUT.
  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk_div : in    std_logic -- clk_div_o of the instance with BYPASS_CBUFG = true
    );

end package tb_clock_divider_bypass_pkg;

package body tb_clock_divider_bypass_pkg is

  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk_div : in    std_logic -- clk_div_o of the instance with BYPASS_CBUFG = true
    ) is
  begin
    measure(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "BYPASS_CBUFG = true");
  end procedure;

end package body tb_clock_divider_bypass_pkg;
