--Teste Somador Completo

entity somador_completo is
    port(
        a, b    :   in  bit; --Entradas
        te      :   in  bit; --Carry-in
        s       :   out bit; --Soma
        ts      :   out bit --Carry-out
    );
end entity somador_completo;

architecture main of somador_completo is
    begin
        s <= a XOR b XOR te;
        ts <= (a AND b) OR (a AND te) OR (b AND te);
        
end architecture main;