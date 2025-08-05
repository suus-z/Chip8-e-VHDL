--Unidade lógico-aritmética com o comando block

library ieee;
use ieee.numeric_bit.all;

entity ula_block is
    port(
        ai, bi :    in unsigned (7 downto 0);
        s1, s0, M :    in bit;
        fi     :    out unsigned (7 downto 0)
    );
end ula_block;

architecture main of ula_block is

    signal H, G :   unsigned(7 downto 0);

    begin

        --unidade aritmética
        arith_unit: block
        signal sel_arith : bit_vector (1 downto 0);
        begin
            sel_arith <= s1 & s0;
            with sel_arith select
                G <= ai+bi when "00",
                     ai-bi when "01",
                     ai+x"01" when "10",
                     ai-x"01" when others;
        end block arith_unit;


        --unidade lógica
        logic_unit : block
        signal sel_logic : bit_vector (1 downto 0);
        begin
            sel_logic <= s1 & s0;
            with sel_logic select
                H <= ai and bi when "00",
                     ai or bi when "01",
                     ai xor bi when "10",
                     not ai when others;
        end block logic_unit;

    fi <= G when M = '1' else H;

    end main;