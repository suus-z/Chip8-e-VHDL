--Teste de Conversor Binario(4bits) para BCD (8bits)

entity bcd_converter is
    port(
        a3, a2, a1, a0      : in    bit;
        b3, b2, b1, b0      : out   bit;
        c3, c2, c1, c0      : out   bit
    );
end bcd_converter;

architecture main of bcd_converter is
    begin
        b3 <= '0';
        b2 <= '0';
        b1 <= '0';
        b0 <= a3 and (a2 or a1);
        
        c3 <= a3 and (not a2) and (not a1);
        c2 <= ((not a3) and a2) or (a2 and a1);
        c1 <= ((not a3) and a1) or (a3 and a2 and (not a1));
        c0 <= a0;
end main;