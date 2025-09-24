library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_gen is
    port(
        reset      : in  std_logic;
        f_clock    : in  std_logic;
        f_on       : in  std_logic;
        f_row      : in  std_logic_vector(9 downto 0);
        f_column   : in  std_logic_vector(10 downto 0);
        R_out      : out std_logic_vector(7 downto 0);
        G_out      : out std_logic_vector(7 downto 0);
        B_out      : out std_logic_vector(7 downto 0)
    );
end pixel_gen;

architecture arch_pixel_gen of pixel_gen is
begin

    process(f_clock, reset)
    begin
        if reset = '0' then
            R_out <= (others => '0');
            G_out <= (others => '0');
            B_out <= (others => '0');
        elsif rising_edge(f_clock) then
            if f_on = '1' then
                -- Lógica de cores dentro da área visível
                if unsigned(f_column) < 100 then
                    R_out <= (others => '1'); -- Vermelho
                    G_out <= (others => '0');
                    B_out <= (others => '0');
                elsif unsigned(f_column) >= 100 and unsigned(f_column) < 200 then
                    R_out <= (others => '0'); -- Azul
                    G_out <= (others => '0');
                    B_out <= (others => '1');
                elsif unsigned(f_column) >= 200 and unsigned(f_column) < 300 then
                    R_out <= (others => '0'); -- Verde
                    G_out <= (others => '1');
                    B_out <= (others => '0');
                elsif unsigned(f_column) >= 300 and unsigned(f_column) < 400 then
                    R_out <= (others => '0'); -- Ciano
                    G_out <= (others => '1');
                    B_out <= (others => '1');
                elsif unsigned(f_column) >= 400 and unsigned(f_column) < 500 then
                    R_out <= (others => '1'); -- Magenta
                    G_out <= (others => '0');
                    B_out <= (others => '1');
                elsif unsigned(f_column) >= 500 and unsigned(f_column) < 600 then
                    R_out <= (others => '1'); -- Amarelo
                    G_out <= (others => '1');
                    B_out <= (others => '0');
                elsif unsigned(f_column) >= 600 and unsigned(f_column) < 700 then
                    R_out <= (others => '1'); -- Branco
                    G_out <= (others => '1');
                    B_out <= (others => '1');
                else
                    R_out <= (others => '0'); -- Preto (valores fora das faixas definidas)
                    G_out <= (others => '0');
                    B_out <= (others => '0');
                end if;
            else
                -- Fora da área visível → preto
                R_out <= (others => '0');
                G_out <= (others => '0');
                B_out <= (others => '0');
            end if;
        end if;
    end process;
end arch_pixel_gen;