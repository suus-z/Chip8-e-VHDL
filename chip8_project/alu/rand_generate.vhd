--Random number generator based on a LFSR (Linear Feedback Shift Register)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rand_generate is
    generic (LFSR_WIDTH  : integer := 8);

    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        rand_val  : out std_logic_vector(LFSR_WIDTH-1 downto 0)
    );
end rand_generate;

architecture arch_rand_generate of rand_generate is
    signal lfsr_reg : std_logic_vector(LFSR_WIDTH-1 downto 0) := "10101010"; --seed

begin
    process(clk, reset)
    begin
        if reset = '0' then
            lfsr_reg <= "10101010";
        elsif rising_edge(clk) then
            --XOR taps: 8,6,5,4
            lfsr_reg <= lfsr_reg(6 downto 0) & (lfsr_reg(7) xor lfsr_reg(5) xor lfsr_reg(4) xor lfsr_reg(3));
        end if;
    end process;

    rand_val <= lfsr_reg;
end arch_rand_generate;