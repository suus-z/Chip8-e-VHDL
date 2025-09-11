--RTL architecture of vga port
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_rtl is
    port(
        reset       :   in std_logic;
        clk50MHz    :   in std_logic;
        vga_clk     :   out std_logic;
        h_sync      :   out std_logic;
        v_sync      :   out std_logic;
        R           :   out std_logic_vector(7 downto 0);
        G           :   out std_logic_vector(7 downto 0);
        B           :   out std_logic_vector(7 downto 0);
        enable      :   out std_logic;

        vga_blank_n :   out std_logic;
        vga_sync_n  :   out std_logic
    );
end vga_rtl;

architecture rtl of vga_rtl is

    component clk40MHz is
        port(
            areset : in std_logic;
            inclk0 : in std_logic;
            c0     : out std_logic;
            locked : out std_logic
        );
    end component clk40MHz;

    component new_vga_sync is
        port(
            reset            : in std_logic;
            pix_clk_40MHz    : in std_logic;
            pll_locked       : in std_logic;
            h_sync           : out std_logic;
            v_sync           : out std_logic;
            column_count     : out std_logic_vector (10 downto 0);
            row_count        : out std_logic_vector (9 downto 0);
            disp_enable      : out std_logic
        );
    end component new_vga_sync;

    component pixel_gen is
        port(
            RESET       : in std_logic;
            F_CLOCK     : in std_logic;
            F_ON        : in std_logic;
            F_ROW       : in std_logic_vector(9 downto 0);
            F_COLUMN    : in std_logic_vector(10 downto 0);
            R_out       : out std_logic_vector(7 downto 0);
            G_out       : out std_logic_vector(7 downto 0);
            B_out       : out std_logic_vector(7 downto 0)
        );
    end component pixel_gen;

    signal pix_clk_40MHz    : std_logic;
    signal pll_locked       : std_logic;
    signal current_column   : std_logic_vector(10 downto 0);
    signal current_row      : std_logic_vector(9 downto 0);
    signal disp_enable      : std_logic;
    signal h_sync_s         : std_logic;
    signal v_sync_s         : std_logic;

begin

    vga_clk     <= pix_clk_40MHz;
    vga_blank_n <= not disp_enable;
    vga_sync_n  <= not (h_sync_s or v_sync_s);
    h_sync      <= h_sync_s;
    v_sync      <= v_sync_s;
    enable      <= disp_enable;

    inst_clk40MHz : clk40MHz
        port map (
            areset => not reset,
            inclk0 => clk50MHz,
            c0 => pix_clk_40MHz,
            locked => pll_locked
        );

    VgaSync: new_vga_sync port map(
        reset           => reset,
        pix_clk_40MHz   => pix_clk_40MHz,
        pll_locked      => pll_locked,
        h_sync          => h_sync_s,
        v_sync          => v_sync_s,
        column_count    => current_column,
        row_count       => current_row,
        disp_enable     => disp_enable
    );

    PixelGen: pixel_gen port map(
        reset        => reset,
        F_CLOCK      => pix_clk_40MHz,
        F_ON         => disp_enable,
        F_ROW        => current_row,
        F_COLUMN     => current_column,
        R_out        => R,
        G_out        => G,
        B_out        => B
    );

end rtl;