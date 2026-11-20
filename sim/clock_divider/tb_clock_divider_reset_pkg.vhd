-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_reset_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_reset_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset of tb_clock_divider, from reset :
--              reset held 10 cycles : clk_div_o low and stable ; reset
--              released on a falling edge : first rising edge of clk_div_o
--              at the expected rising edge of clk_i (RATIO for pulse, 1 for
--              50%), first high time and period. RATIO = 1 : clk_div_o
--              follows clk_i during the reset.
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

package tb_clock_divider_reset_pkg is

  -- reset held 10 cycles : clk_div_o low and stable ; reset
  -- released on a falling edge : first rising edge of clk_div_o
  -- at the expected rising edge of clk_i (RATIO for pulse, 1 for
  -- 50%), first high time and period. RATIO = 1 : clk_div_o
  -- follows clk_i during the reset.
  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk     : in    std_logic -- clk_i
    ;signal   arst_b  : out   std_logic -- arstn_i
    ;signal   clk_div : in    std_logic -- clk_div_o
    );

end package tb_clock_divider_reset_pkg;

package body tb_clock_divider_reset_pkg is

  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk     : in    std_logic -- clk_i
    ;signal   arst_b  : out   std_logic -- arstn_i
    ;signal   clk_div : in    std_logic -- clk_div_o
    ) is
    variable v_cnt : natural;
  begin
    -- Same delta as the release of the reset pulse of the sequencer : the
    -- reset stays asserted
    arst_b <= '0';
    if ratio = 1
    then
      chk_follows(clk, clk_div, 10, "RATIO = 1, arstn_i = '0' : clk_div_o not held low");
    else
      wait for C_SETTLE;
      wait for 10 * C_CLK_PERIOD;
      check_stable(clk_div, 10 * C_CLK_PERIOD, ERROR, "clk_div_o stable during 10 cycles of reset", C_TB_SCOPE);
      check_value (clk_div, '0'              , ERROR, "clk_div_o low during the reset"            , C_TB_SCOPE);
    end if;

    -- Release between 2 rising edges, count the rising edges of clk_i up
    -- to the first rising edge of clk_div_o
    wait until falling_edge(clk);
    arst_b <= '1';
    if ratio > 1
    then
      count_first_rise(clk, clk_div, v_cnt);
      check_value(v_cnt, exp_first_rise(ratio, algo_50), ERROR, "first rising edge of clk_div_o after the reset release (rising edges of clk_i)", C_TB_SCOPE);
      measure_first(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "first period after the reset");
    end if;
  end procedure;

end package body tb_clock_divider_reset_pkg;
