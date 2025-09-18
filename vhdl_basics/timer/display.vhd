--Conversor binário (4 bits) para 7 segmentos

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is
    port(
        a           : in unsigned(3 downto 0);
        m           : in std_logic;
        s           : out std_logic_vector (6 downto 0)
    );
end display;

architecture behavioral of display is
    begin

        process(a,m)
            begin

                if m = '0' then -- Para anodo comum
                    case a is
                        when "0000" => s <= "1000000"; -- 0
                        when "0001" => s <= "1111001"; -- 1
                        when "0010" => s <= "0100100"; -- 2
                        when "0011" => s <= "0110000"; -- 3
                        when "0100" => s <= "0011001"; -- 4
                        when "0101" => s <= "0010010"; -- 5
                        when "0110" => s <= "0000010"; -- 6
                        when "0111" => s <= "1111000"; -- 7
                        when "1000" => s <= "0000000"; -- 8
                        when "1001" => s <= "0011000"; -- 9
                        when others => s <= "1111111"; -- outros
                    end case;

                else -- Para catodo comum
                    case a is
                        when "0000" => s <= "0111111"; -- 0
                        when "0001" => s <= "0000110"; -- 1
                        when "0010" => s <= "1011011";-- 2
                        when "0011" => s <= "1001111"; -- 3
                        when "0100" => s <= "1100110"; -- 4
                        when "0101" => s <= "1101101"; -- 5
                        when "0110" => s <= "1111101"; -- 6
                        when "0111" => s <= "0000111"; -- 7
                        when "1000" => s <= "1111111"; -- 8
                        when "1001" => s <= "1100111"; -- 9
                        when others => s <= "0000000"; -- outros
                    end case;
                end if;
                
        end process;

end behavioral;