--CHIP 8 Top level
--REMEMBER: pc_jump_v0_en, v_dout, stack_dout, cmd_n and pix_valid still open

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;
use work.framebuffer_constants.all;
use work.ram_constants.all;

entity chip8_system is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;

        --Keyboard Interface
        key_pressed  : in  std_logic;
        key_value_in : in  std_logic_vector(3 downto 0);

        --VGA Outputs
        vga_r, vga_g, vga_b : out std_logic_vector(7 downto 0);
        vga_hs, vga_vs, vga_sync_n, vga_blank_n : out std_logic
    );
end entity;

architecture rtl of chip8_system is

    --COMPONENT DECLARATIONS
    component control_system is
        port (
            clk, reset : in std_logic;
            opcode     : in std_logic_vector(15 downto 0);
            pc_in      : in std_logic_vector(11 downto 0);
            i_reg_in   : in std_logic_vector(11 downto 0);
            ram_dout   : in std_logic_vector(7 downto 0);
            key_pressed : in std_logic;
            key_value_in: in std_logic_vector(3 downto 0);
            dt_in, st_in : in std_logic_vector(7 downto 0);
            bcd_code    : in std_logic_vector(11 downto 0);
            rand_val    : in std_logic_vector(7 downto 0);

            --Control Outputs
            ram_read_en, ram_write_en, stack_push_en, stack_pop_en : out std_logic;
            ram_addr_out : out std_logic_vector(11 downto 0);
            ram_din      : out std_logic_vector(7 downto 0);
            key_check_en, dt_load_en, st_load_en, video_clear_en, video_draw_en : out std_logic;
            dt_din, st_din : out std_logic_vector(7 downto 0);
            bcd_en, bin_din, font_addr_en : out std_logic;
            pc_load_en, pc_inc_en, pc_skip_en : out std_logic;
            pc_addr_out : out std_logic_vector(11 downto 0);
            reg_read_en, reg_write_en : out std_logic;
            reg_read_addr_x, reg_read_addr_y, reg_write_addr : out std_logic_vector(3 downto 0);
            reg_data : out std_logic_vector(7 downto 0);
            i_load_en, i_inc_en : out std_logic;
            i_data_in : out std_logic_vector(15 downto 0);
            alu_op : out std_logic_vector(5 downto 0)
        );
    end component;

    component registers is
        port (
            clk, reset : in std_logic;
            we_v, we_i, we_dt, we_st : in std_logic;
            pc_load_nnn_en, pc_inc_en, pc_skip_en, pc_ret_en, pc_jump_v0_en : in std_logic;
            nnn_in : in std_logic_vector(11 downto 0);
            v0_data_in : in std_logic_vector(7 downto 0);
            v_addr, v_addr_x, v_addr_y, v_write_addr : in std_logic_vector(3 downto 0);
            v_din : in std_logic_vector(7 downto 0);
            v_dout, v_dout_x, v_dout_y : out std_logic_vector(7 downto 0);
            i_din : in std_logic_vector(11 downto 0);
            i_dout : out std_logic_vector(11 downto 0);
            pc_dout : out std_logic_vector(11 downto 0);
            dt_din : in std_logic_vector(7 downto 0);
            dt_dout : out std_logic_vector(7 downto 0);
            st_din : in std_logic_vector(7 downto 0);
            st_dout : out std_logic_vector(7 downto 0);
            push, pop : in std_logic;
            stack_dout : out std_logic_vector(11 downto 0)
        );
    end component;

    component ram is
        port (
            clk : in std_logic;
            addr : in std_logic_vector(11 downto 0);
            data_in : in std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            we, re : in std_logic
        );
    end component;

    component alu is
        port (
            op_sel : in std_logic_vector(5 downto 0);
            vx, vy : in std_logic_vector(7 downto 0);
            result : out std_logic_vector(7 downto 0)
        );
    end component;

    component vga_system is
        port (
            clk, reset : in std_logic;
            ram_addr_b : out std_logic_vector(11 downto 0);
            ram_dout_b : in std_logic_vector(7 downto 0);
            ram_req_a, ram_we_a : out std_logic;
            ram_addr_a : out std_logic_vector(11 downto 0);
            ram_din_a : out std_logic_vector(7 downto 0);
            ram_dout_a : in std_logic_vector(7 downto 0);
            op_code_in : in std_logic_vector(5 downto 0);
            cmd_valid  : in std_logic;
            cmd_x      : in std_logic_vector(5 downto 0);
            cmd_y      : in std_logic_vector(4 downto 0);
            cmd_i_reg  : in std_logic_vector(11 downto 0);
            cmd_n      : in std_logic_vector(3 downto 0);
            cmd_ack, cmd_done, collision : out std_logic;
            r, g, b : out std_logic_vector(7 downto 0);
            pix_valid, h_sync, v_sync, sync_n, blank_n : out std_logic
        );
    end component;

    component bcd_convert is
        port (
            bin_in  : in std_logic_vector(7 downto 0);
            bcd_out : out std_logic_vector(11 downto 0)
        );
    end component;

    component rand_generate is
        port (
            clk   : in std_logic;
            reset : in std_logic;
            rand_out : out std_logic_vector(7 downto 0)
        );
    end component;

    --Internal signals
    signal pc_s, i_s           : std_logic_vector(11 downto 0);
    signal opcode_s            : std_logic_vector(15 downto 0);
    signal ram_dout_s, ram_din_s : std_logic_vector(7 downto 0);
    signal alu_res_s           : std_logic_vector(7 downto 0);
    signal bcd_s               : std_logic_vector(11 downto 0);
    signal rand_val_s          : std_logic_vector(7 downto 0);

    --Registers <-> ALU signals
    signal reg_x_s, reg_y_s    : std_logic_vector(7 downto 0);
    signal alu_op_s            : std_logic_vector(5 downto 0);

    --Control signals
    signal ram_read_en_s, ram_write_en_s : std_logic;
    signal stack_push_en_s, stack_pop_en_s : std_logic;
    signal key_check_en_s, dt_load_en_s, st_load_en_s : std_logic;
    signal video_clear_en_s, video_draw_en_s : std_logic;
    signal dt_din_s, st_din_s : std_logic_vector(7 downto 0);
    signal bcd_en_s, bin_din_s, font_addr_en_s : std_logic;
    signal pc_load_en_s, pc_inc_en_s, pc_skip_en_s : std_logic;
    signal pc_addr_out_s : std_logic_vector(11 downto 0);
    signal reg_read_en_s, reg_write_en_s : std_logic;
    signal reg_read_addr_x_s, reg_read_addr_y_s, reg_write_addr_s : std_logic_vector(3 downto 0);
    signal reg_data_s : std_logic_vector(7 downto 0);
    signal i_load_en_s, i_inc_en_s : std_logic;
    signal i_data_in_s : std_logic_vector(11 downto 0);

    --VGA signals
    signal vga_collision_s, vga_cmd_done_s, vga_cmd_ack_s : std_logic;

begin

    --CONTROL UNIT
    u_control : control_system
        port map (
            clk => clk,
            reset => reset,
            opcode => opcode_s,
            pc_in => pc_s,
            i_reg_in => i_s,
            ram_dout => ram_dout_s,
            key_pressed => key_pressed,
            key_value_in => key_value_in,
            dt_in => dt_din_s, st_in => st_din_s,
            bcd_code => bcd_s,
            rand_val => rand_val_s,

            --outputs connected to other modules
            ram_read_en => ram_read_en_s,
            ram_write_en => ram_write_en_s,
            ram_addr_out => pc_addr_out_s,
            ram_din => ram_din_s,
            stack_push_en => stack_push_en_s,
            stack_pop_en => stack_pop_en_s,
            key_check_en => key_check_en_s,
            dt_load_en => dt_load_en_s,
            st_load_en => st_load_en_s,
            video_clear_en => video_clear_en_s,
            video_draw_en => video_draw_en_s,
            dt_din => dt_din_s,
            st_din => st_din_s,
            bcd_en => bcd_en_s,
            bin_din => bin_din_s,
            font_addr_en => font_addr_en_s,
            pc_load_en => pc_load_en_s,
            pc_inc_en => pc_inc_en_s,
            pc_skip_en => pc_skip_en_s,
            pc_addr_out => pc_addr_out_s,
            reg_read_en => reg_read_en_s,
            reg_write_en => reg_write_en_s,
            reg_read_addr_x => reg_read_addr_x_s,
            reg_read_addr_y => reg_read_addr_y_s,
            reg_write_addr => reg_write_addr_s,
            reg_data => reg_data_s,
            i_load_en => i_load_en_s,
            i_inc_en => i_inc_en_s,
            i_data_in => i_data_in_s,
            alu_op => alu_op_s
        );

    --REGISTERS
    u_regs : registers
        port map (
            clk => clk,
            reset => reset,
            we_v => reg_write_en_s,
            we_i => i_load_en_s,
            we_dt => dt_load_en_s,
            we_st => st_load_en_s,
            pc_load_nnn_en => pc_load_en_s,
            pc_inc_en => pc_inc_en_s,
            pc_skip_en => pc_skip_en_s,
            pc_ret_en => stack_pop_en_s,
            pc_jump_v0_en => open,
            nnn_in => pc_addr_out_s,
            v0_data_in => reg_data_s,
            v_addr => reg_write_addr_s,
            v_addr_x => reg_read_addr_x_s,
            v_addr_y => reg_read_addr_y_s,
            v_write_addr => reg_write_addr_s,
            v_din => reg_data_s,
            v_dout => open,
            v_dout_x => reg_x_s,
            v_dout_y => reg_y_s,
            i_din => i_data_in_s,
            i_dout => i_s,
            pc_dout => pc_s,
            dt_din => dt_din_s,
            dt_dout => dt_din_s,
            st_din => st_din_s,
            st_dout => st_din_s,
            push => stack_push_en_s,
            pop => stack_pop_en_s,
            stack_dout => open
        );

    --ALU
    u_alu : alu
        port map (
            op_sel => alu_op_s,
            vx => reg_x_s,
            vy => reg_y_s,
            result => alu_res_s
        );

    --RANDOM GENERATOR
    u_rand : rand_generate
        port map (
            clk => clk,
            reset => reset,
            rand_out => rand_val_s
        );

    --BCD CONVERTER
    u_bcd : bcd_convert
        port map (
            bin_in  => reg_x_s,
            bcd_out => bcd_s
        );

    --VGA SYSTEM (FRAMEBUFFER)
    u_vga : vga_system
        port map (
            clk => clk,
            reset => reset,
            ram_addr_b => pc_addr_out_s,
            ram_dout_b => ram_dout_s,
            ram_req_a => video_draw_en_s,
            ram_we_a => ram_write_en_s,
            ram_addr_a => pc_addr_out_s,
            ram_din_a => ram_din_s,
            ram_dout_a => ram_dout_s,
            op_code_in => alu_op_s,
            cmd_valid => video_draw_en_s,
            cmd_x => reg_x_s(5 downto 0),
            cmd_y => reg_y_s(4 downto 0),
            cmd_i_reg => i_s,
            cmd_n => open,
            cmd_ack => vga_cmd_ack_s,
            cmd_done => vga_cmd_done_s,
            collision => vga_collision_s,
            r => vga_r,
            g => vga_g,
            b => vga_b,
            pix_valid => open,
            h_sync => vga_hs,
            v_sync => vga_vs,
            sync_n => vga_sync_n,
            blank_n => vga_blank_n
        );

end rtl;