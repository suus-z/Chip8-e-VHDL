--BCD Converter
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_convert is
    generic (
        BIN_WIDTH  : integer := 8;
        NUM_DIGITS : integer := 3
    );
    port (
        bin_din     : in  std_logic_vector(BIN_WIDTH-1 downto 0);
        bcd_code    : out std_logic_vector(NUM_DIGITS*4-1 downto 0)
    );
end entity;

architecture arch_bcd_convert of bcd_convert is
begin

    process(bin_din)
        variable shift_reg : std_logic_vector(BIN_WIDTH + NUM_DIGITS*4 - 1 downto 0);
        variable nibble    : unsigned(3 downto 0);
    begin
        shift_reg := (others => '0');
        shift_reg(BIN_WIDTH-1 downto 0) := bin_din;

        for i in 0 to BIN_WIDTH-1 loop
            for d in 0 to NUM_DIGITS-1 loop
                nibble := unsigned(shift_reg(BIN_WIDTH + d*4 + 3 downto BIN_WIDTH + d*4));
                if nibble >= 5 then
                    shift_reg(BIN_WIDTH + d*4 + 3 downto BIN_WIDTH + d*4) := std_logic_vector(nibble + 3);
                end if;
            end loop;
            shift_reg := shift_reg(shift_reg'left-1 downto 0) & '0';
        end loop;

        bcd_code <= shift_reg(shift_reg'left downto BIN_WIDTH);
    end process;

end arch_bcd_convert;