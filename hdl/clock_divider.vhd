-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2025-09-06
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
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
library work;
use     work.techmap_pkg.all;
use     work.math_pkg.all;

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
  -- Function "get_ratio_max"
  -- Arg     : N/A
  -- Generic : ALGO
  --           RATIO
  -- Return  : Return the counter overflow value
  -------------------------------------------------------------------------------
  function get_ratio_max
    return natural is
  begin  -- function get_ratio_max
    
    if ALGO = "pulse" then return RATIO;       end if;
    if ALGO = "50%"   then return 2*(RATIO/2); end if;

    return RATIO;
  end function get_ratio_max;

  constant RATIO_MAX            : natural := get_ratio_max;
  signal   clk_counter_r      : natural range 0 to RATIO_MAX-1;
  signal   clk_counter_r_next : natural range 0 to RATIO_MAX-1;
  signal   clk_div_pos_r_next : std_logic;
  signal   clk_div_pos_r      : std_logic;
  signal   clk_div_neg_r      : std_logic;
  signal   clk_div            : std_logic;

begin
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
    ---------------------------------------------------------------------------
    gen_algo_pulse: if ALGO = "pulse"
    generate
      clk_div_pos_r_next <= '1' when (clk_counter_r = 0) else
                            '0';

      clk_div            <= clk_div_pos_r;

    end generate gen_algo_pulse;
    
    ---------------------------------------------------------------------------
    -- Algo "50%" : Generate clock with closest of 50% duty cycle
    ---------------------------------------------------------------------------
    gen_algo_50percent: if ALGO = "50%"
    generate
      clk_div_pos_r_next <= '0' when (clk_counter_r < RATIO/2) else
                            '1';

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

