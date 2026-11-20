-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_bfm_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_bfm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_clock_divider scenarios : expected high time
--              and first edge, clock enable modes, waits with a timeout,
--              measure of the period and high time of clk_div_o, check that
--              clk_div_o follows clk_i (RATIO = 1).
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

package tb_clock_divider_bfm_pkg is

  constant C_TB_SCOPE    : string  := "TB_CLOCK_DIVIDER_BFM";
  constant C_CLK_PERIOD  : time    := 10 ns;
  constant C_SETTLE      : time    := 1 ns;   -- Sampling delay after a clk_i edge
  constant C_NB_PERIODS  : natural := 3;      -- Number of periods measured
  constant C_TIMEOUT     : time    := 200 * C_CLK_PERIOD;

  -- cke_i driven by the testbench (process p_cke)
  --  CKE_ON        : '1'
  --  CKE_OFF       : '0', from the next falling edge of clk_i
  --  CKE_HALF_FALL : '1' one cycle out of 2, changes on the falling edges
  --  CKE_HALF_RISE : '1' one cycle out of 2, changes C_SETTLE after the
  --                  rising edges
  type     cke_mode_t is (CKE_ON, CKE_OFF, CKE_HALF_FALL, CKE_HALF_RISE);

  -- ALGO of clock_divider from the boolean ALGO_50
  function algo_name
    (constant algo_50  : in    boolean
    ) return string;

  -- Expected high time of clk_div_o, cke_i = '1'
  function exp_high
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return time;

  -- Expected high time of clk_div_o, cke_i = '1' one cycle out of 2
  -- (RATIO > 1) : the half-cycle extension of an odd RATIO stays half a
  -- clk_i cycle
  function exp_high_cke_half
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return time;

  -- Expected rising edge of clk_i (counted from the reset release) of the
  -- first rising edge of clk_div_o (RATIO > 1)
  function exp_first_rise
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return natural;

  -- Wait until sig = val, error after C_TIMEOUT
  procedure wait_level
    (signal   sig      : in    std_logic
    ;constant val      : in    std_logic
    ;constant msg      : in    string
    );

  -- Wait n rising edges of clk
  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    );

  -- Period and high time of clk_div over C_NB_PERIODS periods
  procedure measure
    (signal   clk_div  : in    std_logic
    ;constant period   : in    time
    ;constant high     : in    time
    ;constant msg      : in    string
    );

  -- First high time and period of clk_div, called C_SETTLE after its first
  -- rising edge (a rising edge of clk_i)
  procedure measure_first
    (signal   clk_div  : in    std_logic
    ;constant period   : in    time
    ;constant high     : in    time
    ;constant msg      : in    string
    );

  -- Number of rising edges of clk, from now, up to the first one after
  -- which clk_div is '1' (0 if none in C_TIMEOUT)
  procedure count_first_rise
    (signal   clk      : in    std_logic
    ;signal   clk_div  : in    std_logic
    ;variable cnt      : out   natural
    );

  -- RATIO = 1 : clk_div equal to clk during n cycles from the next rising
  -- edge, sampled 4 times per cycle out of the clk_i edges (one check)
  procedure chk_follows
    (signal   clk      : in    std_logic
    ;signal   clk_div  : in    std_logic
    ;constant n        : in    natural
    ;constant msg      : in    string
    );

end package tb_clock_divider_bfm_pkg;

package body tb_clock_divider_bfm_pkg is

  function algo_name
    (constant algo_50  : in    boolean
    ) return string is
  begin
    if algo_50
    then
      return "50%";
    else
      return "pulse";
    end if;
  end function;

  function exp_high
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return time is
  begin
    if ratio = 1
    then
      return C_CLK_PERIOD/2;
    elsif not algo_50
    then
      return C_CLK_PERIOD;
    else
      return (ratio * C_CLK_PERIOD) / 2;
    end if;
  end function;

  function exp_high_cke_half
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return time is
  begin
    if not algo_50
    then
      return 2 * C_CLK_PERIOD;
    elsif ratio mod 2 = 0
    then
      return ratio * C_CLK_PERIOD;
    else
      return (ratio-1) * C_CLK_PERIOD + C_CLK_PERIOD/2;
    end if;
  end function;

  function exp_first_rise
    (constant ratio    : in    positive
    ;constant algo_50  : in    boolean
    ) return natural is
  begin
    if algo_50
    then
      return 1;
    else
      return ratio;
    end if;
  end function;

  procedure wait_level
    (signal   sig      : in    std_logic
    ;constant val      : in    std_logic
    ;constant msg      : in    string
    ) is
  begin
    if sig /= val
    then
      wait until sig = val for C_TIMEOUT;
      if sig /= val
      then
        alert(ERROR, msg & " : timeout, clk_div_o never " & std_logic'image(val), C_TB_SCOPE);
      end if;
    end if;
  end procedure;

  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    ) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

  procedure measure
    (signal   clk_div  : in    std_logic
    ;constant period   : in    time
    ;constant high     : in    time
    ;constant msg      : in    string
    ) is
    variable t_rise : time;
    variable t_fall : time;
  begin
    wait_level(clk_div, '0', msg);
    wait_level(clk_div, '1', msg);
    for n in 1 to C_NB_PERIODS loop
      t_rise := now;
      wait_level(clk_div, '0', msg);
      t_fall := now;
      wait_level(clk_div, '1', msg);
      check_value(now - t_rise   , period, ERROR, msg & " : period"   , C_TB_SCOPE);
      check_value(t_fall - t_rise, high  , ERROR, msg & " : high time", C_TB_SCOPE);
    end loop;
  end procedure;

  procedure measure_first
    (signal   clk_div  : in    std_logic
    ;constant period   : in    time
    ;constant high     : in    time
    ;constant msg      : in    string
    ) is
    variable t_rise : time;
  begin
    t_rise := now - C_SETTLE;
    wait_level(clk_div, '0', msg);
    check_value(now - t_rise, high  , ERROR, msg & " : high time", C_TB_SCOPE);
    wait_level(clk_div, '1', msg);
    check_value(now - t_rise, period, ERROR, msg & " : period"   , C_TB_SCOPE);
  end procedure;

  procedure count_first_rise
    (signal   clk      : in    std_logic
    ;signal   clk_div  : in    std_logic
    ;variable cnt      : out   natural
    ) is
  begin
    cnt := 0;
    for c in 1 to C_TIMEOUT / C_CLK_PERIOD loop
      wait until rising_edge(clk);
      wait for C_SETTLE;
      if clk_div = '1'
      then
        cnt := c;
        return;
      end if;
    end loop;
  end procedure;

  procedure chk_follows
    (signal   clk      : in    std_logic
    ;signal   clk_div  : in    std_logic
    ;constant n        : in    natural
    ;constant msg      : in    string
    ) is
    variable v_ok : boolean := true;
  begin
    -- Samples C_SETTLE + k*C_CLK_PERIOD/4 after a rising edge : never on an
    -- edge of clk_i
    wait until rising_edge(clk);
    wait for C_SETTLE;
    for i in 1 to 4*n loop
      if clk_div /= clk
      then
        v_ok := false;
      end if;
      wait for C_CLK_PERIOD/4;
    end loop;
    check_value(v_ok, ERROR, msg & " : clk_div_o = clk_i during " & integer'image(n) & " cycles", C_TB_SCOPE);
  end procedure;

end package body tb_clock_divider_bfm_pkg;
