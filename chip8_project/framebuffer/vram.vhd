library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vram is
    generic(
        vram_data_width : integer := 8;
        vram_addr_width : integer := 8
    );
    port(
        --PORT A
        clk_a      : in std_logic;
        we_a       : in std_logic;
        addr_a     : in std_logic_vector(vram_addr_width - 1 downto 0);
        din_a      : in std_logic_vector(vram_data_width - 1 downto 0);
        dout_a     : out std_logic_vector(vram_data_width - 1 downto 0);
        
        --PORT B
        clk_b      : in std_logic;
        addr_b     : in std_logic_vector(vram_addr_width - 1 downto 0);
        dout_b     : out std_logic_vector(vram_data_width - 1 downto 0)
    );
end vram;

architecture vram_arch of vram is
    type vram_type is array(0 to (2**vram_addr_width - 1)) of std_logic_vector(vram_data_width - 1 downto 0);
    signal vram_block : vram_type;
    
    attribute ramstyle : string;
    attribute ramstyle of vram_block : signal is "no_rw_check, M9K";

begin
    process(clk_a)
    begin
        if rising_edge(clk_a) then
            if we_a = '1' then
                vram_block(to_integer(unsigned(addr_a))) <= din_a;
            end if;
            dout_a <= vram_block(to_integer(unsigned(addr_a)));
        end if;
    end process;
    
    process(clk_b)
    begin
        if rising_edge(clk_b) then
            dout_b <= vram_block(to_integer(unsigned(addr_b)));
        end if;
    end process;
end vram_arch;