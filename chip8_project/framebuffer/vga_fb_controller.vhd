--CHIP-8 VGA/Framebuffer Controller
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_constants.all;
use work.instructions_constants.all;

entity vga_fb_controller is
    port (
        --Clocks and reset
        reset        : in  std_logic;
        cmd_clk      : in  std_logic;   --CPU clock (50 MHz)
        pix_clk      : in  std_logic;   --Pixel clock (25 MHz)
        disp_en      : in  std_logic;
        vga_column   : in  std_logic_vector(9 downto 0); --(0-639)
        vga_row      : in  std_logic_vector(9 downto 0); --(0-479)

        sys_ram_addr : out std_logic_vector(11 downto 0);
        sys_ram_dout : in  std_logic_vector(7 downto 0);

        --VRAM Port B interface (for reading)
        ram_addr_b   : out std_logic_vector(7 downto 0);
        ram_dout_b   : in  std_logic_vector(7 downto 0);

        --VRAM Port A interface (for CLS/DRW writing)
        ram_we_a     : out std_logic;
        ram_addr_a   : out std_logic_vector(7 downto 0);
        ram_din_a    : out std_logic_vector(7 downto 0);
        ram_dout_a   : in  std_logic_vector(7 downto 0);

        --Command interface
        op_code_in   : in  std_logic_vector(5 downto 0);
        cmd_valid    : in  std_logic;
        cmd_x        : in  std_logic_vector(5 downto 0);
        cmd_y        : in  std_logic_vector(4 downto 0);
        cmd_i_reg    : in  std_logic_vector(11 downto 0);
        cmd_n        : in  std_logic_vector(3 downto 0);

        --CPU outputs
        cmd_ack      : out std_logic;
        cmd_done     : out std_logic;
        collision    : out std_logic;

        --VGA outputs
        r, g, b      : out std_logic_vector(7 downto 0);
        pix_valid    : out std_logic
    );
end vga_fb_controller;

architecture arch_vga_fb_controller of vga_fb_controller is
    
    type state_type is (IDLE, CLS_START, CLS_LOOP, DRW_START, DRW_READ_1, DRW_WRITE_1, DRW_READ_2, DRW_WRITE_2, DRW_NEXT_LINE, DONE);
    signal state          : state_type := IDLE;

    --Control registers
    signal x_reg, y_reg    : unsigned(5 downto 0);
    signal sprite_x_start  : unsigned(5 downto 0);
    signal sprite_y_start  : unsigned(4 downto 0);
    signal sprite_addr     : unsigned(11 downto 0);
    signal n_lines         : unsigned(3 downto 0);
    signal current_line    : unsigned(3 downto 0);
    signal col_flag        : std_logic := '0';
    signal current_sprite_byte : std_logic_vector(7 downto 0);
    signal current_fb_addr     : std_logic_vector(7 downto 0);

    --VGA
    signal chip8_x             : unsigned(5 downto 0);
    signal chip8_y             : unsigned(4 downto 0);
    signal ram_byte_data       : std_logic_vector(7 downto 0);
    signal rgb_int             : std_logic_vector(23 downto 0);

begin

    --VGA reading
    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            if disp_en = '1' then
                chip8_x <= to_unsigned(to_integer(unsigned(vga_column)) / 10, 6);
                chip8_y <= to_unsigned(to_integer(unsigned(vga_row)) / 15, 5);
                ram_byte_data <= ram_dout_b;
                pix_valid <= '1';
            else
                pix_valid <= '0';
            end if;
        end if;
    end process;

    ram_addr_b <= "00" & std_logic_vector(chip8_y(2 downto 0) & chip8_x(5 downto 3));

    process(ram_byte_data, chip8_x)
        variable pixel_idx : integer;
    begin
        pixel_idx := 7 - to_integer(chip8_x(2 downto 0));
        if ram_byte_data(pixel_idx) = '1' then
            rgb_int <= (others => '1');
        else
            rgb_int <= (others => '0');
        end if;
    end process;

    r <= rgb_int(23 downto 16);
    g <= rgb_int(15 downto 8);
    b <= rgb_int(7 downto 0);

    --FSM writing
    process(cmd_clk, reset)
        variable y_wrap        : unsigned(4 downto 0);
        variable x_bit_offset  : unsigned(2 downto 0);
        variable fb_col_addr   : unsigned(2 downto 0);
        variable next_byte     : std_logic_vector(7 downto 0);
        variable shift         : integer;
        variable sprite_left_shifted, sprite_right_shifted, collision_part : std_logic_vector(7 downto 0);
    begin
        if reset = '0' then
            state <= IDLE;
            cmd_ack <= '0';
            cmd_done <= '0';
            collision <= '0';
            ram_we_a <= '0';
        elsif rising_edge(cmd_clk) then
            cmd_ack <= '0';
            cmd_done <= '0';
            ram_we_a <= '0';
            collision <= col_flag;

            case state is
                when IDLE =>
                    if cmd_valid = '1' then
                        cmd_ack <= '1';
                        if op_code_in = I_CLS then
                            state <= CLS_START;
                        elsif op_code_in = I_DRW then
                            sprite_x_start <= unsigned(cmd_x);
                            sprite_y_start <= unsigned(cmd_y);
                            n_lines <= unsigned(cmd_n);
                            sprite_addr <= unsigned(cmd_i_reg);
                            current_line <= (others => '0');
                            col_flag <= '0';
                            state <= DRW_START;
                        end if;
                    end if;

                when CLS_START =>
                    x_reg <= (others => '0');
                    y_reg <= (others => '0');
                    state <= CLS_LOOP;

                when CLS_LOOP =>
                    current_fb_addr <= "00" & std_logic_vector(y_reg(2 downto 0) & x_reg(2 downto 0));
                    ram_addr_a <= current_fb_addr;
                    ram_din_a <= x"00";
                    ram_we_a <= '1';

                    if x_reg = 7 then
                        x_reg <= (others => '0');
                        if y_reg = 31 then
                            state <= DONE;
                        else
                            y_reg <= y_reg + 1;
                        end if;
                    else
                        x_reg <= x_reg + 1;
                    end if;

                when DRW_START =>
                    sys_ram_addr <= std_logic_vector(sprite_addr + current_line);
                    state <= DRW_READ_1;

                when DRW_READ_1 =>
                    current_sprite_byte <= ram_dout_a;
                    y_wrap := to_unsigned((to_integer(sprite_y_start) + to_integer(current_line)) mod 32, 5);
                    x_bit_offset := sprite_x_start(2 downto 0);
                    fb_col_addr := sprite_x_start(5 downto 3);
                    current_fb_addr <= "00" & std_logic_vector(y_wrap(2 downto 0) & fb_col_addr);
                    ram_addr_a <= current_fb_addr;
                    state <= DRW_WRITE_1;

                when DRW_WRITE_1 =>
                    sprite_left_shifted := std_logic_vector(
                                shift_left(unsigned(current_sprite_byte), to_integer(x_bit_offset))
                            );
                            collision_part := ram_dout_a and sprite_left_shifted;
                    if collision_part /= x"00" then
                        col_flag <= '1';
                    end if;
                    next_byte := ram_dout_a xor sprite_left_shifted;
                    ram_din_a <= next_byte;
                    ram_addr_a <= current_fb_addr;
                    ram_we_a <= '1';
                    if to_integer(x_bit_offset) > 0 then
                        state <= DRW_READ_2;
                    else
                        state <= DRW_NEXT_LINE;
                    end if;

                when DRW_READ_2 =>
                    ram_addr_a <= std_logic_vector(unsigned(current_fb_addr) + 1);
                    state <= DRW_WRITE_2;

                when DRW_WRITE_2 =>
                    shift := 8 - to_integer(sprite_x_start(2 downto 0));
                            sprite_right_shifted := std_logic_vector(
                                shift_right(unsigned(current_sprite_byte), shift)
                            );
                            collision_part := ram_dout_a and sprite_right_shifted;
                    if collision_part /= x"00" then
                        col_flag <= '1';
                    end if;
                    next_byte := ram_dout_a xor sprite_right_shifted;
                    ram_din_a <= next_byte;
                    ram_addr_a <= std_logic_vector(unsigned(current_fb_addr) + 1);
                    ram_we_a <= '1';
                    state <= DRW_NEXT_LINE;

                when DRW_NEXT_LINE =>
                    if current_line = n_lines - 1 then
                        state <= DONE;
                    else
                        current_line <= current_line + 1;
                        sprite_addr <= sprite_addr + 1;
                        state <= DRW_START;
                    end if;

                when DONE =>
                    cmd_done <= '1';
                    collision <= col_flag;
                    state <= IDLE;
            end case;
        end if;
    end process;

end arch_vga_fb_controller;