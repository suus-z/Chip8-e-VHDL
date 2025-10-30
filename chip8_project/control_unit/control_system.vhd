--Control Unit of CHIP 8
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;

entity control_system is
    port (
        --System Signals
        clk          : in  std_logic;
        reset        : in  std_logic;

        --Instruction Input
        opcode       : in  std_logic_vector(15 downto 0);

        --Inputs from Chip-8 Core
        pc_in        : in  std_logic_vector(11 downto 0);
        i_reg_in     : in  std_logic_vector(11 downto 0);
        ram_dout     : in  std_logic_vector(7 downto 0);
        key_pressed  : in  std_logic;
        key_value_in : in  std_logic_vector(3 downto 0);
        dt_in        : in  std_logic_vector(7 downto 0);
        st_in        : in  std_logic_vector(7 downto 0);
        bcd_code     : in  std_logic_vector(11 downto 0);
        rand_val     : in  std_logic_vector(7 downto 0);

        --Outputs (Control Signals)
        ram_read_en     : out std_logic;
        ram_write_en    : out std_logic;
        ram_addr_out    : out std_logic_vector(11 downto 0);
        ram_din         : out std_logic_vector(7 downto 0);

        stack_push_en   : out std_logic;
        stack_pop_en    : out std_logic;

        key_check_en    : out std_logic;

        dt_load_en      : out std_logic;
        dt_din          : out std_logic_vector(7 downto 0);
        st_load_en      : out std_logic;
        st_din          : out std_logic_vector(7 downto 0);

        video_clear_en  : out std_logic;
        video_draw_en   : out std_logic;

        bcd_en          : out std_logic;
        bin_din         : out std_logic;
        font_addr_en    : out std_logic;

        pc_load_en      : out std_logic;
        pc_inc_en       : out std_logic;
        pc_skip_en      : out std_logic;
        pc_addr_out     : out std_logic_vector(11 downto 0);

        reg_read_en     : out std_logic;
        reg_write_en    : out std_logic;
        reg_read_addr_x : out std_logic_vector(3 downto 0);
        reg_read_addr_y : out std_logic_vector(3 downto 0);
        reg_write_addr  : out std_logic_vector(3 downto 0);
        reg_data        : out std_logic_vector(7 downto 0);

        i_load_en       : out std_logic;
        i_data_in       : out std_logic_vector(15 downto 0);
        i_inc_en        : out std_logic;

        alu_op          : out std_logic_vector(5 downto 0)
    );
end control_system;

architecture rtl of control_system is

    --Component Declarations
    component decoder is
        port(
            opcode  : in  std_logic_vector(15 downto 0);
            nnn     : out std_logic_vector(11 downto 0);
            kk      : out std_logic_vector(7 downto 0);
            x       : out std_logic_vector(3 downto 0);
            y       : out std_logic_vector(3 downto 0);
            n       : out std_logic_vector(3 downto 0);
            instr   : out std_logic_vector(5 downto 0);
            illegal : out std_logic
        );
    end component;

    component control_fsm is
        port (
            clk           : in  std_logic;
            reset         : in  std_logic;

            --From chip-8
            pc_in         : in  std_logic_vector(11 downto 0);
            i_reg_in      : in  std_logic_vector(11 downto 0);
            ram_dout      : in  std_logic_vector(7 downto 0);
            key_pressed   : in  std_logic;
            key_value_in  : in  std_logic_vector(3 downto 0);
            dt_in         : in  std_logic_vector(7 downto 0);
            st_in         : in  std_logic_vector(7 downto 0);
            bcd_code      : in  std_logic_vector(11 downto 0);
            rand_val      : in  std_logic_vector(7 downto 0);

            --From decoder
            instr_code    : in  std_logic_vector(5 downto 0);
            nnn           : in  std_logic_vector(11 downto 0);
            kk            : in  std_logic_vector(7 downto 0);
            x             : in  std_logic_vector(3 downto 0);
            y             : in  std_logic_vector(3 downto 0);
            n             : in  std_logic_vector(3 downto 0);
            illegal_instr : in  std_logic;

            --Control Outputs
            ram_read_en     : out std_logic;
            ram_write_en    : out std_logic;
            ram_addr_out    : out std_logic_vector(11 downto 0);
            ram_din         : out std_logic_vector(7 downto 0);

            stack_push_en   : out std_logic;
            stack_pop_en    : out std_logic;

            key_check_en    : out std_logic;

            dt_load_en      : out std_logic;
            dt_din          : out std_logic_vector(7 downto 0);
            st_load_en      : out std_logic;
            st_din          : out std_logic_vector(7 downto 0);

            video_clear_en  : out std_logic;
            video_draw_en   : out std_logic;

            bcd_en          : out std_logic;
            bin_din         : out std_logic;
            font_addr_en    : out std_logic;

            pc_load_en      : out std_logic;
            pc_inc_en       : out std_logic;
            pc_skip_en      : out std_logic;
            pc_addr_out     : out std_logic_vector(11 downto 0);

            reg_read_en     : out std_logic;
            reg_write_en    : out std_logic;
            reg_read_addr_x : out std_logic_vector(3 downto 0);
            reg_read_addr_y : out std_logic_vector(3 downto 0);
            reg_write_addr  : out std_logic_vector(3 downto 0);
            reg_data        : out std_logic_vector(7 downto 0);

            i_load_en       : out std_logic;
            i_data_in       : out std_logic_vector(15 downto 0);
            i_inc_en        : out std_logic;

            alu_op          : out std_logic_vector(5 downto 0)
        );
    end component;

    --Internal Signals
    signal s_nnn        : std_logic_vector(11 downto 0);
    signal s_kk         : std_logic_vector(7 downto 0);
    signal s_x          : std_logic_vector(3 downto 0);
    signal s_y          : std_logic_vector(3 downto 0);
    signal s_n          : std_logic_vector(3 downto 0);
    signal s_instr_code : std_logic_vector(5 downto 0);
    signal s_illegal    : std_logic;

begin
    --Instruction Decoder
    u_decoder : decoder
        port map (
            opcode  => opcode,
            nnn     => s_nnn,
            kk      => s_kk,
            x       => s_x,
            y       => s_y,
            n       => s_n,
            instr   => s_instr_code,
            illegal => s_illegal
        );

    --Control FSM
    u_fsm : control_fsm
        port map (
            clk           => clk,
            reset         => reset,

            pc_in         => pc_in,
            i_reg_in      => i_reg_in,
            ram_dout      => ram_dout,
            key_pressed   => key_pressed,
            key_value_in  => key_value_in,
            dt_in         => dt_in,
            st_in         => st_in,
            bcd_code      => bcd_code,
            rand_val      => rand_val,

            instr_code    => s_instr_code,
            nnn           => s_nnn,
            kk            => s_kk,
            x             => s_x,
            y             => s_y,
            n             => s_n,
            illegal_instr => s_illegal,

            ram_read_en     => ram_read_en,
            ram_write_en    => ram_write_en,
            ram_addr_out    => ram_addr_out,
            ram_din         => ram_din,

            stack_push_en   => stack_push_en,
            stack_pop_en    => stack_pop_en,

            key_check_en    => key_check_en,

            dt_load_en      => dt_load_en,
            dt_din          => dt_din,
            st_load_en      => st_load_en,
            st_din          => st_din,

            video_clear_en  => video_clear_en,
            video_draw_en   => video_draw_en,

            bcd_en          => bcd_en,
            bin_din         => bin_din,
            font_addr_en    => font_addr_en,

            pc_load_en      => pc_load_en,
            pc_inc_en       => pc_inc_en,
            pc_skip_en      => pc_skip_en,
            pc_addr_out     => pc_addr_out,

            reg_read_en     => reg_read_en,
            reg_write_en    => reg_write_en,
            reg_read_addr_x => reg_read_addr_x,
            reg_read_addr_y => reg_read_addr_y,
            reg_write_addr  => reg_write_addr,
            reg_data        => reg_data,

            i_load_en       => i_load_en,
            i_data_in       => i_data_in,
            i_inc_en        => i_inc_en,

            alu_op          => alu_op
        );
end rtl;