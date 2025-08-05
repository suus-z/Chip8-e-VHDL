--Somador completo

library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
    port (
        a, b, carry_in   : in std_logic;
        sum, carry       : out std_logic
    );
end full_adder;

architecture rtl of full_adder is

    --Declaração do componente do meio somador
    component half_adder is
    port(
        a, b    :   in std_logic;
        sum, carry : out std_logic
    );
    end component half_adder;

    signal x, y, z  :   std_logic;

    begin
        carry <= y or z;

        --Instanciação nominal
        ha1: half_adder
            port map(
                a       => a,
                b       => b,
                sum     => x,
                carry   => y
            );

        --Instanciação posicional
        ha2: half_adder
            port map(x, carry_in, sum, z);

    end rtl;