--Conversor binário (4 bits) para 7 segmentos com catodo comum

library ieee;
use ieee.std_logic_1164.all;

entity seven_seg is
    port(
        a   : in std_logic_vector (3 downto 0);
        s   : out std_logic_vector (6 downto 0)
    );
end seven_seg;

architecture main of seven_seg is

    begin

    process(a)
    begin
        case a is
            when "0000" => s <= "0000001"; -- "0"     
            when "0001" => s <= "1001111"; -- "1" 
            when "0010" => s <= "0010010"; -- "2" 
            when "0011" => s <= "0000110"; -- "3" 
            when "0100" => s <= "1001100"; -- "4" 
            when "0101" => s <= "0100100"; -- "5" 
            when "0110" => s <= "0100000"; -- "6" 
            when "0111" => s <= "0001111"; -- "7" 
            when "1000" => s <= "0000000"; -- "8"     
            when "1001" => s <= "0000100"; -- "9"
            when others => s <= "1111111"; -- Todos apagados (ativo alto)
        end case;
    end process;

end main;