-------------------------------------------------------------------------------
-- Title      : tb_clock_divider
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_clock_divider.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2017-04-27
-- Last update: 2022-02-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2022-02-09  1.1      mrosiere Update tb from ALGO parameter
-- 2017-04-27  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tb_clock_divider is
  
end entity tb_clock_divider;

architecture tb of tb_clock_divider is

  -------------------------------------------------------
  -- DUT signals
  -------------------------------------------------------
  signal clk_i             : std_logic := '0';
  signal cke_i             : std_logic;
  signal arstn_i           : std_logic;
  signal clk_div1_o        : std_logic;
  signal clk_div2_o        : std_logic;
  signal clk_div3_o        : std_logic;
  signal clk_div4_o        : std_logic;
  signal clk_div5_o        : std_logic;
  signal clk_div6_o        : std_logic;
  signal clk_div7_o        : std_logic;
  signal clk_div8_o        : std_logic;
  signal clk_div25_algo0_o : std_logic;
  signal clk_div25_algo1_o : std_logic;

  -------------------------------------------------------
  -- run
  -------------------------------------------------------
  procedure xrun
    (constant n     : in positive;           -- nb cycle
     signal   clk_i : in std_logic
     ) is
    
  begin
    for i in 0 to n-1
    loop
      wait until rising_edge(clk_i);        
    end loop;  -- i
  end xrun;

  procedure run
    (constant n     : in positive           -- nb cycle
     ) is
    
  begin
    xrun(n,clk_i);
  end run;

  -----------------------------------------------------
  -- Test signals
  -----------------------------------------------------
  signal test_done : std_logic := '0';
  signal test_ok   : std_logic := '0';
  
begin  -- architecture tb

  dut_div1 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 1
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div1_o    
     );
    
  dut_div2 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 2
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div2_o    
     );
    
  dut_div3 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 3
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div3_o    
     );
    
  dut_div4 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 4
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div4_o    
     );
    
  dut_div5 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 5
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div5_o    
     );
    
  dut_div6 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 6
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div6_o    
     );
    
  dut_div7 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 7
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div7_o    
     );
    
  dut_div8 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 8
    ,ALGO         => "pulse"
     )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div8_o    
     );

  dut_div25_algo0 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 25
    ,ALGO         => "pulse"
    )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div25_algo0_o    
     );

    dut_div25_algo1 : entity work.clock_divider(rtl)
    generic map
    (RATIO        => 25
    ,ALGO         => "50%"
    )
    port map
    (clk_i        => clk_i        
    ,cke_i        => cke_i        
    ,arstn_i      => arstn_i      
    ,clk_div_o    => clk_div25_algo1_o    
     );

  clk_i <= not test_done and not clk_i after 5 ns;
  
  gen_pattern: process is
  begin  -- process gen_pattern
    report "[TESTBENCH] Test Begin";

    run(1);

    -- Reset
    report "[TESTBENCH] Reset";
    arstn_i <= '0';
    cke_i   <= '1';
    run(10);
    cke_i   <= '1';
    arstn_i <= '1';
    run(1000);

    report "[TESTBENCH] Test End";

    test_ok   <= '1';

    run(1);
    test_done <= '1';
    run(1);
  end process gen_pattern;

  
  gen_test_done: process (test_done) is
  begin  -- process gen_test_done
    if test_done'event and test_done = '1' then  -- rising clock edge
      if test_ok = '1' then
        report "[TESTBENCH] Test OK";
      else
        report "[TESTBENCH] Test KO" severity failure;
      end if;
      
    end if;
  end process gen_test_done;
  
end architecture tb;
