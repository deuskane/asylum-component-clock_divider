-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_cke_stop_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_cke_stop_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario cke_stop of tb_clock_divider, from reset :
--              cke_i = '0' 0 to 3 cycles after a rising edge of clk_div_o
--              (4 phases) : clk_div_o frozen during 30 cycles from the
--              falling edge where cke_i falls, then period and high time
--              with cke_i = '1' again. RATIO = 1 : clk_div_o follows clk_i
--              with cke_i = '0'.
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

package tb_clock_divider_cke_stop_pkg is

  -- cke_i = '0' 0 to 3 cycles after a rising edge of clk_div_o
  -- (4 phases) : clk_div_o frozen during 30 cycles from the
  -- falling edge where cke_i falls, then period and high time
  -- with cke_i = '1' again. RATIO = 1 : clk_div_o follows clk_i
  -- with cke_i = '0'.
  procedure run
    (constant ratio    : in    positive   -- RATIO
    ;constant algo_50  : in    boolean    -- ALGO = "50%"
    ;signal   clk      : in    std_logic  -- clk_i
    ;signal   cke_mode : out   cke_mode_t -- cke_i driver
    ;signal   clk_div  : in    std_logic  -- clk_div_o
    );

end package tb_clock_divider_cke_stop_pkg;

package body tb_clock_divider_cke_stop_pkg is

  procedure run
    (constant ratio    : in    positive   -- RATIO
    ;constant algo_50  : in    boolean    -- ALGO = "50%"
    ;signal   clk      : in    std_logic  -- clk_i
    ;signal   cke_mode : out   cke_mode_t -- cke_i driver
    ;signal   clk_div  : in    std_logic  -- clk_div_o
    ) is
  begin
    if ratio = 1
    then
      cke_mode <= CKE_OFF;
      wait until falling_edge(clk);     -- cke_i <= '0'
      chk_follows(clk, clk_div, 30, "RATIO = 1, cke_i = '0' : clk_div_o not frozen");
      cke_mode <= CKE_ON;
      return;
    end if;

    for k in 0 to 3 loop
      -- Stop k cycles after a rising edge of clk_div_o (k = 0 : the next
      -- enabled edge would clear clk_div_o in pulse mode)
      wait for C_SETTLE;
      wait_level(clk_div, '0', "cke_i = '0'");
      wait_level(clk_div, '1', "cke_i = '0'");
      cycles(k, clk);
      cke_mode <= CKE_OFF;
      wait until falling_edge(clk);     -- cke_i <= '0'
      wait for C_SETTLE;                -- from there, nothing may change
      wait for 30 * C_CLK_PERIOD;
      check_stable(clk_div, 30 * C_CLK_PERIOD, ERROR, "clk_div_o frozen during 30 cycles with cke_i = '0' (phase " & integer'image(k) & ")", C_TB_SCOPE);
      cke_mode <= CKE_ON;
      wait until falling_edge(clk);     -- cke_i <= '1'
    end loop;
    measure(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "after cke_i = '0'");
  end procedure;

end package body tb_clock_divider_cke_stop_pkg;
