--Demultiplexador de 1 entrada e 4 saídas

entity demux_1_4 is
    port(
        d                 : in  bit;
        s0, s1            : in  bit;
        y0, y1, y2, y3    : out bit
    );
end demux_1_4;

architecture main of demux_1_4 is

    signal sel : bit_vector(1 downto 0) := "00";

begin
    sel <= s1 & s0;

    y0 <= d when sel = "00" else '0';
    y1 <= d when sel = "01" else '0';
    y2 <= d when sel = "10" else '0';
    y3 <= d when sel = "11" else '0';

end main;