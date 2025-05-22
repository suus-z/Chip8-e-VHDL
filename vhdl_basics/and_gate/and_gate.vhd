--Teste porta AND

entity and_gate is
    port(
        a, b : in   bit;
        z    : out  bit
    );
end and_gate;

architecture main of and_gate is
    begin
        z <= a AND b;
    
end main;