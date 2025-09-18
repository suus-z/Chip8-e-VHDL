--RAM 4KB
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_constants.all;

entity ram is
    generic(
        data_width  :   integer  := 8;
        addr_width  :   integer  := 12
    );

    port(
        clk     :   in   std_logic;
        we      :   in   std_logic;
        addr    :   in   std_logic_vector(addr_width-1 downto 0);
        din     :   in   std_logic_vector(data_width-1 downto 0);
        dout    :   out  std_logic_vector(data_width-1 downto 0)
    );
end ram;

architecture ram_arch of ram is
    type ram_type is array(0 to (2**addr_width - 1)) of std_logic_vector(data_width-1 downto 0);
    signal ram_block    :   ram_type := (
        16#000# => x"F0", 16#001# => x"90", 16#002# => x"90", 16#003# => x"90", 16#004# => x"F0", --0
        16#005# => x"20", 16#006# => x"60", 16#007# => x"20", 16#008# => x"20", 16#009# => x"70", --1
        16#00A# => x"F0", 16#00B# => x"10", 16#00C# => x"F0", 16#00D# => x"80", 16#00E# => x"F0", --2
        16#00F# => x"F0", 16#010# => x"10", 16#011# => x"F0", 16#012# => x"10", 16#013# => x"F0", --3
        16#014# => x"90", 16#015# => x"90", 16#016# => x"F0", 16#017# => x"10", 16#018# => x"10", --4
        16#019# => x"F0", 16#01A# => x"80", 16#01B# => x"F0", 16#01C# => x"10", 16#01D# => x"F0", --5
        16#01E# => x"F0", 16#01F# => x"80", 16#020# => x"F0", 16#021# => x"90", 16#022# => x"F0", --6
        16#023# => x"F0", 16#024# => x"10", 16#025# => x"20", 16#026# => x"40", 16#027# => x"40", --7
        16#028# => x"F0", 16#029# => x"90", 16#02A# => x"F0", 16#02B# => x"90", 16#02C# => x"F0", --8
        16#02D# => x"F0", 16#02E# => x"90", 16#02F# => x"F0", 16#030# => x"10", 16#031# => x"F0", --9
        16#032# => x"F0", 16#033# => x"90", 16#034# => x"F0", 16#035# => x"90", 16#036# => x"90", --A
        16#037# => x"E0", 16#038# => x"90", 16#039# => x"E0", 16#03A# => x"90", 16#03B# => x"E0", --B
        16#03C# => x"F0", 16#03D# => x"80", 16#03E# => x"80", 16#03F# => x"80", 16#040# => x"F0", --C
        16#041# => x"E0", 16#042# => x"90", 16#043# => x"90", 16#044# => x"90", 16#045# => x"E0", --D
        16#046# => x"F0", 16#047# => x"80", 16#048# => x"F0", 16#049# => x"80", 16#04A# => x"F0", --E
        16#04B# => x"F0", 16#04C# => x"80", 16#04D# => x"F0", 16#04E# => x"80", 16#04F# => x"80", --F
        others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' and unsigned(addr) >= font_size then
                ram_block(to_integer(unsigned(addr))) <= din;
            end if;

            dout <= ram_block(to_integer(unsigned(addr)));
        end if;
    end process;

end ram_arch;