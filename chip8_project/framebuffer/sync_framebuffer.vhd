--Sync signals for VGA bus
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.framebuffer_constants.all;

entity sync_framebuffer is
  port (
    pix_clk : in std_logic;
    reset   : in std_logic;

    disp_en : out std_logic;
    h_sync  : out std_logic;
    v_sync  : out std_logic;
    column  : out std_logic_vector(9 downto 0);
    row     : out std_logic_vector(9 downto 0)
  );
end sync_framebuffer;

architecture arch_sync_framebuffer of sync_framebuffer is
  signal h_count : unsigned(9 downto 0) := (others => '0');
  signal v_count : unsigned(9 downto 0) := (others => '0');

begin
  process (reset, pix_clk)
  begin
    if reset = '0' then
      h_count <= (others => '0');
      v_count <= (others => '0');
    elsif rising_edge(pix_clk) then

      if h_count < H_TOTAL - 1 then
        h_count <= h_count + 1;
      else
        h_count <= (others => '0');

        if v_count < V_TOTAL - 1 then
          v_count <= v_count + 1;
        else
          v_count <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  h_sync  <= '0' when ((to_integer(h_count) >= H_ACTIVE + H_FP) and (to_integer(h_count) < H_ACTIVE + H_FP + HSYNC)) else '1';
  v_sync  <= '0' when ((to_integer(v_count) >= V_ACTIVE + V_FP) and (to_integer(v_count) < V_ACTIVE + V_FP + VSYNC)) else '1';
  disp_en <= '1' when ((to_integer(h_count) < H_ACTIVE) and (to_integer(v_count) < V_ACTIVE)) else '0';
  column  <= std_logic_vector(h_count);
  row     <= std_logic_vector(v_count);

end arch_sync_framebuffer;