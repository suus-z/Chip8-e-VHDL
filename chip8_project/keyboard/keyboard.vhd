--4x4 hex keyboard (0 to F)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard is
    port(
        clk       : in   std_logic;
        reset     : in   std_logic;
        row       : in   std_logic_vector(3 downto 0);
        column    : out  std_logic_vector(3 downto 0);
        key_code  : out  std_logic_vector(3 downto 0);
        key_valid : out  std_logic
    );
end keyboard;

architecture arch_keyboard of keyboard is

    --Signals for clock
    signal clk50kHz     : std_logic                     := '0';
    signal clk_counter  : integer range 0 to 49999;

    --Signals for control and logic
    signal column_s     : std_logic_vector(3 downto 0)  := (others => '1');
    signal row_s        : std_logic_vector(3 downto 0);
    signal key_code_s   : unsigned(3 downto 0)          := (others =>'0');
    signal key_valid_s  : std_logic                     := '0';

    --Signals for FSM
    type fsm_state is (IDLE, SCAN, DEBOUNCE_WAIT, KEY_VALID_DETECTED);
    signal current_state : fsm_state := IDLE;
    signal column_scan_index : integer range 0 to 3 := 0;
    signal debounce_counter  : integer range 0 to 5000;
    signal key_pressed_row   : integer range 0 to 3;

begin

    process(reset, clk)
    begin

        if (reset = '0') then
            clk_counter  <= 0;
            clk50kHz     <= '0';

        elsif rising_edge(clk) then

            if (clk_counter = 49999) then
                clk_counter <= 0;
                clk50kHz <= not clk50kHz;
                
            else
                clk_counter <= clk_counter + 1;
            end if;
        end if;

    end process;

    process(reset, clk50kHz)
    begin
        
        if (reset = '0') then
            column_s    <= (others => '1');
            key_code_s  <= (others => '0');
            key_valid_s <= '0';
            current_state       <= IDLE;
            column_scan_index   <= 0;
            debounce_counter    <= 0;

        elsif rising_edge(clk50kHz) then
            key_valid_s <= '0';


                case current_state is

                when IDLE =>
                    --All columns = '1' and reset index
                    column_s <= (others => '1');
                    column_scan_index <= 0;
                    current_state <= SCAN;

                when SCAN =>
                    column_s <= (others => '1');
                    column_s(column_scan_index) <= '0';
                    
                    for i in 0 to 3 loop
                        if (row(i) = '0') then
                            key_pressed_row <= i;
                            debounce_counter <= 0;
                            current_state <= DEBOUNCE_WAIT;
                        end if;
                    end loop;
                    
                    column_scan_index <= column_scan_index + 1;
                    if (column_scan_index = 3) then
                        column_scan_index <= 0;
                    end if;

                when DEBOUNCE_WAIT =>
                    if (debounce_counter < 5000) then
                        debounce_counter <= debounce_counter + 1;
                    else
                        if (row(key_pressed_row) = '0') then
                            current_state <= KEY_VALID_DETECTED;
                        else
                            current_state <= IDLE;
                        end if;
                    end if;

                when KEY_VALID_DETECTED =>
                    key_code_s <= to_unsigned(column_scan_index * 4 + key_pressed_row, 4);
                    key_valid_s <= '1';
                    current_state <= IDLE;
            
            end case;
        end if;
    end process;

    column      <= column_s;
    key_code    <= std_logic_vector(key_code_s);
    key_valid   <= key_valid_s;

end arch_keyboard;