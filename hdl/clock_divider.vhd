-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2026-10-05
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Clock divider with static RATIO
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2013-12-26  1.0      mrosière Created
-- 2014-07-12  1.1      mrosière Change Port name
-- 2017-04-27  1.2      mrosière Add 2 algo
-- 2022-02-10  1.3      mrosiere Delete unused algo
-- 2022-02-27  2.0      mrosiere Create real 50%
-- 2025-08-13  2.1      mrosiere Add clock buffer
-- 2026-10-05  2.2      mrosiere 50% : period is RATIO for odd RATIO (was RATIO-1)
--                               and high time is RATIO/2 cycles exactly,
--                               assert on invalid ALGO (fallback to pulse)
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
library asylum;
use     asylum.techmap_pkg.all;
use     asylum.math_pkg.all;

-------------------------------------------------------------------------------
entity clock_divider is
-------------------------------------------------------------------------------
  generic(RATIO        : positive := 2;       -- Static Ratio
          ALGO         : string   := "pulse"  -- pulse
                                              -- 50%
          );
  port   (clk_i        : in  std_logic;       -- Clock Input
          cke_i        : in  std_logic;       -- Clock Enable
          arstn_i      : in  std_logic;       -- Reset Asynchronous active low
          clk_div_o    : out std_logic        -- Clock Input divided by RATIO
          );
end clock_divider;

architecture rtl of clock_divider is

  -----------------------------------------------------------------------------
  -- The counter period is always RATIO cycles
  --  * "pulse" : clk_div_pos_r is 1 during 1 cycle (counter = 0)
  --  * "50%"   : clk_div_pos_r is 1 during RATIO/2 cycles (integer division)
  --              (counter >= RATIO_HIGH)
  --              For odd RATIO, clk_div_neg_r (clk_div_pos_r sampled on the
  --              falling edge) is ORed to extend the high phase by half a
  --              cycle : RATIO/2 cycles high, RATIO/2 cycles low exactly
  --              (assuming a 50% duty cycle on clk_i)
  -----------------------------------------------------------------------------
  constant RATIO_MAX            : natural := RATIO;
  constant RATIO_HIGH           : natural := RATIO - RATIO/2;
  constant ALGO_50              : boolean := (ALGO = "50%");

  signal   clk_counter_r      : natural range 0 to RATIO_MAX-1;
  signal   clk_counter_r_next : natural range 0 to RATIO_MAX-1;
  signal   clk_div_pos_r_next : std_logic;
  signal   clk_div_pos_r      : std_logic;
  signal   clk_div_neg_r      : std_logic;
  signal   clk_div            : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Check generic
  -----------------------------------------------------------------------------
  assert (ALGO = "pulse") or (ALGO = "50%")
    report "clock_divider : invalid ALGO value """ & ALGO & """ (must be ""pulse"" or ""50%""), ""pulse"" is used"
    severity failure;

  -----------------------------------------------------------------------------
  -- Ratio = 1, then clock is unchanged
  -----------------------------------------------------------------------------
  gen_ratio_eq_1: if RATIO=1
  generate
    clk_div_o <= clk_i;
  end generate gen_ratio_eq_1;

  -----------------------------------------------------------------------------
  -- Ratio > 1
  -----------------------------------------------------------------------------
  gen_ratio_gt_1: if RATIO > 1
  generate

    ---------------------------------------------------------------------------
    -- Algo "Pulse" : Generate a pulse of 1 cycle
    -- Is 1 when counter is 0, else is 0
    -- (also used for an invalid ALGO value, see assertion)
    ---------------------------------------------------------------------------
    gen_algo_pulse: if not ALGO_50
    generate
      clk_div_pos_r_next <= '1' when (clk_counter_r = 0) else
                            '0';

      clk_div            <= clk_div_pos_r;

    end generate gen_algo_pulse;
    
    ---------------------------------------------------------------------------
    -- Algo "50%" : Generate clock with closest of 50% duty cycle
    ---------------------------------------------------------------------------
    gen_algo_50percent: if ALGO_50
    generate
      clk_div_pos_r_next <= '1' when (clk_counter_r >= RATIO_HIGH) else
                            '0';

      -- If Ratio is even, just take the divider on posedge of clock
      gen_ratio_even : if RATIO mod 2 = 0
      generate
        clk_div            <= clk_div_pos_r;
      end generate gen_ratio_even; 

      -- If Ratio is odd, combine the divider on posedge of clock and the
      -- sampling on negedge
      gen_ratio_odd  : if RATIO mod 2 = 1
      generate
        clk_div            <= clk_div_pos_r or clk_div_neg_r;
      end generate gen_ratio_odd; 
    end generate gen_algo_50percent;

    ---------------------------------------------------------------------------
    -- Registers
    ---------------------------------------------------------------------------

    -- decrease clock diviser
    clk_counter_r_next <= RATIO_MAX-1 when (clk_counter_r = 0) else
                          clk_counter_r-1;
    
    -- Process on posedge of clock : counter and result of divider
    process(arstn_i,clk_i)
    begin 
      if arstn_i='0'
      then
        clk_counter_r <= RATIO_MAX-1;
        clk_div_pos_r <= '0';
      elsif rising_edge(clk_i)
      then
        if (cke_i = '1')
        then
          clk_div_pos_r     <= clk_div_pos_r_next;
          clk_counter_r     <= clk_counter_r_next;
        end if;
      end if;
    end process;

    -- Process on negedge of clock : sample posedge divider 
    process(arstn_i,clk_i)
    begin 
      if arstn_i='0'
      then
        clk_div_neg_r     <= '0';
      elsif falling_edge(clk_i)
      then
        if (cke_i = '1')
        then
          clk_div_neg_r     <= clk_div_pos_r;
        end if;
      end if;
    end process;

    ---------------------------------------------------------------------------
    -- Clock Buffer
    ---------------------------------------------------------------------------

  ins_cbufg : cbufg
  port map (
    d_i   => clk_div,
    d_o   => clk_div_o
    );

  end generate gen_ratio_gt_1;
end rtl;

