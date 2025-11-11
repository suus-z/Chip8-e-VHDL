library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;
use work.framebuffer_constants.all;
use work.ram_constants.all;

entity chip8_top is
    port(
        clk     : in std_logic;
        reset   : in std_logic;

        --Keyboard Interface
        row_pins         : in  std_logic_vector(3 downto 0);
        column_pins      : out std_logic_vector(3 downto 0);

        --VGA Interface
        vga_r, vga_g, vga_b  : out std_logic_vector(7 downto 0);
        vga_hs, vga_vs, vga_sync_n, vga_blank_n : out std_logic
    );
end chip8_top;

architecture rtl of chip8_top is
    component control_system is
    port (
        --System Signals
        clk          : in  std_logic;
        reset        : in  std_logic;

        --Instruction Input
        opcode       : in  std_logic_vector(15 downto 0);

        --Inputs from Chip-8 Core
        pc_in         : in  std_logic_vector(11 downto 0);
        i_reg_in      : in  std_logic_vector(11 downto 0);
        ram_dout      : in  std_logic_vector(7 downto 0);
        key_pressed   : in  std_logic;
        key_value_in  : in  std_logic_vector(3 downto 0);
        dt_in         : in  std_logic_vector(7 downto 0);
        st_in         : in  std_logic_vector(7 downto 0);
        bcd_code      : in  std_logic_vector(11 downto 0);
        rand_val      : in  std_logic_vector(7 downto 0);
        alu_result_in : in std_logic_vector(7 downto 0);  
        alu_i_add_in  : in std_logic_vector(11 downto 0); 
        vf_flag_in    : in std_logic;
        cmd_ack       : in  std_logic;
        cmd_done      : in  std_logic;
        collision     : in  std_logic;

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

        bin_din         : out std_logic_vector(7 downto 0);

        pc_load_en      : out std_logic;
        pc_inc_en       : out std_logic;
        pc_skip_en      : out std_logic;
        pc_addr_out     : out std_logic_vector(11 downto 0);
        pc_ret_en       : out std_logic;
        pc_jump_v0_en   : out std_logic;

        reg_read_en     : out std_logic;
        reg_write_en    : out std_logic;
        reg_read_addr_x : out std_logic_vector(3 downto 0);
        reg_read_addr_y : out std_logic_vector(3 downto 0);
        reg_write_addr  : out std_logic_vector(3 downto 0);
        reg_data        : out std_logic_vector(7 downto 0);

        i_load_en       : out std_logic;
        i_data_in       : out std_logic_vector(11 downto 0);
        i_inc_en        : out std_logic;

        alu_op          : out std_logic_vector(5 downto 0);

        latch_msb_en    : out std_logic
    );
    end component control_system;

    component vga_system is
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        clk_25  : out std_logic;
        
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
    end component vga_system;

    component ram is
    generic (
        data_width : integer := 8;
        addr_width : integer := 12
    );

    port (
        --A port
        clk_a  : in std_logic;
        we     : in std_logic;
        addr_a : in std_logic_vector(addr_width - 1 downto 0);
        din    : in std_logic_vector(data_width - 1 downto 0);
        dout_a : out std_logic_vector(data_width - 1 downto 0);

        --B port
        clk_b  : in std_logic;
        addr_b : in std_logic_vector(addr_width - 1 downto 0);
        dout_b : out std_logic_vector(data_width - 1 downto 0)
    );
    end component ram;

    component registers is
    port(
        clk     : in std_logic;
        reset   : in std_logic;

        --Write Control
        we_v    : in std_logic;
        we_i    : in std_logic;
        we_dt   : in std_logic;
        we_st   : in std_logic;

        --PC CONTROL INPUTS
        pc_load_nnn_en : in std_logic;
        pc_inc_en      : in std_logic;
        pc_skip_en     : in std_logic;
        pc_ret_en      : in std_logic;
        pc_jump_v0_en  : in std_logic;

        nnn_in         : in std_logic_vector(11 downto 0);
        v0_data_in     : in std_logic_vector(7 downto 0);

        --V registers control
        v_addr  : in std_logic_vector(3 downto 0);
        v_din   : in std_logic_vector(7 downto 0);
        v_dout  : out std_logic_vector(7 downto 0);
        v_addr_x : in std_logic_vector(3 downto 0);
        v_dout_x : out std_logic_vector(7 downto 0);
        v_addr_y : in std_logic_vector(3 downto 0);
        v_dout_y : out std_logic_vector(7 downto 0);

        --I register control
        i_din   : in std_logic_vector(11 downto 0);
        i_dout  : out std_logic_vector(11 downto 0);

        --PC (program counter)
        pc_dout  : out std_logic_vector(11 downto 0);

        --DT (delay timer)
        dt_din   : in std_logic_vector(7 downto 0);
        dt_dout  : out std_logic_vector(7 downto 0);

        --ST (sound timer)
        st_din   : in std_logic_vector(7 downto 0);
        st_dout  : out std_logic_vector(7 downto 0);

        --Stack functions
        push     : in std_logic;
        pop      : in std_logic;
        stack_dout : out std_logic_vector(11 downto 0)
    );
    end component registers;

    component bcd_convert is
    generic (
        BIN_WIDTH  : integer := 8;
        NUM_DIGITS : integer := 3
    );
    port (
        bin_din     : in  std_logic_vector(BIN_WIDTH-1 downto 0);
        bcd_code    : out std_logic_vector(NUM_DIGITS*4-1 downto 0)
    );
    end component bcd_convert;

    component rand_generate is
    generic (LFSR_WIDTH  : integer := 8);

    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        rand_val  : out std_logic_vector(LFSR_WIDTH-1 downto 0)
    );
    end component rand_generate;

    component chip8_alu is
    port (
        -- Inputs
        op_code_in : in  std_logic_vector(5 downto 0); --The 6-bit opcode from the instruction
        data_a_in  : in  std_logic_vector(7 downto 0); --First operand (e.g., Vx)
        data_b_in  : in  std_logic_vector(7 downto 0); --Second operand (e.g., Vy or kk)
        i_reg_in   : in  std_logic_vector(11 downto 0); --Actual value of I register
        
        -- Outputs
        result_out : out std_logic_vector(7 downto 0);  --Result of the operation
        vf_flag    : out std_logic;                     --The VF (carry/borrow) flag
        i_add_out  : out std_logic_vector(11 downto 0)  --Result for the I_ADD_I_Vx instruction
    );
    end component chip8_alu;

    component keyboard is
    port(
        clk       : in   std_logic;
        reset     : in   std_logic;
        row       : in   std_logic_vector(3 downto 0);
        column    : out  std_logic_vector(3 downto 0);
        key_code  : out  std_logic_vector(3 downto 0);
        key_valid : out  std_logic
    );
    end component keyboard;


    signal latch_msb_en_s : std_logic;
    signal opcode_msb_s   : std_logic_vector(7 downto 0);

    --RAM
    signal opcode_s       : std_logic_vector(15 downto 0);
    signal ram_dout_a_s   : std_logic_vector(7 downto 0);
    signal ram_dout_b_s   : std_logic_vector(7 downto 0);
    signal ram_addr_a_s   : std_logic_vector(11 downto 0);
    signal ram_addr_b_s   : std_logic_vector(11 downto 0);
    signal ram_din_s      : std_logic_vector(7 downto 0);
    signal ram_din_ctrl_s : std_logic_vector(7 downto 0);
    signal ram_addr_ctrl_s : std_logic_vector(11 downto 0);
    signal ram_read_en_s  : std_logic;
    signal ram_write_en_s : std_logic;
    signal clk_25_s       : std_logic; --Pixel clock
    signal ram_we_s       : std_logic;
    signal ram_req_a_vga_s  : std_logic;
    signal ram_we_a_vga_s   : std_logic;
    signal ram_addr_a_vga_s : std_logic_vector(11 downto 0);
    signal ram_din_a_vga_s  : std_logic_vector(7 downto 0);
    
    --Registers
    --PC
    signal pc_s               : std_logic_vector(11 downto 0);
    signal pc_load_en_s       : std_logic;
    signal pc_inc_en_s        : std_logic;
    signal pc_skip_en_s       : std_logic;
    signal pc_ret_en_s        : std_logic;
    signal pc_jump_v0_en_s    : std_logic;
    --Stack
    signal stack_push_en_s    : std_logic;
    signal stack_pop_en_s     : std_logic;
    signal key_check_en_s     : std_logic;
    signal dt_load_en_s       : std_logic;
    signal dt_din_s           : std_logic_vector(7 downto 0);
    signal st_load_en_s       : std_logic;
    signal st_din_s           : std_logic_vector(7 downto 0);
    signal stack_dout_s       : std_logic_vector(11 downto 0);
    --V reg
    signal vreg_read_en_s     : std_logic;
    signal vreg_write_en_s    : std_logic;
    signal vreg_read_addr_x_s : std_logic_vector(3 downto 0);
    signal vreg_read_addr_y_s : std_logic_vector(3 downto 0);
    signal vreg_write_addr_s  : std_logic_vector(3 downto 0);
    signal vreg_data_s        : std_logic_vector(7 downto 0);
    signal v_dout_s           : std_logic_vector(7 downto 0);
    signal v_dout_x_s         : std_logic_vector(7 downto 0);
    signal v_dout_y_s         : std_logic_vector(7 downto 0);
    --I reg
    signal i_data_in_s        : std_logic_vector(11 downto 0);
    signal i_load_en_s        : std_logic;
    signal i_inc_en_s         : std_logic;
    signal we_i_s             : std_logic;
    signal nnn_s              : std_logic_vector(11 downto 0);
    signal i_dout_s           : std_logic_vector(11 downto 0);
    --Timers
    signal dt_dout_s          : std_logic_vector(7 downto 0);
    signal st_dout_s          : std_logic_vector(7 downto 0);
    
    --ALU
    signal bcd_code_s        : std_logic_vector(11 downto 0);
    signal rand_val_s        : std_logic_vector(7 downto 0);
    signal bin_din_s         : std_logic_vector(7 downto 0);
    signal alu_op_s          : std_logic_vector(5 downto 0);
    signal vf_flag_s         : std_logic;
    signal i_add_s           : std_logic_vector(11 downto 0);
    signal alu_out_s         : std_logic_vector(7 downto 0);

    --Video
    signal video_clear_en_s  : std_logic;
    signal video_draw_en_s   : std_logic;
    signal cmd_ack_s         : std_logic;
    signal cmd_done_s        : std_logic;
    signal collision_s         : std_logic;

    --Keyboard
    signal key_pressed_s     : std_logic;
    signal key_value_in_s    : std_logic_vector(3 downto 0);
    
begin
    we_i_s       <= i_load_en_s or i_inc_en_s;
    ram_addr_a_s <= ram_addr_a_vga_s when ram_req_a_vga_s = '1' else ram_addr_ctrl_s;
    ram_we_s     <= ram_we_a_vga_s   when ram_req_a_vga_s = '1' else ram_write_en_s;
    ram_din_s    <= ram_din_a_vga_s  when ram_req_a_vga_s = '1' else ram_din_ctrl_s;

    process(clk, reset)
    begin
        if reset = '0' then
            opcode_msb_s <= (others => '0');
        elsif rising_edge(clk) then
            if latch_msb_en_s = '1' then
                opcode_msb_s <= ram_dout_a_s;
            end if;
        end if;
    end process;

    opcode_s <= opcode_msb_s & ram_dout_a_s;

    u_ram: ram
        port map (
            clk_a  => clk,
            we     => ram_write_en_s,
            addr_a => ram_addr_a_s,
            din    => ram_din_s,
            dout_a => ram_dout_a_s,
            clk_b  => clk_25_s,
            addr_b => ram_addr_b_s,
            dout_b => ram_dout_b_s
        );

    u_registers: registers
        port map (
            clk            => clk,
            reset          => reset,
            we_v           => vreg_write_en_s,
            we_i           => we_i_s,
            we_dt          => dt_load_en_s,
            we_st          => st_load_en_s,
            pc_load_nnn_en => pc_load_en_s,
            pc_inc_en      => pc_inc_en_s,
            pc_skip_en     => pc_skip_en_s,
            pc_ret_en      => pc_ret_en_s,
            pc_jump_v0_en  => pc_jump_v0_en_s,
            nnn_in         => nnn_s,
            v0_data_in     => v_dout_s,
            v_addr         => vreg_write_addr_s,
            v_addr_x       => vreg_read_addr_x_s,
            v_addr_y       => vreg_read_addr_y_s,
            v_din          => vreg_data_s,
            v_dout         => v_dout_s,
            v_dout_x       => v_dout_x_s,
            v_dout_y       => v_dout_y_s,
            i_din          => i_data_in_s,
            i_dout         => i_dout_s,
            pc_dout        => pc_s,
            dt_din         => dt_din_s,
            dt_dout        => dt_dout_s,
            st_din         => st_din_s,
            st_dout        => st_dout_s,
            push           => stack_push_en_s,
            pop            => stack_pop_en_s,
            stack_dout     => stack_dout_s
        );

    u_control_system: control_system
        port map (
            clk             => clk,
            reset           => reset,
            opcode          => opcode_s,
            pc_in           => pc_s,
            i_reg_in        => i_dout_s,
            ram_dout        => ram_dout_a_s,
            key_pressed     => key_pressed_s,
            key_value_in    => key_value_in_s,
            dt_in           => dt_dout_s, 
            st_in           => st_dout_s,
            bcd_code        => bcd_code_s,
            rand_val        => rand_val_s,
            alu_result_in   => alu_out_s,
            alu_i_add_in    => i_add_s,
            vf_flag_in      => vf_flag_s,
            cmd_ack         => cmd_ack_s,
            cmd_done        => cmd_done_s,
            collision       => collision_s,
            ram_read_en     => ram_read_en_s,
            ram_write_en    => ram_write_en_s,
            ram_addr_out    => ram_addr_ctrl_s,
            ram_din         => ram_din_ctrl_s,
            stack_push_en   => stack_push_en_s,
            stack_pop_en    => stack_pop_en_s,
            key_check_en    => key_check_en_s,
            dt_load_en      => dt_load_en_s,
            st_load_en      => st_load_en_s,
            video_clear_en  => video_clear_en_s,
            video_draw_en   => video_draw_en_s,
            dt_din          => dt_din_s,
            st_din          => st_din_s,
            bin_din         => bin_din_s,
            pc_load_en      => pc_load_en_s,
            pc_inc_en       => pc_inc_en_s,
            pc_skip_en      => pc_skip_en_s,
            pc_addr_out     => nnn_s,
            pc_ret_en       => pc_ret_en_s,
            pc_jump_v0_en   => pc_jump_v0_en_s,
            reg_read_en     => vreg_read_en_s,
            reg_write_en    => vreg_write_en_s,
            reg_read_addr_x => vreg_read_addr_x_s,
            reg_read_addr_y => vreg_read_addr_y_s,
            reg_write_addr  => vreg_write_addr_s,
            reg_data        => vreg_data_s,
            i_load_en       => i_load_en_s,
            i_inc_en        => i_inc_en_s,
            i_data_in       => i_data_in_s,
            alu_op          => alu_op_s,
            latch_msb_en    => latch_msb_en_s
        );

    u_vga_system: vga_system
        port map (
            clk             => clk,
            reset           => reset,
            clk_25           => clk_25_s,
            ram_addr_b      => ram_addr_b_s,
            ram_dout_b      => ram_dout_b_s,
            ram_req_a       => ram_req_a_vga_s,
            ram_we_a        => ram_we_a_vga_s,
            ram_addr_a      => ram_addr_a_s,
            ram_din_a       => ram_din_a_vga_s,
            ram_dout_a      => ram_dout_a_s,
            op_code_in      => opcode_s,
            cmd_valid       => video_draw_en_s,
            cmd_x           => v_dout_x_s(5 downto 0),
            cmd_y           => v_dout_y_s(4 downto 0),
            cmd_i_reg       => i_dout_s,
            cmd_n           => opcode_s(3 downto 0),
            cmd_ack         => cmd_ack_s,
            cmd_done        => cmd_done_s,
            collision       => collision_s,
            r               => vga_r,
            g               => vga_g,
            b               => vga_b,
            h_sync          => vga_hs,
            v_sync          => vga_vs,
            sync_n          => vga_sync_n,
            blank_n         => vga_blank_n
        );

    u_bcd: bcd_convert
        port map (
            bin_din  => bin_din_s,
            bcd_code => bcd_code_s
        );

    u_rand: rand_generate
        port map (
            clk      => clk,
            reset    => reset,
            rand_val => rand_val_s
        );

    u_alu: chip8_alu
        port map(
            op_code_in => alu_op_s,
            data_a_in  => v_dout_x_s,
            data_b_in  => v_dout_y_s,
            i_reg_in   => i_dout_s,
            result_out => alu_out_s,
            vf_flag    => vf_flag_s,
            i_add_out  => i_add_s
        );

    u_keyboard: keyboard
        port map (
            clk => clk,
            reset => reset,
            row => row_pins,
            column => column_pins,
            key_code => key_value_in_s,
            key_valid => key_check_en_s
        );
end rtl;