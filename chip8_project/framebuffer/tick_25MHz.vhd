--25MHz clock for framebuffer based on a generic clock divisor
library ieee;
use ieee.std_logic_1164.all;

entity tick_25MHz is
  generic (
    CLK_FREQ_IN  : integer := 50e6;
    CLK_FREQ_OUT : integer := 25e6
  );

  port (
    clk        : in std_logic;
    reset      : in std_logic;
    tick_25MHz : out std_logic
  );
end tick_25MHz;

architecture arch_tick_25MHz of tick_25MHz is
  constant MAX_COUNT : integer                          := CLK_FREQ_IN/CLK_FREQ_OUT;
  signal count       : integer range 0 to MAX_COUNT - 1 := 0;
  signal tick        : std_logic                        := '0';

begin
  process (clk, reset)
  begin
    if reset = '0' then
      count <= 0;
      tick  <= '0';

    elsif rising_edge(clk) then
      if count = MAX_COUNT - 1 then
        count <= 0;
        tick  <= '1';
      else
        count <= count + 1;
        tick  <= '0';
      end if;
    end if;
  end process;

  tick_25MHz <= tick;
end arch_tick_25MHz;