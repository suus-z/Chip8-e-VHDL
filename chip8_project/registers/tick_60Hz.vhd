library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tick_60Hz is
    generic(
        CLK_FREQ  : integer := 50e6  -- frequência do clock da FPGA em Hz
    );
    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        tick_60Hz : out std_logic
    );
end tick_60Hz;

architecture arch_tick_60Hz of tick_60Hz is
    constant MAX_COUNT : integer := CLK_FREQ / 60;
    signal counter : integer range 0 to MAX_COUNT-1 := 0;
    signal tick    : std_logic := '0';
    
begin
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= 0;
            tick <= '0';
        elsif rising_edge(clk) then
            if counter = MAX_COUNT-1 then
                counter <= 0;
                tick <= '1';
            else
                counter <= counter + 1;
                tick <= '0';
            end if;
        end if;
    end process;

    tick_60Hz <= tick;
end arch_tick_60Hz;