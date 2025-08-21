--Comparador de magnitude com sinal

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signed_comparator is
    generic(n   :   integer :=4); --Range do comparador

    port(
        a       : in    std_logic_vector (n-1 downto 0);
        b       : in    std_logic_vector (n-1 downto 0);
        a_gt_b  : out   std_logic
    );
end signed_comparator;

architecture rtl of signed_comparator is
    begin

        process(a, b) --Processo de comparação
            begin
                if(signed(a) > signed(b)) then
                    a_gt_b <= '1';
                else
                    a_gt_b <= '0';
                end if;
        end process;

end rtl;