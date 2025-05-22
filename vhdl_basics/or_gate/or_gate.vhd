--Teste porta OR

entity or_gate is
    port(
        a, b    :in bit;
        z       :out bit
    );
end or_gate;

architecture main of or_gate is
    begin
        z <= a OR b;
        
end main;