--RAM 4KB
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_constants.all;

entity ram is
  generic (
    ram_data_width : integer := 8;
    ram_addr_width : integer := 12
  );

  port (
    clk      : in std_logic;
    ram_we   : in std_logic;
    ram_re   : in std_logic;
    ram_addr : in std_logic_vector(ram_addr_width - 1 downto 0);
    ram_din  : in std_logic_vector(ram_data_width - 1 downto 0);
    ram_dout : out std_logic_vector(ram_data_width - 1 downto 0)
  );
end ram;

architecture ram_arch of ram is

  type ram_type is array(0 to ((2 ** ram_addr_width) - 1)) of std_logic_vector(ram_data_width - 1 downto 0);
  signal ram_block : ram_type;

  attribute ram_init_file              : string;
  attribute ram_init_file of ram_arch : architecture is "invaders.mif";

begin

  process (clk)
  begin
    if rising_edge(clk) then
      if ram_we = '1' and unsigned(ram_addr) >= font_size then
        ram_block(to_integer(unsigned(ram_addr))) <= ram_din;
      end if;

      ram_dout <= ram_block(to_integer(unsigned(ram_addr)));

    end if;
  end process;

end ram_arch;