--FSM of control unit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;

entity control_fsm is
    port (
        --System inputs
        clk             : in  std_logic;
        reset           : in  std_logic;

        --Inputs from chip-8 top-level
        pc_in           : in  std_logic_vector(11 downto 0);
        reg_data_x_in   : in  std_logic_vector(7 downto 0);
        reg_data_y_in   : in  std_logic_vector(7 downto 0);
        i_reg_in        : in  std_logic_vector(11 downto 0);
        instr_code      : in  std_logic_vector(5 downto 0); --from decoder
        ram_dout        : in  std_logic_vector(7 downto 0);
        nnn             : in  std_logic_vector(11 downto 0);
        kk              : in  std_logic_vector(7 downto 0);
        x               : in  std_logic_vector(3 downto 0);
        y               : in  std_logic_vector(3 downto 0);
        n               : in  std_logic_vector(3 downto 0);
        illegal_instr   : in  std_logic;
        key_pressed     : in  std_logic;
        key_value_in    : in  std_logic_vector(3 downto 0);
        dt_in           : in  std_logic_vector(7 downto 0); --delay timer
        st_in           : in  std_logic_vector(7 downto 0); --sound timer
        bcd_code        : in  std_logic_vector(11 downto 0); --BCD code
        rand_val        : in  std_logic_vector(7 downto 0);
        alu_result_in   : in  std_logic_vector(7 downto 0);  
        alu_i_add_in    : in  std_logic_vector(11 downto 0); 
        vf_flag_in      : in  std_logic;

        --Outputs
        ram_read_en     : out std_logic;
        ram_addr_out    : out std_logic_vector(11 downto 0);
        ram_write_en    : out std_logic;
        ram_din         : out std_logic_vector(7 downto 0);
        stack_push_en   : out std_logic;
        stack_pop_en    : out std_logic;

        key_check_en    : out std_logic;

        dt_load_en      : out std_logic;
        dt_din          : out std_logic_vector(7 downto 0); --data for delay timer
        st_load_en      : out std_logic;
        st_din          : out std_logic_vector(7 downto 0); --data for sound timer

        video_clear_en  : out std_logic; --signal to clear the screen
        video_draw_en   : out std_logic; --signal to draw in the screen

        bin_din         : out std_logic_vector(7 downto 0);
        bcd_en          : out std_logic;

        pc_load_en      : out std_logic; --load PC from immediate nnn (pc_load_nnn_en)
        pc_inc_en       : out std_logic;
        pc_skip_en      : out std_logic;
        pc_addr_out     : out std_logic_vector(11 downto 0);
        pc_ret_en       : out std_logic; --request PC load from stack (RET)
        pc_jump_v0_en   : out std_logic; --request PC = nnn + V0 (JP V0)

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
end entity control_fsm;

architecture arch_control_fsm of control_fsm is
    --States definition
    type state_type is (S_FETCH_1, S_FETCH_2, S_DECODE,S_READ_REGS, S_EXECUTE,
        S_LD_I_VX_INIT, 
        S_LD_I_VX_WRITE,
        S_LD_VX_I_INIT,
        S_LD_VX_I_READ,
        S_LD_B_VX_0,
        S_LD_B_VX_1,
        S_LD_B_VX_2,
        S_WAIT_KEY);
    signal current_state, next_state : state_type;

    signal reg_counter               : unsigned(3 downto 0);

    signal i_reg_addr_internal       : std_logic_vector(11 downto 0);

begin

    process(clk, reset)
    begin
        if reset = '0' then
            current_state <= S_FETCH_1;
            i_reg_addr_internal <= (others => '0');
            reg_counter         <= (others => '0');

        elsif rising_edge(clk) then
            current_state <= next_state;

            if current_state = S_LD_I_VX_INIT or current_state = S_LD_VX_I_INIT then
                i_reg_addr_internal <= i_reg_in;  
                reg_counter <= (others => '0');

            elsif current_state = S_LD_I_VX_WRITE or current_state = S_LD_VX_I_READ or current_state = S_LD_B_VX_0 or current_state = S_LD_B_VX_1 or current_state = S_LD_B_VX_2 then
                i_reg_addr_internal <= std_logic_vector(unsigned(i_reg_addr_internal) + 1);
                reg_counter <= reg_counter + 1;

            end if;
        end if;

    end process;

    --Control logic
    process(current_state, instr_code, pc_in, nnn, kk, x, y, n, illegal_instr, rand_val, key_pressed, key_value_in, reg_data_x_in, reg_data_y_in, dt_in, alu_i_add_in, alu_result_in, vf_flag_in, bcd_code, i_reg_addr_internal, reg_counter, ram_dout, i_reg_in)
    begin
        --Defaults
        ram_read_en     <= '0';
        ram_addr_out    <= (others => '0');
        ram_write_en    <= '0';
        ram_din         <= (others => '0');

        stack_push_en   <= '0';
        stack_pop_en    <= '0';

        key_check_en    <= '0';

        pc_load_en      <= '0';
        pc_inc_en       <= '0';
        pc_skip_en      <= '0';
        pc_addr_out     <= (others => '0');

        pc_ret_en       <= '0';
        pc_jump_v0_en   <= '0';

        reg_read_en     <= '0';
        reg_write_en    <= '0';
        reg_read_addr_x <= (others => '0');
        reg_read_addr_y <= (others => '0');
        reg_write_addr  <= (others => '0');
        reg_data        <= (others => '0');

        alu_op          <= (others => '0');

        i_load_en       <= '0';
        i_data_in       <= (others => '0');
        i_inc_en        <= '0';

        dt_load_en      <= '0';
        dt_din      <= (others => '0');

        st_load_en      <= '0';
        st_din      <= (others => '0');

        bcd_en          <= '0';

        video_clear_en  <= '0'; 
        video_draw_en   <= '0'; 
        latch_msb_en    <= '0';
        bin_din         <= (others => '0');

        next_state <= current_state;

        case current_state is
            when S_FETCH_1 =>
                ram_read_en  <= '1';
                ram_addr_out <= pc_in;
                latch_msb_en <= '1';

                pc_inc_en       <= '0';
                pc_load_en      <= '0';
                pc_skip_en      <= '0';
                bcd_en        <= '0';

                next_state   <= S_FETCH_2;

            when S_FETCH_2 =>
                latch_msb_en    <= '0';
                ram_read_en     <= '1';
                ram_addr_out    <= std_logic_vector(unsigned(pc_in) + 1);

                next_state      <= S_DECODE;


            when S_DECODE =>
                pc_inc_en   <= '1';
                ram_read_en <= '0';

                if instr_code = I_CLS or instr_code = I_RET or instr_code = I_JP or instr_code = I_CALL or instr_code = I_SYS or instr_code = I_LD_I then
                    next_state <= S_EXECUTE;
                else
                    next_state <= S_READ_REGS;
                end if;

            when S_READ_REGS =>
                reg_read_en     <= '1';
                reg_read_addr_x <= x;
                reg_read_addr_y <= y;
                
                next_state <= S_EXECUTE;

            when S_EXECUTE =>
                case instr_code is

                    --CLS
                    when I_CLS =>
                        --Clear the screen
                        video_clear_en <= '1';
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --DRW
                    when I_DRW =>
                        --Draw in the screen
                        video_draw_en <= '1';
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --RET
                    when I_RET =>
                        -- Request pop from stack and let registers unit set PC from stack
                        stack_pop_en <= '1';
                        pc_ret_en    <= '1';
                        next_state <= S_FETCH_1;

                    --CALL
                    when I_CALL =>
                        stack_push_en <= '1';
                        pc_load_en  <= '1';
                        pc_addr_out <= nnn;
                        next_state <= S_FETCH_1;

                    --SYS
                    when I_SYS =>
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --RND
                    when I_RND =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data       <= rand_val and kk;
                        pc_inc_en      <= '1';
                        next_state     <= S_FETCH_1;

                    --SE Vx, kk
                    when I_SE_Vx_kk =>
                        if reg_data_x_in = kk then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --SNE Vx, kk
                    when I_SNE_Vx_kk =>
                        if reg_data_x_in /= kk then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --SE Vx, Vy
                    when I_SE_Vx_Vy =>
                        if reg_data_x_in = reg_data_y_in then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --SNE Vx, Vy
                    when I_SNE_Vx_Vy =>
                        if reg_data_x_in /= reg_data_y_in then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --SKP Vx
                    when I_SKP =>
                        key_check_en <= '1';
                        if key_pressed = '1' and std_logic_vector(resize(unsigned(key_value_in), 8)) = reg_data_x_in then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --SKNP Vx
                    when I_SKNP =>
                        key_check_en <= '1';
                        if key_pressed = '0' or std_logic_vector(resize(unsigned(key_value_in), 8)) /= reg_data_x_in then
                            pc_skip_en <= '1';
                        end if;
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --LD Vx, kk
                    when I_LD_Vx_kk =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data       <= kk;
                        pc_inc_en      <= '1';
                        next_state     <= S_FETCH_1;

                    --LD I, nnn
                    when I_LD_I =>
                        i_load_en  <= '1';
                        i_data_in  <= nnn;
                        pc_inc_en  <= '1';
                        next_state <= S_FETCH_1;

                    --LD Vx, Vy
                    when I_LD_Vx_Vy =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data       <= reg_data_y_in;
                        pc_inc_en      <= '1';
                        next_state     <= S_FETCH_1;

                    --LD Vx, DT
                    when I_LD_Vx_DT =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data       <= dt_in;
                        pc_inc_en      <= '1';
                        next_state     <= S_FETCH_1;

                    --LD DT, Vx
                    when I_LD_DT_Vx =>
                        dt_load_en <= '1';
                        dt_din     <= reg_data_x_in;
                        pc_inc_en  <= '1';
                        next_state <= S_FETCH_1;

                    --LD ST, Vx
                    when I_LD_ST_Vx =>
                        st_load_en <= '1';
                        st_din     <= reg_data_x_in;
                        pc_inc_en  <= '1';
                        next_state <= S_FETCH_1;

                    --LD B, Vx
                    when I_LD_B =>
                        bcd_en          <= '1';
                        next_state <= S_LD_B_VX_0;

                     --LD I, Vx
                    when I_LD_I_Vx =>
                        reg_read_addr_x <= (others => '0');
                        next_state <= S_LD_I_VX_INIT;

                    --LD Vx, I
                    when I_LD_Vx_I =>
                        next_state <= S_LD_VX_I_INIT;

                    --LD Vx, K
                    when I_LD_Vx_K =>
                        next_state <= S_WAIT_KEY;

                    --LD F, Vx
                    when I_LD_F =>
                        i_load_en <= '1';
                        i_data_in <= std_logic_vector(resize(unsigned(reg_data_x_in) * 5, 12));
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                    --JP addr
                    when I_JP =>
                        pc_load_en  <= '1';
                        pc_addr_out <= nnn;
                        next_state <= S_FETCH_1;

                    --JP V0 : use registers block to perform nnn + V0
                    when I_JP_V0 =>
                        -- Request V0 read (addr 0) and signal jump_v0 to registers
                        reg_read_addr_x <= (others => '0'); -- ensure V0 is read (top-level should route V0 back if needed)
                        pc_jump_v0_en <= '1';
                        next_state <= S_FETCH_1;

                    --ALU instructions
                    when I_ADD_Vx_Vy | I_SUB | I_SUBN | I_OR | I_AND | I_XOR | I_SHR | I_SHL | I_ADD_Vx_kk | I_ADD_I_Vx =>

                        alu_op <= instr_code;

                        if instr_code = I_ADD_I_Vx then
                            i_load_en    <= '1';
                            i_data_in    <= alu_i_add_in;
                            reg_write_en <= '0';
                        else
                            reg_write_en   <= '1';
                            reg_write_addr <= x;
                            reg_data       <= alu_result_in;
                        end if;

                        if (instr_code = I_ADD_Vx_Vy or instr_code = I_SUB or instr_code = I_SUBN or 
                            instr_code = I_SHR or instr_code = I_SHL or instr_code = I_ADD_Vx_kk) then
                            reg_write_en   <= '1';
                            reg_write_addr <= "1111"; --VF
                            reg_data       <= (7 downto 1 => '0') & vf_flag_in;
                        end if;

                        pc_inc_en  <= '1';
                        next_state <= S_FETCH_1;


                    when others =>
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;

                end case;

                --Start waiting for key
                when S_WAIT_KEY =>
                    key_check_en <= '1';
                    reg_read_en  <= '1';
                    reg_read_addr_x <= x;
                    
                    if key_pressed = '1' then
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        
                        reg_data       <= std_logic_vector(resize(unsigned(key_value_in), 8));
                        pc_inc_en      <= '1';
                        next_state     <= S_FETCH_1;
                    else
                        next_state <= S_WAIT_KEY; --Still waiting
                    end if;

                when S_LD_B_VX_0 => --Write the MS digit
                    ram_write_en <= '1';
                    ram_addr_out <= i_reg_addr_internal;
                    ram_din <= std_logic_vector(resize(unsigned(bcd_code(11 downto 8)), 8));
                    
                    next_state <= S_LD_B_VX_1;

                when S_LD_B_VX_1 => --Write the digit in the middle
                    ram_write_en <= '1';
                    ram_addr_out <= i_reg_addr_internal;
                    ram_din <= std_logic_vector(resize(unsigned(bcd_code(7 downto 4)), 8)); 
                    
                    next_state <= S_LD_B_VX_2;

                when S_LD_B_VX_2 => --Write the LS digit
                    ram_write_en <= '1';
                    ram_addr_out <= i_reg_addr_internal;
                    ram_din <= std_logic_vector(resize(unsigned(bcd_code(3 downto 0)), 8)); 
                    
                    pc_inc_en <= '1';
                    next_state <= S_FETCH_1;


                -- Multi-cycle: LD I, Vx
                when S_LD_I_VX_INIT =>
                    next_state <= S_LD_I_VX_WRITE;

                when S_LD_I_VX_WRITE =>
                    reg_read_en     <= '1';
                    reg_read_addr_x <= std_logic_vector(reg_counter);
                    ram_write_en    <= '1';
                    ram_addr_out    <= i_reg_addr_internal;
                    ram_din         <= reg_data_x_in;
                    
                    if reg_counter = unsigned(x) then
                        i_inc_en   <= '1';
                        pc_inc_en  <= '1';
                        next_state <= S_FETCH_1;
                    else
                        next_state <= S_LD_I_VX_WRITE;
                    end if;


                --Multi-cycle: LD Vx, I
                when S_LD_VX_I_INIT =>
                    ram_read_en  <= '1';
                    ram_addr_out <= i_reg_in;
                    next_state   <= S_LD_VX_I_READ;

                when S_LD_VX_I_READ =>
                    reg_write_en   <= '1';
                    reg_write_addr <= std_logic_vector(reg_counter);
                    ram_read_en    <= '1';
                    ram_addr_out   <= i_reg_addr_internal;
                    reg_data       <= ram_dout;
                    
                    if reg_counter = unsigned(x) then
                        i_inc_en  <= '1';
                        pc_inc_en <= '1';
                        next_state <= S_FETCH_1;
                    else
                        next_state <= S_LD_VX_I_READ;
                    end if;

        end case;
    end process;
end arch_control_fsm;