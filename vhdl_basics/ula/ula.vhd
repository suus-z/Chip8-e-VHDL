--Unidade lógico-aritimética

library ieee;
use ieee.numeric_bit.all;

entity ula is
    port(
        Ai, Bi    :     in unsigned (7 downto 0);
        S1, S0, M :     in bit;
        Fi        :     out unsigned (7 downto 0)

    );
end ula;

architecture main of ula is

    signal H, G :   unsigned(7 downto 0);
    signal sel  :   bit_vector(1 downto 0);

    begin
        sel <= S1 & S0;

        --aritimética
        with sel select
            G <=    Ai + Bi when "00",
                    Ai - Bi when "01",
                    Ai + x"01" when "10",
                    Ai - x"01" when others;

        --lógica
        with sel select
            H <=    Ai and Bi when "00",
                    Ai or Bi when "01",
                    Ai xor Bi when "10",
                    not Ai when others;

        --Saída e seleção
        Fi <= G when M = '1' else H;

end main;