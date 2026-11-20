-------------------------------------------------------------------------------
-- Title      : tb_clock_divider
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_clock_divider.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of clock_divider.
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_clock_divider_tests_pkg), each one after a
--                           reset pulse ; "" : build and elaboration only
--              RATIO      : RATIO of the DUT
--              ALGO_50    : ALGO of the DUT, false : "pulse", true : "50%"
--                           (a FuseSoC parameter value cannot contain '%')
--              A second instance with BYPASS_CBUFG = true runs next to the
--              DUT : a monitor compares the two clk_div_o C_SETTLE after
--              every change of one of them, in every scenario.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2017-04-27  1.0      mrosiere Created
-- 2022-02-09  1.1      mrosiere Update tb from ALGO parameter
-- 2026-10-05  2.0      mrosiere UVVM self-checking testbench
-- 2026-10-22  2.1      mrosiere Instances with BYPASS_CBUFG = true
-- 2026-11-20  3.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_clock_divider_<name>_pkg), helpers in
--                               tb_clock_divider_bfm_pkg, reset pulse before
--                               each scenario, one DUT configuration per run
--                               (generics RATIO, ALGO_50)
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;
use     asylum.clock_divider_pkg.all;

library work;
use     work.tb_clock_divider_bfm_pkg.all;
use     work.tb_clock_divider_tests_pkg.all;

entity tb_clock_divider is
  generic (
    TESTS_LIST    : string   := ""     -- Scenarios, e.g. "reset,period"
   ;RATIO         : positive := 5      -- RATIO of the DUT
   ;ALGO_50       : boolean  := true   -- false : ALGO "pulse", true : "50%"
  );
end entity tb_clock_divider;

architecture tb of tb_clock_divider is

  constant C_SCOPE       : string     := "TB_CLOCK_DIVIDER";

  signal   clk_i         : std_logic  := '0';
  signal   clk_ena       : boolean    := true;
  signal   cke_i         : std_logic  := '1';
  signal   cke_mode      : cke_mode_t := CKE_ON;
  signal   arstn_i       : std_logic  := '0';
  signal   clk_div_o     : std_logic;
  signal   clk_div_byp   : std_logic;  -- Instance with BYPASS_CBUFG = true

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : clock_divider
    generic map
    (RATIO        => RATIO
    ,ALGO         => algo_name(ALGO_50)
    ,BYPASS_CBUFG => false
    )
    port map
    (clk_i        => clk_i
    ,cke_i        => cke_i
    ,arstn_i      => arstn_i
    ,clk_div_o    => clk_div_o
    );

  dut_byp : clock_divider
    generic map
    (RATIO        => RATIO
    ,ALGO         => algo_name(ALGO_50)
    ,BYPASS_CBUFG => true
    )
    port map
    (clk_i        => clk_i
    ,cke_i        => cke_i
    ,arstn_i      => arstn_i
    ,clk_div_o    => clk_div_byp
    );

  -----------------------------------------------------------------------------
  -- BYPASS_CBUFG = true : clk_div_o equal to the one of the DUT (cbufg),
  -- compared C_SETTLE after each change of one of them
  -----------------------------------------------------------------------------
  p_bypass : process
  begin
    wait on clk_div_o, clk_div_byp;
    wait for C_SETTLE;
    check_value(clk_div_byp, clk_div_o, ERROR, "BYPASS_CBUFG = true : clk_div_o equal to the DUT", C_SCOPE, ID_NEVER);
  end process p_bypass;

  -----------------------------------------------------------------------------
  -- Clock enable driver (cke_mode, see tb_clock_divider_bfm_pkg) : cke_i
  -- changes on the falling edges of clk_i, or C_SETTLE after the rising
  -- edges (CKE_HALF_RISE)
  -----------------------------------------------------------------------------
  p_cke : process
  begin
    if cke_mode = CKE_HALF_RISE
    then
      wait until rising_edge(clk_i);
      wait for C_SETTLE;
      cke_i <= not cke_i;
    else
      wait until falling_edge(clk_i);
      case cke_mode is
        when CKE_ON        => cke_i <= '1';
        when CKE_OFF       => cke_i <= '0';
        when others        => cke_i <= not cke_i;
      end case;
    end if;
  end process p_cke;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "RATIO = " & integer'image(RATIO) & ", ALGO = " & algo_name(ALGO_50) & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, cke_i = '1' : each scenario starts from reset, released
      -- on a falling edge of clk_i
      cke_mode <= CKE_ON;
      arstn_i  <= '0';
      for c in 1 to 3 loop
        wait until falling_edge(clk_i);
      end loop;
      arstn_i  <= '1';

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), RATIO, ALGO_50, clk_i, arstn_i, cke_mode, clk_div_o, clk_div_byp);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture tb;
