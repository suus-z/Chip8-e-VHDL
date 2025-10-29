-- CHIP-8 Framebuffer + VGA Scaling
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.framebuffer_constants.all;
use work.instructions_constants.all;

entity scale_framebuffer is
    port (
        reset        : in  std_logic;
        pix_clk      : in  std_logic;
        disp_en      : in  std_logic;

        --VGA outputs
        r, g, b      : out std_logic_vector(7 downto 0);
        pix_valid    : out std_logic;

        --Handshake with control unit
        op_code_in   : in  std_logic_vector(5 downto 0);
        cmd_valid    : in  std_logic;
        cmd_x        : in  std_logic_vector(5 downto 0);
        cmd_y        : in  std_logic_vector(4 downto 0);
        cmd_n        : in  std_logic_vector(3 downto 0); --sprite height
        cmd_ack      : out std_logic;
        cmd_done     : out std_logic;
        collision    : out std_logic;

        --FIFO dual-clock (control unit to framebuffer)
        fifo_wr_clk  : in  std_logic;
        fifo_wr_en   : in  std_logic;
        fifo_wr_data : in  std_logic_vector(7 downto 0);
        fifo_full    : out std_logic;
        fifo_empty   : out std_logic
    );
end scale_framebuffer;

architecture arch_scale_FB of scale_framebuffer is

    --FIFO dual-clock
    type fifo_type is array (0 to 15) of std_logic_vector(7 downto 0);
    signal fifo_mem  : fifo_type;
    signal wr_ptr    : unsigned(3 downto 0) := (others => '0');
    signal rd_ptr    : unsigned(3 downto 0) := (others => '0');
    signal fifo_cnt  : unsigned(4 downto 0) := (others => '0');

    signal fifo_wr_sync : std_logic;
    signal fifo_rd_sync : std_logic;
    signal fifo_dout    : std_logic_vector(7 downto 0);

    --Framebuffer
    type framebuffer_type is array (0 to 31, 0 to 63) of std_logic;
    signal framebuffer : framebuffer_type := (others => (others => '0'));

    --FSM states
    type state_type is (IDLE, CLEAR, DRAW, DONE);
    signal state : state_type := IDLE;

    --Control signals
    signal x_reg, y_reg : unsigned(5 downto 0);
    signal n_reg        : unsigned(3 downto 0);
    signal line_idx     : unsigned(3 downto 0);
    signal col_flag     : std_logic := '0';

    signal cmd_latched  : std_logic := '0';
    signal cmd_reg_type : std_logic_vector(1 downto 0);

    --VGA Scan
    signal chip8_x : unsigned(5 downto 0) := (others => '0');
    signal chip8_y : unsigned(4 downto 0) := (others => '0');
    signal rgb_int : std_logic_vector(23 downto 0);

begin

    --FIFO
    process(fifo_wr_clk)
    begin
        if rising_edge(fifo_wr_clk) then
            if fifo_wr_en = '1' and fifo_cnt < 16 then
                fifo_mem(to_integer(wr_ptr)) <= fifo_wr_data;
                wr_ptr <= wr_ptr + 1;
                fifo_cnt <= fifo_cnt + 1;
            end if;
        end if;
    end process;

    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            if (state = DRAW and fifo_cnt > 0) then
                fifo_dout <= fifo_mem(to_integer(rd_ptr));
                rd_ptr <= rd_ptr + 1;
                fifo_cnt <= fifo_cnt - 1;
            end if;
        end if;
    end process;

    fifo_empty <= '1' when fifo_cnt = 0 else '0';
    fifo_full  <= '1' when fifo_cnt = 16 else '0';

    --FSM
    process(pix_clk, reset)
        variable px, py : integer;
    begin
        if reset = '0' then
            state <= IDLE;
            cmd_ack <= '0';
            cmd_done <= '0';
            col_flag <= '0';
        elsif rising_edge(pix_clk) then
            cmd_ack <= '0';
            cmd_done <= '0';

            case state is

                when IDLE =>
                    if cmd_valid = '1' then
                        cmd_ack <= '1';
                        cmd_reg_type <= op_code_in;

                        if op_code_in = I_CLS then  --CLS
                            state <= CLEAR;
                            x_reg <= (others => '0');
                            y_reg <= (others => '0');

                        elsif op_code_in = I_DRW then  --DRW
                            x_reg <= unsigned(cmd_x);
                            y_reg <= unsigned(cmd_y);
                            n_reg <= unsigned(cmd_n);
                            line_idx <= (others => '0');
                            col_flag <= '0';
                            state <= DRAW;

                        else state <= IDLE;
                        end if;
                    end if;

                when CLEAR =>
                    framebuffer(to_integer(y_reg), to_integer(x_reg)) <= '0';
                    if x_reg = 63 then
                        x_reg <= (others => '0');
                        if y_reg = 31 then
                            state <= DONE;
                        else
                            y_reg <= y_reg + 1;
                        end if;
                    else
                        x_reg <= x_reg + 1;
                    end if;

                when DRAW =>
                    if fifo_cnt > 0 then
                        for bit_idx in 0 to 7 loop
                            if fifo_dout(7 - bit_idx) = '1' then
                                px := (to_integer(x_reg) + bit_idx) mod 64;
                                py := (to_integer(y_reg) + to_integer(line_idx)) mod 32;

                                if framebuffer(py, px) = '1' then
                                    col_flag <= '1';
                                end if;
                                framebuffer(py, px) <= framebuffer(py, px) xor '1';
                            end if;
                        end loop;

                        if line_idx = n_reg - 1 then
                            state <= DONE;
                        else
                            line_idx <= line_idx + 1;
                        end if;
                    end if;

                when DONE =>
                    cmd_done <= '1';
                    collision <= col_flag;
                    state <= IDLE;

            end case;
        end if;
    end process;

    --VGA
    process(pix_clk, reset)
        variable cur_x : integer;
        variable cur_y : integer;
    begin
        if reset = '0' then
            rgb_int <= (others => '0');
            pix_valid <= '0';
        elsif rising_edge(pix_clk) then
            if disp_en = '1' then
                cur_x := to_integer(chip8_x);
                cur_y := to_integer(chip8_y);

                if framebuffer(cur_y, cur_x) = '1' then
                    rgb_int <= (others => '1');
                else
                    rgb_int <= (others => '0');
                end if;
                pix_valid <= '1';
            else
                rgb_int <= (others => '0');
                pix_valid <= '0';
            end if;
        end if;
    end process;

    r <= rgb_int(23 downto 16);
    g <= rgb_int(15 downto 8);
    b <= rgb_int(7 downto 0);

end arch_scale_FB;