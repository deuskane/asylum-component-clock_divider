library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

package clock_divider_pkg is
-- [COMPONENT_INSERT][BEGIN]
component clock_divider is
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
end component clock_divider;

-- [COMPONENT_INSERT][END]

end clock_divider_pkg;
