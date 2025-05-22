--Teste de incrementador

entity incrementer is
    port(
        data_in     : in    integer;
        data_out    : out   integer
    );
    
end incrementer;

architecture main of incrementer is
    
    constant valor  :   integer := 3;

    begin
        data_out <= data_in + valor;

end main;