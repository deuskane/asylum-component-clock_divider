-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_reset_running_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_reset_running_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset_running of tb_clock_divider, from reset :
--              reset asserted between two clock edges while clk_div_o is
--              high (and both registers for an odd 50% RATIO) : clk_div_o
--              cleared without clock edge ; after the release, first
--              rising edge at the expected edge of clk_i, first high time
--              and period, then period and high time. RATIO = 1 :
--              clk_div_o follows clk_i during the reset.
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

package tb_clock_divider_reset_running_pkg is

  -- reset asserted between two clock edges while clk_div_o is
  -- high (and both registers for an odd 50% RATIO) : clk_div_o
  -- cleared without clock edge ; after the release, first
  -- rising edge at the expected edge of clk_i, first high time
  -- and period, then period and high time. RATIO = 1 :
  -- clk_div_o follows clk_i during the reset.
  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk     : in    std_logic -- clk_i
    ;signal   arst_b  : out   std_logic -- arstn_i
    ;signal   clk_div : in    std_logic -- clk_div_o
    );

end package tb_clock_divider_reset_running_pkg;

package body tb_clock_divider_reset_running_pkg is

  procedure run
    (constant ratio   : in    positive  -- RATIO
    ;constant algo_50 : in    boolean   -- ALGO = "50%"
    ;signal   clk     : in    std_logic -- clk_i
    ;signal   arst_b  : out   std_logic -- arstn_i
    ;signal   clk_div : in    std_logic -- clk_div_o
    ) is
    variable v_cnt : natural;
  begin
    cycles(7, clk);
    if ratio = 1
    then
      wait for C_CLK_PERIOD/4;
      arst_b <= '0';
      chk_follows(clk, clk_div, 10, "RATIO = 1, reset while running : clk_div_o not held low");
      wait until falling_edge(clk);
      arst_b <= '1';
      return;
    end if;

    -- T/4 after the falling edge of clk_i that follows a rising edge of
    -- clk_div_o : still high, and for an odd 50% RATIO both the rising and
    -- the falling edge registers are high
    wait for C_SETTLE;
    wait_level(clk_div, '0', "reset while running");
    wait_level(clk_div, '1', "reset while running");
    wait until falling_edge(clk);
    wait for C_CLK_PERIOD/4;
    check_value(clk_div, '1', ERROR, "clk_div_o high before the reset", C_TB_SCOPE);
    arst_b <= '0';
    wait for C_SETTLE;
    check_value(clk_div, '0', ERROR, "clk_div_o cleared by the reset without clock edge", C_TB_SCOPE);
    cycles(2, clk);
    wait until falling_edge(clk);
    arst_b <= '1';
    count_first_rise(clk, clk_div, v_cnt);
    check_value(v_cnt, exp_first_rise(ratio, algo_50), ERROR, "first rising edge of clk_div_o after the reset release (rising edges of clk_i)", C_TB_SCOPE);
    measure_first(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "first period after the reset");
    measure(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "after the reset");
  end procedure;

end package body tb_clock_divider_reset_running_pkg;
