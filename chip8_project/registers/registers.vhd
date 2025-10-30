library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
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
end entity registers;

architecture arch_reg of registers is
    type v_reg_type is array(0 to 15) of std_logic_vector(7 downto 0);
    signal v_reg     : v_reg_type   := (others => (others => '0'));

    type stack_type is array(0 to 15) of std_logic_vector(11 downto 0); 
    signal stack     : stack_type   := (others => (others => '0'));
    signal stack_ptr : unsigned(3 downto 0)   := (others => '0');

    signal i_reg     : std_logic_vector(11 downto 0);
    signal pc_reg    : std_logic_vector(11 downto 0);
    signal dt_reg    : std_logic_vector(7 downto 0);
    signal st_reg    : std_logic_vector(7 downto 0);

    signal pc_next   : std_logic_vector(11 downto 0);

    component tick_60Hz is
        port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        tick_60Hz : out std_logic
        );
    end component tick_60Hz;

    signal tick_60Hz_s : std_logic;

begin

    inst_tick_60Hz: tick_60Hz port map(clk, reset, tick_60Hz_s);

    --PC_NEXT
    process(pc_reg, pc_load_nnn_en, pc_inc_en, pc_skip_en, pc_ret_en, pc_jump_v0_en, nnn_in, v0_data_in, stack_ptr, stack)
        variable jump_v0_addr_v : unsigned(11 downto 0); 
        
    begin
        --Default: PC_NEXT = PC_CURRENT
        pc_next <= pc_reg; 

        jump_v0_addr_v := unsigned(nnn_in) + unsigned(resize(unsigned(v0_data_in), 12));

        if pc_load_nnn_en = '1' then
            pc_next <= nnn_in;
        
        elsif pc_ret_en = '1' then
            if stack_ptr > 0 then
                pc_next <= stack(to_integer(stack_ptr - 1));
            else
                pc_next <= pc_reg;
            end if;

        elsif pc_jump_v0_en = '1' then
            pc_next <= std_logic_vector(jump_v0_addr_v);

        elsif pc_skip_en = '1' then
            pc_next <= std_logic_vector(unsigned(pc_reg) + 4);

        elsif pc_inc_en = '1' then
            pc_next <= std_logic_vector(unsigned(pc_reg) + 2);
        
        end if;
    end process;

    stack_dout <= stack(to_integer(stack_ptr - 1)) when stack_ptr > 0 else (others => '0');

    process(reset, clk)
    begin
        if reset = '0' then
            i_reg     <= (others => '0');
            pc_reg    <= x"200";
            dt_reg    <= (others => '0');
            st_reg    <= (others => '0');
            stack_ptr <= (others => '0');

        elsif rising_edge(clk) then

            --PC
            if pc_load_nnn_en = '1' or pc_inc_en = '1' or pc_skip_en = '1' or pc_ret_en = '1' or pc_jump_v0_en = '1' then
                pc_reg <= pc_next;
            end if;

            --Write V
            if we_v = '1' then
                v_reg(to_integer(unsigned(v_addr))) <= v_din;
            end if;

            --Write I
            if we_i = '1' then
                i_reg <= i_din(11 downto 0); -- I é de 12 bits
            end if;

            --Timer DT
            if we_dt = '1' then
                dt_reg <= dt_din;
            elsif tick_60Hz_s = '1' and dt_reg > "00000000" then
                dt_reg <= std_logic_vector(unsigned(dt_reg) - 1);
            end if;

            --Timer ST
            if we_st = '1' then
                st_reg <= st_din;
            elsif tick_60Hz_s = '1' and st_reg > "00000000" then
                st_reg <= std_logic_vector(unsigned(st_reg) - 1);
            end if;

            --Stack Push/Pop
            if push = '1' and stack_ptr < 15 then
                stack(to_integer(stack_ptr)) <= std_logic_vector(resize(unsigned(pc_reg) + 2, 16));
                stack_ptr <= stack_ptr + 1;
            elsif pop = '1' and stack_ptr > 0 then
                stack_ptr <= stack_ptr - 1;
            end if;

        end if;
    end process;

    -- Saídas de Registradores (Combinacionais)
    v_dout  <= v_reg(to_integer(unsigned(v_addr)));
    v_dout_x <= v_reg(to_integer(unsigned(v_addr_x)));
    v_dout_y <= v_reg(to_integer(unsigned(v_addr_y)));
    
    i_dout  <= i_reg;
    pc_dout <= pc_reg;
    dt_dout <= dt_reg;
    st_dout <= st_reg;

end arch_reg;