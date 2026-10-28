-------------------------------------------------------------------------------
-- Title      : clock_divider_wrapper
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : clock_divider_wrapper.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Wrapper (lint_ghdl, lint_ghdl_synth_*) : clock_divider with the algorithm
-- selected by the boolean ALGO_50 (false : "pulse", true : "50%") : a
-- FuseSoC parameter value cannot contain '%'. RATIO is forwarded.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-24  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;

entity clock_divider_wrapper is
  generic (
    RATIO     : positive := 2;
    ALGO_50   : boolean  := false
  );
  port (
    clk_i     : in  std_logic;
    cke_i     : in  std_logic;
    arstn_i   : in  std_logic;
    clk_div_o : out std_logic
  );
end entity clock_divider_wrapper;

architecture rtl of clock_divider_wrapper is

  function algo_name (algo_50 : boolean) return string is
  begin
    if algo_50 then
      return "50%";
    else
      return "pulse";
    end if;
  end function algo_name;

begin

  ins_clock_divider : entity asylum.clock_divider
    generic map (
      RATIO     => RATIO,
      ALGO      => algo_name(ALGO_50)
    )
    port map (
      clk_i     => clk_i,
      cke_i     => cke_i,
      arstn_i   => arstn_i,
      clk_div_o => clk_div_o
    );

end architecture rtl;
