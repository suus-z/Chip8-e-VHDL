-- decoder.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;

entity decoder is
    port(
        opcode  : in  std_logic_vector(15 downto 0);
        --extracted fields
        nnn     : out std_logic_vector(11 downto 0);
        kk      : out std_logic_vector(7 downto 0);
        x       : out std_logic_vector(3 downto 0);
        y       : out std_logic_vector(3 downto 0);
        n       : out std_logic_vector(3 downto 0);
        --decoded instruction code
        instr   : out std_logic_vector(5 downto 0);
        illegal : out std_logic
    );
end decoder;

architecture rtl of decoder is
begin

    --extract basic fields
    nnn <= opcode(11 downto 0);
    kk  <= opcode(7 downto 0);
    x   <= opcode(11 downto 8);
    y   <= opcode(7 downto 4);
    n   <= opcode(3 downto 0);

    --combinational decode
    process(opcode)
    begin
        --defaults
        instr   <= I_ILLEGAL;
        illegal <= '1';

        case opcode(15 downto 12) is
            when "0000" =>
                -- 0x00E0 CLS, 00EE RET, 0nnn SYS (ignored)
                if opcode = x"00E0" then
                    instr <= I_CLS; illegal <= '0';
                elsif opcode = x"00EE" then
                    instr <= I_RET; illegal <= '0';
                else
                    -- SYS nnn (legacy) -> mark as SYS (can be ignored upstream)
                    instr <= I_SYS; illegal <= '0';
                end if;

            when "0001" =>
                instr <= I_JP; illegal <= '0'; -- 1nnn

            when "0010" =>
                instr <= I_CALL; illegal <= '0'; -- 2nnn

            when "0011" =>
                instr <= I_SE_Vx_kk; illegal <= '0'; -- 3xkk

            when "0100" =>
                instr <= I_SNE_Vx_kk; illegal <= '0'; -- 4xkk

            when "0101" =>
                if opcode(3 downto 0) = "0000" then
                    instr <= I_SE_Vx_Vy; illegal <= '0'; -- 5xy0
                end if;

            when "0110" =>
                instr <= I_LD_Vx_kk; illegal <= '0'; -- 6xkk

            when "0111" =>
                instr <= I_ADD_Vx_kk; illegal <= '0'; -- 7xkk

            when "1000" =>
                case opcode(3 downto 0) is
                    when "0000" => instr <= I_LD_Vx_Vy;
                    when "0001" => instr <= I_OR;
                    when "0010" => instr <= I_AND;
                    when "0011" => instr <= I_XOR;
                    when "0100" => instr <= I_ADD_Vx_Vy;
                    when "0101" => instr <= I_SUB;
                    when "0110" => instr <= I_SHR;
                    when "0111" => instr <= I_SUBN;
                    when "1110" => instr <= I_SHL;
                    when others => instr <= I_ILLEGAL;
                end case;
                illegal <= '0';

            when "1001" =>
                if opcode(3 downto 0) = "0000" then
                    instr <= I_SNE_Vx_Vy; illegal <= '0';
                end if;

            when "1010" =>
                instr <= I_LD_I; illegal <= '0'; -- Annn

            when "1011" =>
                instr <= I_JP_V0; illegal <= '0'; -- Bnnn

            when "1100" =>
                instr <= I_RND; illegal <= '0'; -- Cxkk

            when "1101" =>
                instr <= I_DRW; illegal <= '0'; -- Dxyn

            when "1110" =>
                -- Ex9E, ExA1
                if opcode(7 downto 0) = x"9E" then
                    instr <= I_SKP; illegal <= '0';
                elsif opcode(7 downto 0) = x"A1" then
                    instr <= I_SKNP; illegal <= '0';
                end if;

            when "1111" =>
                -- Fx07, Fx0A, Fx15, Fx18, Fx1E, Fx29, Fx33, Fx55, Fx65
                case opcode(7 downto 0) is
                    when x"07" => instr <= I_LD_Vx_DT;
                    when x"0A" => instr <= I_LD_Vx_K;
                    when x"15" => instr <= I_LD_DT_Vx;
                    when x"18" => instr <= I_LD_ST_Vx;
                    when x"1E" => instr <= I_ADD_I_Vx;
                    when x"29" => instr <= I_LD_F;
                    when x"33" => instr <= I_LD_B;
                    when x"55" => instr <= I_LD_I_Vx;
                    when x"65" => instr <= I_LD_Vx_I;
                    when others => instr <= I_ILLEGAL;
                end case;
                illegal <= '0';

            when others =>
                instr <= I_ILLEGAL;
        end case;
    end process;

end rtl;