library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity new_vga_sync is
    port(
        reset          : in std_logic;
        pix_clk_40MHz  : in std_logic;
        pll_locked     : in std_logic;
        h_sync         : out std_logic;
        v_sync         : out std_logic;
        column_count   : out std_logic_vector (10 downto 0);
        row_count      : out std_logic_vector (9 downto 0);
        disp_enable    : out std_logic
    );
end new_vga_sync;

architecture arch_new_vga_sync of new_vga_sync is

    -- Constantes para a sincronização VGA
    constant h_display_c  : integer := 800;
    constant h_fp_c       : integer := 40;
    constant h_sync_c     : integer := 128;
    constant h_bp_c       : integer := 88;
    constant h_total_c    : integer := 1056;

    constant v_display_c  : integer := 600;
    constant v_fp_c       : integer := 1;
    constant v_sync_c     : integer := 4;
    constant v_bp_c       : integer := 23;
    constant v_total_c    : integer := 628;

    signal h_count : unsigned(10 downto 0) := (others => '0');
    signal v_count : unsigned(9 downto 0)  := (others => '0');

begin

    process(reset, pll_locked, pix_clk_40MHz)
    begin
        if reset = '0' or pll_locked = '0' then
            h_count <= (others => '0');
            v_count <= (others => '0');
        elsif rising_edge(pix_clk_40MHz) then
            -- Incrementa o contador horizontal
            if h_count < h_total_c - 1 then
                h_count <= h_count + 1;
            else
                -- Reinicia o contador horizontal e incrementa o vertical
                h_count <= (others => '0');
                if v_count < v_total_c - 1 then
                    v_count <= v_count + 1;
                else
                    v_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    h_sync        <= '0' when ((to_integer(h_count) >= h_display_c + h_fp_c) and (to_integer(h_count) < h_display_c + h_fp_c + h_sync_c)) else '1';
    v_sync        <= '0' when ((to_integer(v_count) >= v_display_c + v_fp_c) and (to_integer(v_count) < v_display_c + v_fp_c + v_sync_c)) else '1';
    disp_enable   <= '1' when ((to_integer(h_count) < h_display_c) and (to_integer(v_count) < v_display_c)) else '0';
    column_count  <= std_logic_vector(h_count);
    row_count     <= std_logic_vector(v_count);

end arch_new_vga_sync;