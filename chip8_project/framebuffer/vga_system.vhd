--RTL of framebuffer VGA
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_constants.all;
use work.framebuffer_constants.all;
use work.instructions_constants.all;

entity vga_system is
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        
        --Port B Interface (Display Reading - VGA)
        ram_addr_b   : out std_logic_vector(11 downto 0);
        ram_dout_b   : in  std_logic_vector(7 downto 0);

        --Port A Interface (CLS/DRW Write - To Memory Arbiter)
        ram_req_a    : out std_logic;
        ram_we_a     : out std_logic;
        ram_addr_a   : out std_logic_vector(11 downto 0);
        ram_din_a    : out std_logic_vector(7 downto 0);
        ram_dout_a   : in  std_logic_vector(7 downto 0);

        --Comand Interface (from control unit)
        op_code_in   : in  std_logic_vector(5 downto 0);
        cmd_valid    : in  std_logic;
        cmd_x        : in  std_logic_vector(5 downto 0);
        cmd_y        : in  std_logic_vector(4 downto 0);
        cmd_i_reg    : in  std_logic_vector(11 downto 0);
        cmd_n        : in  std_logic_vector(3 downto 0);

        --Outputs to control unit
        cmd_ack      : out std_logic;
        cmd_done     : out std_logic;
        collision    : out std_logic;

        --VGA Outputs
        r, g, b      : out std_logic_vector(7 downto 0);
        pix_valid    : out std_logic;

        --Sync signals
        h_sync       : out std_logic;
        v_sync       : out std_logic;
        sync_n       : out std_logic;
        blank_n      : out std_logic
    );
end vga_system;

architecture rtl of vga_system is
    component tick_25MHz is
        generic (
            CLK_FREQ_IN  : integer := 50e6;
            CLK_FREQ_OUT : integer := 25e6
        );

        port (
            clk        : in std_logic;
            reset      : in std_logic;
            tick_25MHz : out std_logic
        );
    end component tick_25MHz;

    component sync_framebuffer is
        port (
            pix_clk : in std_logic;
            reset   : in std_logic;

            disp_en : out std_logic;
            h_sync  : out std_logic;
            v_sync  : out std_logic;
            column  : out std_logic_vector(9 downto 0);
            row     : out std_logic_vector(9 downto 0)
        );
    end component sync_framebuffer;

    component vga_fb_controller is
        port (
            reset        : in  std_logic;
            cmd_clk      : in  std_logic;
            pix_clk      : in  std_logic;
            disp_en      : in  std_logic;
            vga_column   : in  std_logic_vector(9 downto 0);
            vga_row      : in  std_logic_vector(9 downto 0);

            ram_addr_b   : out std_logic_vector(11 downto 0);
            ram_dout_b   : in  std_logic_vector(7 downto 0);

            ram_req_a    : out std_logic;
            ram_we_a     : out std_logic;
            ram_addr_a   : out std_logic_vector(11 downto 0);
            ram_din_a    : out std_logic_vector(7 downto 0);
            ram_dout_a   : in  std_logic_vector(7 downto 0);

            op_code_in   : in  std_logic_vector(5 downto 0);
            cmd_valid    : in  std_logic;
            cmd_x        : in  std_logic_vector(5 downto 0);
            cmd_y        : in  std_logic_vector(4 downto 0);
            cmd_i_reg    : in  std_logic_vector(11 downto 0);
            cmd_n        : in  std_logic_vector(3 downto 0);

            cmd_ack      : out std_logic;
            cmd_done     : out std_logic;
            collision    : out std_logic;

            r, g, b      : out std_logic_vector(7 downto 0);
            pix_valid    : out std_logic
        );
    end component vga_fb_controller;

    signal disp_en      : std_logic;
    signal column, row  : std_logic_vector(9 downto 0);
    signal pix_clk      : std_logic;
    signal hsync_s, vsync_s : std_logic;

begin
    inst_tick_25MHz: tick_25MHz port map(clk, reset, pix_clk);

    inst_sync_framebuffer: sync_framebuffer port map(
        pix_clk => pix_clk,
        reset   => reset,
        disp_en => disp_en,
        h_sync  => hsync_s,
        v_sync  => vsync_s,
        column  => column,
        row     => row);

    inst_vga_fb_controller: vga_fb_controller port map(
        reset      => reset,
        cmd_clk    => clk,
        pix_clk    => pix_clk,
        disp_en    => disp_en,
        vga_column => column,
        vga_row    => row,
        ram_addr_b => ram_addr_b,
        ram_dout_b => ram_dout_b,
        ram_req_a  => ram_req_a,
        ram_addr_a => ram_addr_a,
        ram_din_a  => ram_din_a,
        ram_dout_a => ram_dout_a,
        op_code_in => op_code_in,
        cmd_valid  => cmd_valid,
        cmd_x      => cmd_x,
        cmd_y      => cmd_y,
        cmd_i_reg  => cmd_i_reg,
        cmd_n      => cmd_n,
        cmd_ack    => cmd_ack,
        cmd_done   => cmd_done,
        collision  => collision,
        r          => r,
        g          => g,
        b          => b,
        pix_valid  => pix_valid
    );

    sync_n  <= not (hsync_s xor vsync_s);
    h_sync  <= hsync_s;
    v_sync  <= vsync_s;
    blank_n <= not disp_en;
end rtl;