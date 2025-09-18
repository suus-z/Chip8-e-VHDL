--Scaling 64x32p to 800x600p 60Hz
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_FB is
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
end vga_FB;

architecture arch_chip8_vga of vga_FB is

    constant CHIP8_W : integer := 64;
    constant CHIP8_H : integer := 32;
    constant VGA_W   : integer := 800;
    constant VGA_H   : integer := 600;
    constant SCALE_X : integer := VGA_W / CHIP8_W;  --12
    constant SCALE_Y : integer := VGA_H / CHIP8_H;  --18
    constant FRAME_BASE : integer := 16#F00#;

    signal column_count : std_logic_vector(10 downto 0);
    signal row_count    : std_logic_vector(9 downto 0);
    signal vga_disp_en  : std_logic;

    signal chip8_x, chip8_y : integer range 0 to CHIP8_W-1;
    signal bit_index         : integer range 0 to 7;
    signal byte_index        : integer range 0 to 255;
    signal pixel_on          : std_logic;

    component sync_FB is
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
    end component;

begin

    vga_sync_inst : sync_FB
        port map(
            reset        => reset,
            pix_clk_40MHz => pix_clk_40MHz,
            pll_locked   => pll_locked,
            h_sync       => h_sync,
            v_sync       => v_sync,
            column_count => column_count,
            row_count    => row_count,
            disp_enable  => vga_disp_en
        );

    disp_enable <= vga_disp_en;

    process(column_count, row_count)
    begin
        chip8_x <= to_integer(unsigned(column_count)) / SCALE_X;
        chip8_y <= to_integer(unsigned(row_count))    / SCALE_Y;

        --Framebuffer's index
        byte_index <= chip8_y * 8 + (chip8_x / 8);
        bit_index  <= 7 - (chip8_x mod 8);

        ram_addr <= std_logic_vector(to_unsigned(FRAME_BASE + byte_index, 12));

        if ram_dout(bit_index) = '1' and vga_disp_en = '1' then
            pixel_on <= '1';
        else
            pixel_on <= '0';
        end if;
    end process;

    --Monochromatic output
    rgb <= (others => '1') when pixel_on = '1' else (others => '0');

end arch_chip8_vga;