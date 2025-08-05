--Porta XOR de n entradas (máximo 8 entradas i)

library ieee;
use ieee.std_logic_1164.all;

entity xor_n is
    generic(
        n   :   natural := 8
    );
    port(
        i   :   in std_logic_vector (1 to n);
        o   :   out std_logic
    );
end xor_n;

architecture main of xor_n is

    signal a    :   std_logic_vector(1 to n);

    begin

        a(1) <= i(1);
        o <= a(n);
        g1: for x in 2 to n generate
            a(x) <= i(x) xor a(x-1);
        end generate g1;

    end main;