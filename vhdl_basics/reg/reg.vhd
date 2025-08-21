--Registrador paralelo genérico

library ieee;
use ieee.std_logic_1164.all;

entity reg is
    generic(n   :   integer := 8);

    port(
        clk, rst    :   in   std_logic;
        data        :   in   std_logic_vector(n-1 downto 0);
        q           :   out  std_logic_vector(n-1 downto 0)
    );

end reg;

architecture behavioral of reg is
    begin

        process(clk, rst, data)
        begin

            if rst = '0' then
                q <= (others => '0');
                
            elsif rising_edge(clk) then
                q <= data;
            end if;

        end process;

end behavioral;