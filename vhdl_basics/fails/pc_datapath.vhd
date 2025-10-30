library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc_datapath is
    port (
        pc_current_in  : in  std_logic_vector(11 downto 0);
        nnn_in         : in  std_logic_vector(11 downto 0);
        v0_data_in     : in  std_logic_vector(7 downto 0);

        -- FSM control
        pc_load_en     : in  std_logic;
        pc_inc_en      : in  std_logic;  -- Novo: Inc em +2
        pc_skip_en     : in  std_logic;  -- NOVO: Inc em +4 (para skips)
        
        -- Outputs for pc reg (pc_din e we_pc)
        pc_next_out    : out std_logic_vector(11 downto 0);
        pc_we_out      : out std_logic
    );
end entity pc_datapath;

architecture arch_pc_datapath of pc_datapath is
begin
    process(pc_current_in, pc_load_en, pc_inc_en, pc_skip_en, nnn_in, v0_data_in)
    begin
        pc_next_out <= pc_current_in; 

        if pc_load_en = '1' then
            -- 1. Carregamento de um novo endereço (JP ou CALL)
            pc_next_out <= nnn_in;
            -- (Nota: Para JP V0, nnn, a FSM precisará calcular nnn + V0 e enviar para nnn_in)

        elsif pc_skip_en = '1' then
            -- NOVO: 2. Incremento de Skip: PC = PC + 4
            pc_next_out <= std_logic_vector(unsigned(pc_current_in) + 4);

        elsif pc_inc_en = '1' then
            -- 3. Incremento normal: PC = PC + 2
            pc_next_out <= std_logic_vector(unsigned(pc_current_in) + 2);
        end if;
    end process;

    -- Lógica de Escrita (we_pc)
    -- O PC deve ser escrito se houver qualquer sinal de carregamento ou incremento
    pc_we_out <= pc_load_en or pc_inc_en or pc_skip_en; -- pc_skip_en adicionado

end arch_pc_datapath;