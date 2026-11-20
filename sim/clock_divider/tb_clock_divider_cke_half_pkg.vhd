-------------------------------------------------------------------------------
-- Title      : tb_clock_divider_cke_half_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider_cke_half_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario cke_half of tb_clock_divider, from reset :
--              cke_i = '1' one cycle out of 2, changing on the falling
--              edges then after the rising edges of clk_i : period
--              2*RATIO*T and high time (2*T for pulse, RATIO*T for 50%
--              even RATIO, (RATIO-1)*T + T/2 for 50% odd RATIO), then
--              period and high time with cke_i = '1' again.
--              RATIO = 1 : clk_div_o follows clk_i.
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

package tb_clock_divider_cke_half_pkg is

  -- cke_i = '1' one cycle out of 2, changing on the falling
  -- edges then after the rising edges of clk_i : period
  -- 2*RATIO*T and high time (2*T for pulse, RATIO*T for 50%
  -- even RATIO, (RATIO-1)*T + T/2 for 50% odd RATIO), then
  -- period and high time with cke_i = '1' again.
  -- RATIO = 1 : clk_div_o follows clk_i.
  procedure run
    (constant ratio    : in    positive   -- RATIO
    ;constant algo_50  : in    boolean    -- ALGO = "50%"
    ;signal   clk      : in    std_logic  -- clk_i
    ;signal   cke_mode : out   cke_mode_t -- cke_i driver
    ;signal   clk_div  : in    std_logic  -- clk_div_o
    );

end package tb_clock_divider_cke_half_pkg;

package body tb_clock_divider_cke_half_pkg is

  procedure run
    (constant ratio    : in    positive   -- RATIO
    ;constant algo_50  : in    boolean    -- ALGO = "50%"
    ;signal   clk      : in    std_logic  -- clk_i
    ;signal   cke_mode : out   cke_mode_t -- cke_i driver
    ;signal   clk_div  : in    std_logic  -- clk_div_o
    ) is
  begin
    for m in CKE_HALF_FALL to CKE_HALF_RISE loop
      cke_mode <= m;
      if ratio = 1
      then
        chk_follows(clk, clk_div, 30, "RATIO = 1, " & cke_mode_t'image(m) & " : clk_div_o not divided");
      else
        cycles(4, clk);
        measure(clk_div, 2 * ratio * C_CLK_PERIOD, exp_high_cke_half(ratio, algo_50), cke_mode_t'image(m));
      end if;
      cke_mode <= CKE_ON;
      for c in 1 to 4 loop
        wait until falling_edge(clk);
      end loop;
    end loop;
    measure(clk_div, ratio * C_CLK_PERIOD, exp_high(ratio, algo_50), "after cke_i toggling");
  end procedure;

end package body tb_clock_divider_cke_half_pkg;
