--Top level of framebuffer
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RTL_FB is
    port(
        clkin        :   in  std_logic;
        reset        :   in  std_logic;
        ram_dout     :   in  std_logic_vector(7 downto 0);
        ram_addr     :   out std_logic_vector(11 downto 0);
        h_sync       :   out std_logic;
        v_sync       :   out std_logic;
        rgb          :   out std_logic_vector(7 downto 0);
        disp_enable  :   out std_logic
    );
end RTL_FB;

architecture rtl of RTL_FB is

    signal pix_clk_40MHz    :   std_logic;
    signal pll_locked       :   std_logic;

    component clk40MHz is
        port(
            areset : in std_logic;
            inclk0 : in std_logic;
            c0     : out std_logic;
            locked : out std_logic
        );
    end component clk40MHz;

    component vga_FB is
        port(
        reset          : in  std_logic;
        pix_clk_40MHz  : in  std_logic;
        pll_locked     : in  std_logic;
        ram_dout       : in  std_logic_vector(7 downto 0);  --framebuffer's byte
        ram_addr       : out std_logic_vector(11 downto 0); --RAM addres
        h_sync         : out std_logic;
        v_sync         : out std_logic;
        rgb            : out std_logic_vector(7 downto 0);
        disp_enable    : out std_logic
    );
    end component vga_FB;

begin

    inst_clk_40MHz: clk40MHz port map(not reset, clkin, pix_clk_40MHz, pll_locked);
    inst_vga_FB:    vga_FB port map(reset, pix_clk_40MHz, pll_locked, ram_dout, ram_addr, h_sync, v_sync, rgb, disp_enable);

end rtl;