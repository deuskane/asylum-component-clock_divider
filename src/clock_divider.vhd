-------------------------------------------------------------------------------
-- Title      : Clock Divider
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : clock_divider.vhd
-- Author     : Mathieu Rosière
-- Company    : 
-- Created    : 2013-12-26
-- Last update: 2022-03-20
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Clock divider with static RATIO
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2022-02-27  2.0      mrosiere Create real 50%
-- 2022-02-10  1.3      mrosiere Delete unused algo
-- 2017-04-27  1.2      mrosière Add 2 algo
-- 2014-07-12  1.1      mrosière Change Port name
-- 2013-12-26  1.0      mrosière Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.math_pkg.all;

entity clock_divider is
    generic(RATIO        : positive := 2;
            ALGO         : string   := "pulse"    -- pulse
                                                  -- 50%
            );
    port   (clk_i        : in  std_logic;
            cke_i        : in  std_logic;
            arstn_i      : in  std_logic;
            clk_div_o    : out std_logic);
end clock_divider;

architecture rtl of clock_divider is
  function get_ratio_max
    return natural is
  begin  -- function get_ratio_max
    
    if ALGO = "pulse" then return RATIO;       end if;
    if ALGO = "50%"   then return 2*(RATIO/2); end if;

    return RATIO;
  end function get_ratio_max;
  
  constant RATIO_MAX            : natural := get_ratio_max;
  signal   clock_counter_r      : natural range 0 to RATIO_MAX-1;
  signal   clock_div_pos_r_next : std_logic;
  signal   clock_div_pos_r      : std_logic;
  signal   clock_div_neg_r      : std_logic;

begin
  -- Ratio = 1, then clock is unchanged
  gen_ratio_eq_1: if RATIO=1
  generate
    clk_div_o <= clk_i;
  end generate gen_ratio_eq_1;

  gen_ratio_gt_1: if RATIO > 1
  generate

    -- Generate a pulse of 1 cycle
    gen_algo_pulse: if ALGO = "pulse"
    generate
      clock_div_pos_r_next <= '1' when (clock_counter_r = 0) else
                              '0';

      clk_div_o            <= clock_div_pos_r;

    end generate gen_algo_pulse;
    
    -- Generate clock with closest of 50% duty cycle
    gen_algo_50percent: if ALGO = "50%"
    generate
      clock_div_pos_r_next <= '0' when (clock_counter_r < RATIO/2) else
                              '1';


      gen_ratio_even : if RATIO mod 2 = 0
      generate
        clk_div_o            <= clock_div_pos_r;
      end generate gen_ratio_even; 

      gen_ratio_odd : if RATIO mod 2 = 1
      generate
        clk_div_o            <= clock_div_pos_r or clock_div_neg_r;
      end generate gen_ratio_odd; 
    end generate gen_algo_50percent;
    
    process(arstn_i,clk_i)
    begin 
      if arstn_i='0'
      then
        clock_counter_r <= RATIO_MAX-1;
        clock_div_pos_r     <= '0';
      elsif rising_edge(clk_i)
      then
        if (cke_i = '1')
        then
          clock_div_pos_r     <= clock_div_pos_r_next;

          -- decrease clock diviser
          if (clock_counter_r = 0)
          then
            clock_counter_r <= RATIO_MAX-1;
          else
            clock_counter_r <= clock_counter_r-1;
          end if;
        end if;
      end if;
    end process;

    process(arstn_i,clk_i)
    begin 
      if arstn_i='0'
      then
        clock_div_neg_r     <= '0';
      elsif falling_edge(clk_i)
      then
        if (cke_i = '1')
        then
          clock_div_neg_r     <= clock_div_pos_r;
        end if;
      end if;
    end process;

    
  end generate gen_ratio_gt_1;
end rtl;

