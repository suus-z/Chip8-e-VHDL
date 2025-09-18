library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_rtl is
    port(
        clk        :   in std_logic;
        rst        :   in std_logic;
        m          :   in std_logic;
        hex0       :   out std_logic_vector(6 downto 0);
        hex1       :   out std_logic_vector(6 downto 0);
        hex2       :   out std_logic_vector(6 downto 0);
        hex3       :   out std_logic_vector(6 downto 0);
        hex4       :   out std_logic_vector(6 downto 0);
        hex5       :   out std_logic_vector(6 downto 0)
    );
end timer_rtl;

architecture rtl of timer_rtl is

    signal s_u  :   unsigned(3 downto 0)    := (others => '0');
    signal s_d  :   unsigned(3 downto 0)    := (others => '0');
    signal m_u  :   unsigned(3 downto 0)    := (others => '0');
    signal m_d  :   unsigned(3 downto 0)    := (others => '0');
    signal h_u  :   unsigned(3 downto 0)    := (others => '0');
    signal h_d  :   unsigned(3 downto 0)    := (others => '0');

    component timer is
    generic (clockFreq  :   integer := 50e6);

    port(
        clk           :   in          std_logic;
        rst           :   in          std_logic;
        s_u, m_u, h_u :   out         unsigned (3 downto 0);
        s_d, m_d, h_d :   out         unsigned (3 downto 0)
    );
    end component;

    component display is
    port(
        a           : in unsigned (3 downto 0);
        m           : in std_logic;
        s           : out std_logic_vector (6 downto 0)
    );
    end component;


begin

    timer_n: timer port map(
        clk => clk,
        rst => rst,
        s_u => s_u,
        m_u => m_u,
        h_u => h_u,
        s_d => s_d,
        m_d => m_d,
        h_d => h_d
    );

    display_HEX0: display port map(s_u, m, hex0);
    display_HEX1: display port map(s_d, m, hex1);

    display_HEX2: display port map(m_u, m, hex2);
    display_HEX3: display port map(m_d, m, hex3);

    display_HEX4: display port map(h_u, m, hex4);
    display_HEX5: display port map(h_d, m, hex5);

end rtl;