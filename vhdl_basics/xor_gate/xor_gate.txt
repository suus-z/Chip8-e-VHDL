--Teste porta XOR

entity gate_xor is
    port(
        a, b    : in    bit;
        z       : out   bit
    );
end gate_xor;

architecture main of gate_xor is
    begin
        z <= a XOR b;
        
end main;