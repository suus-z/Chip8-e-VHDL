--Somador completo do tipo carry-ripple (n bits)

library ieee;
use ieee.std_logic_1164.all;

entity generic_carry_ripple is
    generic(n   :   integer := 16); --Número de bits entrada e saída
    port(
        --Entradas
        a, b  : in std_logic_vector (n-1 downto 0);
        carry_in: in std_logic;
        
        --Saídas
        s      : out std_logic_vector (n-1 downto 0);
        carry_out: out std_logic
    );
end generic_carry_ripple;

architecture main of generic_carry_ripple is
    
    --Sinais internos
    signal c   :   std_logic_vector (0 to n);

    begin

        carry_out <= c(n);
        c(0) <= carry_in;

        gen: for i in 0 to n-1 generate
            fa: entity work.full_adder(rtl) port map(a(i), b(i), c(i), s(i), c(i+1));
        end generate gen;

end main;