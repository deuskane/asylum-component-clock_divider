-------------------------------------------------------------------------------
-- Title      : tb_clock_divider
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of clock_divider
--              One instance per (RATIO, ALGO) with RATIO in C_RATIOS and
--              ALGO in ("pulse", "50%"). For each instance :
--              * period and high time of clk_div_o
--                - pulse : period RATIO*T, high time T
--                - 50%   : period RATIO*T, high time RATIO*T/2
--                - RATIO = 1 : clk_div_o = clk_i
--              * reset : clk_div_o low during reset, first rising edge at
--                the expected clk_i edge after the release
--              * cke_i = 0 : clk_div_o frozen
--              * cke_i = 1 one cycle out of 2 (pulse) : period 2*RATIO*T
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2017-04-27  1.0      mrosiere Created
-- 2022-02-09  1.1      mrosiere Update tb from ALGO parameter
-- 2026-10-05  2.0      mrosiere UVVM self-checking testbench
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.clock_divider_pkg.all;

entity tb_clock_divider is
end entity tb_clock_divider;

architecture tb of tb_clock_divider is

  constant C_SCOPE      : string        := "TB_CLOCK_DIVIDER";
  constant C_CLK_PERIOD : time          := 10 ns;
  constant C_SETTLE     : time          := 1 ns;
  constant C_RATIOS     : integer_vector := (1, 2, 3, 4, 5, 6, 7, 8, 24, 25);
  constant C_NB         : natural       := C_RATIOS'length;
  constant C_NB_PERIODS : natural       := 3;     -- number of periods measured

  -- Index 0 : "pulse", index 1 : "50%"
  type     clk_div_t is array (0 to 1) of std_logic_vector(0 to C_NB-1);

  signal   clk_i        : std_logic := '0';
  signal   clk_ena      : boolean   := true;
  signal   cke_i        : std_logic := '1';
  signal   cke_req      : std_logic := '1';   -- cke_i value requested by the sequencer
  signal   cke_toggle   : boolean   := false; -- cke_i active one cycle out of 2
  signal   arstn_i      : std_logic := '0';
  signal   clk_div      : clk_div_t;

  function algo_name(a : natural) return string is
  begin
    if a = 0 then return "pulse"; else return "50%"; end if;
  end function;

  -- Expected high time (cke_i = 1)
  function exp_high(a : natural; ratio : positive) return time is
  begin
    if ratio = 1 then
      return C_CLK_PERIOD/2;
    elsif a = 0 then
      return C_CLK_PERIOD;
    else
      return (ratio * C_CLK_PERIOD) / 2;
    end if;
  end function;

  -- Expected clk_i rising edge (counted from the reset release) of the
  -- first rising edge of clk_div_o
  function exp_first_rise(a : natural; ratio : positive) return natural is
  begin
    if a = 0 then return ratio; else return 1; end if;
  end function;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUTs
  -----------------------------------------------------------------------------
  gen_ratio : for i in 0 to C_NB-1 generate
    dut_pulse : clock_divider
      generic map
      (RATIO     => C_RATIOS(i)
      ,ALGO      => "pulse"
      )
      port map
      (clk_i     => clk_i
      ,cke_i     => cke_i
      ,arstn_i   => arstn_i
      ,clk_div_o => clk_div(0)(i)
      );

    dut_50 : clock_divider
      generic map
      (RATIO     => C_RATIOS(i)
      ,ALGO      => "50%"
      )
      port map
      (clk_i     => clk_i
      ,cke_i     => cke_i
      ,arstn_i   => arstn_i
      ,clk_div_o => clk_div(1)(i)
      );
  end generate gen_ratio;

  -----------------------------------------------------------------------------
  -- Clock enable driver : cke_i changes on the falling edges of clk_i
  -----------------------------------------------------------------------------
  p_cke : process
  begin
    wait until falling_edge(clk_i);
    if cke_toggle then
      cke_i <= not cke_i;
    else
      cke_i <= cke_req;
    end if;
  end process p_cke;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process
    variable v_first : integer_vector(0 to 2*C_NB-1);
    variable v_snap  : clk_div_t;
    variable v_ok    : boolean;

    -- Measure period and high time of clk_div(a)(i) over C_NB_PERIODS periods
    procedure measure(a        : natural;
                      i        : natural;
                      period   : time;
                      high     : time;
                      msg      : string) is
      variable t_rise : time;
      variable t_fall : time;
      variable t_next : time;
    begin
      if clk_div(a)(i) = '1' then
        wait until clk_div(a)(i) = '0';
      end if;
      wait until clk_div(a)(i) = '1';
      for n in 1 to C_NB_PERIODS loop
        t_rise := now;
        wait until clk_div(a)(i) = '0';
        t_fall := now;
        wait until clk_div(a)(i) = '1';
        t_next := now;
        check_value(t_next - t_rise, period, ERROR, msg & " : period");
        if high > 0 ns then
          check_value(t_fall - t_rise, high  , ERROR, msg & " : high time");
        end if;
      end loop;
    end procedure;

    -- Measure all instances with cke_i = 1
    procedure measure_all(msg : string) is
    begin
      for a in 0 to 1 loop
        for i in 0 to C_NB-1 loop
          measure(a, i,
                  C_RATIOS(i) * C_CLK_PERIOD,
                  exp_high(a, C_RATIOS(i)),
                  msg & " RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a));
        end loop;
      end loop;
    end procedure;

  begin
    ------------------------------------------------
    log(ID_LOG_HDR, "1. Reset", C_SCOPE);
    ------------------------------------------------
    arstn_i <= '0';
    for c in 1 to 10 loop
      wait until falling_edge(clk_i);
      for a in 0 to 1 loop
        for i in 0 to C_NB-1 loop
          if C_RATIOS(i) > 1 then
            check_value(clk_div(a)(i), '0', ERROR, "clk_div_o low during reset RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a), C_SCOPE, ID_NEVER);
          end if;
        end loop;
      end loop;
    end loop;

    -- Release reset between 2 rising edges, count the rising edges of clk_i
    -- up to the first rising edge of each clk_div_o
    arstn_i <= '1';
    v_first := (others => 0);
    for c in 1 to 30 loop
      wait until rising_edge(clk_i);
      wait for C_SETTLE;
      for a in 0 to 1 loop
        for i in 0 to C_NB-1 loop
          if v_first(a*C_NB+i) = 0 and clk_div(a)(i) = '1' then
            v_first(a*C_NB+i) := c;
          end if;
        end loop;
      end loop;
    end loop;
    for a in 0 to 1 loop
      for i in 0 to C_NB-1 loop
        if C_RATIOS(i) > 1 then
          check_value(v_first(a*C_NB+i), exp_first_rise(a, C_RATIOS(i)), ERROR,
                      "First rising edge after reset RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a));
        end if;
      end loop;
    end loop;

    ------------------------------------------------
    log(ID_LOG_HDR, "2. Period and high time (cke_i = 1)", C_SCOPE);
    ------------------------------------------------
    measure_all("cke_i=1");

    ------------------------------------------------
    log(ID_LOG_HDR, "3. cke_i = 0 : clk_div_o frozen", C_SCOPE);
    ------------------------------------------------
    for k in 0 to 3 loop
      -- stop at different phases of the dividers
      for c in 0 to k*3 loop
        wait until rising_edge(clk_i);
      end loop;
      cke_req <= '0';
      wait until falling_edge(clk_i);  -- cke_i <= '0'
      wait until rising_edge(clk_i);   -- first rising edge with cke_i = 0
      wait for C_SETTLE;
      v_snap := clk_div;
      v_ok   := true;
      for c in 1 to 4*30 loop
        wait for C_CLK_PERIOD/4;
        for a in 0 to 1 loop
          for i in 0 to C_NB-1 loop
            if C_RATIOS(i) > 1 and clk_div(a)(i) /= v_snap(a)(i) then
              v_ok := false;
              alert(ERROR, "clk_div_o changed while cke_i=0 RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a), C_SCOPE);
            end if;
          end loop;
        end loop;
      end loop;
      check_value(v_ok, ERROR, "All clk_div_o (RATIO>1) frozen during 30 cycles with cke_i=0 (phase " & to_string(k) & ")");
      -- RATIO = 1 : clk_div_o is clk_i, cke_i has no effect
      for a in 0 to 1 loop
        check_value(clk_div(a)(0), clk_i, ERROR, "RATIO=1 : clk_div_o = clk_i while cke_i=0 ALGO=" & algo_name(a));
      end loop;
      cke_req <= '1';
      wait until falling_edge(clk_i);  -- cke_i <= '1'
    end loop;
    measure_all("After cke_i=0");

    ------------------------------------------------
    log(ID_LOG_HDR, "4. cke_i = 1 one cycle out of 2 : period 2*RATIO", C_SCOPE);
    ------------------------------------------------
    cke_toggle <= true;
    wait until rising_edge(clk_i);
    for a in 0 to 1 loop
      for i in 0 to C_NB-1 loop
        if C_RATIOS(i) > 1 then
          -- pulse : high 2 cycles (no high time check for 50%)
          if a = 0 then
            measure(a, i, 2*C_RATIOS(i)*C_CLK_PERIOD, 2*C_CLK_PERIOD,
                    "cke_i 1/2 RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a));
          else
            measure(a, i, 2*C_RATIOS(i)*C_CLK_PERIOD, 0 ns,
                    "cke_i 1/2 RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a));
          end if;
        end if;
      end loop;
    end loop;
    cke_toggle <= false;
    cke_req    <= '1';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    measure_all("After cke_i toggling");

    ------------------------------------------------
    log(ID_LOG_HDR, "5. Reset while running", C_SCOPE);
    ------------------------------------------------
    for k in 1 to 7 loop
      wait until rising_edge(clk_i);
    end loop;
    wait for C_CLK_PERIOD/4;
    arstn_i <= '0';
    wait for C_SETTLE;
    for a in 0 to 1 loop
      for i in 1 to C_NB-1 loop
        check_value(clk_div(a)(i), '0', ERROR, "clk_div_o cleared by asynchronous reset RATIO=" & to_string(C_RATIOS(i)) & " ALGO=" & algo_name(a));
      end loop;
    end loop;
    wait until falling_edge(clk_i);
    arstn_i <= '1';
    measure_all("After reset");

    log(ID_LOG_HDR, "Simulation Finished", C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture tb;
