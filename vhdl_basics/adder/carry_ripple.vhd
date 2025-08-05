--Somador completo do tipo carry-ripple (4bits)

library ieee;
use ieee.std_logic_1164.all;

entity carry_ripple is
    port(
        --Entradas
        a, b  : in std_logic_vector (3 downto 0);
        carry_in: in std_logic;
        
        --Saídas
        s      : out std_logic_vector (3 downto 0);
        carry_out: out std_logic
    );
end carry_ripple;

architecture main of carry_ripple is
    
    --Declaração do componente full_adder
    component full_adder is
    port (
        a, b, carry_in   : in std_logic;
        sum, carry       : out std_logic
    );
    end component full_adder;

    --Sinais internos
    signal c   :   std_logic_vector (3 downto 0);

    begin
        fa1: full_adder port map(a(0), b(0), carry_in, s(0), c(1));
        fa2: full_adder port map(a(1), b(1), c(1), s(1), c(2));
        fa3: full_adder port map(a(2), b(2), c(2), s(2), c(3));
        fa4: full_adder port map(a(3), b(3), c(3), s(3), carry_out);
end main;