library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;

entity control_fsm is
    port (
        -- System inputs
        clk             : in  std_logic;
        reset           : in  std_logic;

        --Inputs from top-level
        pc_in           : in  std_logic_vector(11 downto 0);
        i_reg_in        : in  std_logic_vector(15 downto 0);
        instr_code      : in  std_logic_vector(5 downto 0); --decoder
        ram_dout        : in  std_logic_vector(7 downto 0);
        nnn             : in  std_logic_vector(11 downto 0);
        kk              : in  std_logic_vector(7 downto 0);
        x               : in  std_logic_vector(3 downto 0);
        y               : in  std_logic_vector(3 downto 0);
        n               : in  std_logic_vector(3 downto 0);
        illegal_instr   : in  std_logic;
        key_pressed     : in  std_logic;

        -- Outputs
        ram_read_en     : out std_logic;
        ram_addr_out    : out std_logic_vector(11 downto 0);
        stack_push_en   : out std_logic;
        stack_pop_en    : out std_logic;

        key_check_en    : out std_logic;


        pc_load_en      : out std_logic;
        pc_inc_en       : out std_logic;
        pc_addr_out     : out std_logic_vector(11 downto 0);

        reg_read_en     : out std_logic;
        reg_write_en    : out std_logic;
        reg_read_addr_x : out std_logic_vector(3 downto 0);
        reg_read_addr_y : out std_logic_vector(3 downto 0);
        reg_write_addr  : out std_logic_vector(3 downto 0);
        reg_data_in     : out std_logic_vector(7 downto 0);

        i_load_en       : out std_logic;
        i_data_in       : out std_logic_vector(15 downto 0);

        alu_op          : out std_logic_vector(3 downto 0)
    );
end entity control_fsm;

architecture behavioral of control_fsm is
    -- States definition
    type state_type is (S_FETCH, S_DECODE, S_EXECUTE);
    signal current_state, next_state : state_type;

begin
    -- Processo de transição de estados
    process(clk, reset)
    begin
        if reset = '0' then
            current_state <= S_FETCH;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Lógica de controle
    process(current_state, instr_code, pc_in, nnn, kk, x, y, n, illegal_instr)
    begin
        -- Defaults (sinais inativos)
        ram_read_en     <= '0';
        ram_addr_out    <= (others => '0');
        pc_load_en      <= '0';
        pc_inc_en       <= '0';
        pc_addr_out     <= (others => '0');
        reg_read_en     <= '0';
        reg_write_en    <= '0';
        reg_read_addr_x <= (others => '0');
        reg_read_addr_y <= (others => '0');
        reg_write_addr  <= (others => '0');
        reg_data_in     <= (others => '0');
        alu_op          <= (others => '0');
        i_load_en       <= '0';
        i_data_in       <= (others => '0');

        next_state <= current_state;

        case current_state is
            when S_FETCH =>
                ram_read_en  <= '1';
                ram_addr_out <= pc_in;
                next_state   <= S_DECODE;

            when S_DECODE =>
                next_state <= S_EXECUTE;

            when S_EXECUTE =>
                case instr_code is

                    --CLS
                    when I_CLS =>
                        --clear the screen
                        --video_cls <= '1';
                        pc_inc_en <= '1';

                    --DRW
                    when I_DRW =>
                        --Draw in the screen
                        --video_draw <= '1';
                        pc_inc_en <= '1';

                    --RET
                    when I_RET =>
                        pc_load_en   <= '1';
                        pc_addr_out  <= std_logic_vector(resize(unsigned(ram_dout), 12));
                        stack_pop_en <= '1';

                    --CALL
                    when I_CALL =>
                        stack_push_en <= '1';
                        pc_load_en  <= '1';
                        pc_addr_out <= nnn;

                    --SE Vx, kk
                    when I_SE_Vx_kk =>
                        reg_read_en <= '1';
                        reg_read_addr_x <= x;
                        if reg_data_in = kk then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    --SNE Vx, kk
                    when I_SNE_Vx_kk =>
                        reg_read_en <= '1';
                        reg_read_addr_x <= x;
                        if reg_data_in /= kk then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    --SE Vx, Vy
                    when I_SE_Vx_Vy =>
                        reg_read_en <= '1';
                        reg_read_addr_x <= x;
                        if reg_data_in = y then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    --SNE Vx, Vy
                    when I_SNE_Vx_Vy =>
                        reg_read_en <= '1';
                        reg_read_addr_x <= x;
                        if reg_data_in /= y then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    --SKP Vx
                    when I_SKP =>
                        reg_read_en <= '1';
                        reg_read_addr_x <= x;
                        key_check_en <= '1';
                        if key_pressed = '1' then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    --SKNP Vx
                    when I_SKNP =>
                        reg_read_en     <= '1';
                        reg_read_addr_x <= x;
                        key_check_en <= '1';
                        if key_pressed = '0' then
                            pc_inc_en <= '1';
                        end if;
                        pc_inc_en <= '1';

                    -- LD Vx, kk
                    when I_LD_Vx_kk =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data_in    <= kk;
                        pc_inc_en      <= '1';

                    -- LD I, nnn
                    when I_LD_I =>
                        i_load_en  <= '1';
                        i_data_in  <= std_logic_vector(resize(unsigned(nnn), 16));
                        pc_inc_en  <= '1';

                    --LD Vx, Vy
                    when I_LD_Vx_Vy =>
                        reg_write_en   <= '1';
                        reg_write_addr <= x;
                        reg_data_in    <= y;
                        pc_inc_en      <= '1';

                    -- JP addr
                    when I_JP =>
                        pc_load_en  <= '1';
                        pc_addr_out <= nnn;
                        

                    --ALU instructions
                    when I_ADD_Vx_Vy | I_SUB | I_SUBN | I_OR | I_AND | I_XOR | I_SHR | I_SHL | I_ADD_Vx_kk | I_ADD_I_Vx =>

                        reg_read_en     <= '1';
                        reg_read_addr_x <= x;
                        if instr_code = I_ADD_Vx_kk then
                            reg_data_in <= kk;
                        else
                            reg_read_addr_y <= y;
                        end if;
                        alu_op          <= instr_code;
                        reg_write_en    <= '1';
                        reg_write_addr  <= x;
                        pc_inc_en       <= '1';


                    when others =>
                        pc_inc_en <= '1';
                end case;

                next_state <= S_FETCH;
        end case;
    end process;
end architecture behavioral;