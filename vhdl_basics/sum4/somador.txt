--Teste de Somador de 4 bits

entity somador is
    port(
        a, b : in   integer range 0 to 15;
        z    : out  integer range 0 to 15
    );
end somador;

architecture main of somador is
    begin
        z <= a + b;
        
    end main;