--Relógio digital

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    generic (clockFreq  :   integer := 50e6);

    port(
        clk           :   in          std_logic;
        rst           :   in          std_logic;
        s_u, m_u, h_u :   out         unsigned (3 downto 0);
        s_d, m_d, h_d :   out         unsigned (3 downto 0)
    );
end timer;

architecture rtl of timer is
    signal counter   : integer range 0 to clockFreq-1 :=0;
    signal s_u_s     : unsigned(3 downto 0) := (others => '0');
    signal m_u_s     : unsigned(3 downto 0) := (others => '0');
    signal h_u_s     : unsigned(3 downto 0) := (others => '0');
    signal s_d_s     : unsigned(3 downto 0) := (others => '0');
    signal m_d_s     : unsigned(3 downto 0) := (others => '0');
    signal h_d_s     : unsigned(3 downto 0) := (others => '0');

    begin

        process(clk, rst)
        begin

            if rst = '1' then
                counter <= 0;
                s_u_s     <= (others => '0');
                m_u_s     <= (others => '0');
                h_u_s     <= (others => '0');
                s_d_s     <= (others => '0');
                m_d_s     <= (others => '0');
                h_d_s     <= (others => '0');

            elsif rising_edge(clk) then

                if counter = clockFreq - 1 then
                    counter <= 0;

                    if s_u_s = 9 then
                        s_u_s <= to_unsigned(0, 4);
                        if s_d_s = 5 then
                            s_d_s <= to_unsigned(0, 4);

                            if m_u_s = 9 then
                                m_u_s <= to_unsigned(0, 4);
                                if m_d_s = 5 then
                                    m_d_s <= to_unsigned(0, 4);

                                    if (h_d_s = 2 and h_u_s = 3) then
                                        h_d_s <= to_unsigned(0, 4);
                                        h_u_s <= to_unsigned(0, 4);
                                    elsif (h_u_s = 9) then
                                        h_u_s <= to_unsigned(0, 4);
                                        h_d_s <= h_d_s + 1;
                                    else
                                        h_u_s <= h_u_s + 1;
                                    end if;
                                
                                else
                                    m_d_s <= m_d_s + 1;
                                end if;
                            else
                                m_u_s <= m_u_s + 1;
                            end if;

                        else
                            s_d_s <= s_d_s + 1;
                        end if;
                    else
                        s_u_s <= s_u_s + 1;
                    end if;

                else
                    counter <= counter + 1;
                end if;

            end if;

        end process;

        s_u <= s_u_s;
        s_d <= s_d_s;
        m_u <= m_u_s;
        m_d <= m_d_s;
        h_u <= h_u_s;
        h_d <= h_d_s;

end rtl;