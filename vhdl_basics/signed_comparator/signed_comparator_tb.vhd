--Script de testbench do comparador de magnitude com sinal

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signed_comparator_tb is
end signed_comparator_tb;

architecture sim of signed_comparator_tb is

        constant n  :   integer :=4; --Largura dos dados
        constant most_negative  :   signed(n-1 downto 0)    :=(n-1 => '1', others => '0');
        constant most_positive  :   signed(n-1 downto 0)    :=(n-1 => '0', others => '1');

        signal a, b     :   std_logic_vector    :=std_logic_vector(most_negative);
        signal a_gt_b   :   std_logic;

        begin

                entity work.signed_comparator(rtl) --DUT (device under test)
                    generic map(n => n)
                    port map(a, b, a_gt_b);

                process is
                    variable va, vb     :   signed(n-1 downto 0)    :=most_negative;

                    begin
                        wait for 100 ns;
                        va := va+1;

                        if va = most_negative then
                            vb := vb+1;
                        end if;

                        a <= std_logic_vector(va);
                        b <= std_logic_vector(vb);

                        if vb = most_positive then
                            wait;
                        end if;

                end process;
end sim;