-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_tests_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_tests_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_clock_divider : names (valid items of
--              TESTS_LIST) and dispatch (run_test) to the package of each
--              scenario (tb_clock_divider_<name>_pkg)
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

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_clock_divider_bfm_pkg.all;

package tb_clock_divider_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "reset,period,cke_stop,cke_half,reset_running,bypass";

  -- Run the scenario name
  procedure run_test
    (constant name        : in    string     -- Scenario
    ;constant ratio       : in    positive   -- RATIO
    ;constant algo_50     : in    boolean    -- ALGO = "50%"
    ;signal   clk         : in    std_logic  -- clk_i
    ;signal   arst_b      : out   std_logic  -- arstn_i
    ;signal   cke_mode    : out   cke_mode_t -- cke_i driver
    ;signal   clk_div     : in    std_logic  -- clk_div_o
    ;signal   clk_div_byp : in    std_logic  -- clk_div_o, BYPASS_CBUFG = true
    );

end package tb_clock_divider_tests_pkg;

package body tb_clock_divider_tests_pkg is

  procedure run_test
    (constant name        : in    string     -- Scenario
    ;constant ratio       : in    positive   -- RATIO
    ;constant algo_50     : in    boolean    -- ALGO = "50%"
    ;signal   clk         : in    std_logic  -- clk_i
    ;signal   arst_b      : out   std_logic  -- arstn_i
    ;signal   cke_mode    : out   cke_mode_t -- cke_i driver
    ;signal   clk_div     : in    std_logic  -- clk_div_o
    ;signal   clk_div_byp : in    std_logic  -- clk_div_o, BYPASS_CBUFG = true
    ) is
  begin
    if    string_eq(name, "reset")
    then
      work.tb_clock_divider_reset_pkg.run(ratio, algo_50, clk, arst_b, clk_div);
    elsif string_eq(name, "period")
    then
      work.tb_clock_divider_period_pkg.run(ratio, algo_50, clk_div);
    elsif string_eq(name, "cke_stop")
    then
      work.tb_clock_divider_cke_stop_pkg.run(ratio, algo_50, clk, cke_mode, clk_div);
    elsif string_eq(name, "cke_half")
    then
      work.tb_clock_divider_cke_half_pkg.run(ratio, algo_50, clk, cke_mode, clk_div);
    elsif string_eq(name, "reset_running")
    then
      work.tb_clock_divider_reset_running_pkg.run(ratio, algo_50, clk, arst_b, clk_div);
    elsif string_eq(name, "bypass")
    then
      work.tb_clock_divider_bypass_pkg.run(ratio, algo_50, clk_div_byp);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_clock_divider_tests_pkg;
