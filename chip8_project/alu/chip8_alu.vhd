--CHIP-8 ALU
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instructions_constants.all;

entity chip8_alu is
    port (
        -- Inputs
        op_code_in : in  std_logic_vector(5 downto 0); --The 6-bit opcode from the instruction
        data_a_in  : in  std_logic_vector(7 downto 0); --First operand (e.g., Vx)
        data_b_in  : in  std_logic_vector(7 downto 0); --Second operand (e.g., Vy or kk)
        i_reg_in   : in  std_logic_vector(11 downto 0); --Actual value of I register
        
        -- Outputs
        result_out : out std_logic_vector(7 downto 0);  --Result of the operation
        vf_flag    : out std_logic;                     --The VF (carry/borrow) flag
        i_add_out  : out std_logic_vector(11 downto 0)  --Result for the I_ADD_I_Vx instruction
    );
end entity chip8_alu;

architecture behavioral of chip8_alu is
begin
    process(op_code_in, data_a_in, data_b_in)
        --Temporary variables to hold intermediate results
        variable temp_result_8bit  : unsigned(7 downto 0);
        variable temp_result_9bit  : unsigned(8 downto 0);
        variable temp_result_17bit : unsigned(16 downto 0);
    begin
        --Default values for outputs
        result_out <= (others => '0');
        vf_flag    <= '0';
        i_add_out  <= (others => '0');

        case op_code_in is
            --8XY4: ADD Vx, Vy (with carry)
            when I_ADD_Vx_Vy =>
                temp_result_9bit := unsigned('0' & data_a_in) + unsigned('0' & data_b_in);
                result_out <= std_logic_vector(temp_result_9bit(7 downto 0));
                vf_flag    <= temp_result_9bit(8);
            
            --8XY5: SUB Vx, Vy (set VF = NOT borrow)
            when I_SUB =>
                temp_result_9bit := unsigned('0' & data_a_in) - unsigned('0' & data_b_in);
                result_out <= std_logic_vector(temp_result_9bit(7 downto 0));
                if unsigned(data_a_in) >= unsigned(data_b_in) then
                    vf_flag <= '1';
                else
                    vf_flag <= '0';
                end if;
            
            --8XY7: SUBN Vx, Vy (subtrai Vx de Vy, set VF = NOT borrow)
            when I_SUBN =>
                temp_result_9bit := unsigned('0' & data_b_in) - unsigned('0' & data_a_in);
                result_out <= std_logic_vector(temp_result_9bit(7 downto 0));
                if unsigned(data_b_in) >= unsigned(data_a_in) then
                    vf_flag <= '1';
                else
                    vf_flag <= '0';
                end if;
                
            --8XY1: OR Vx, Vy
            when I_OR =>
                result_out <= data_a_in or data_b_in;
                
            --8XY2: AND Vx, Vy
            when I_AND =>
                result_out <= data_a_in and data_b_in;
                
            --8XY3: XOR Vx, Vy
            when I_XOR =>
                result_out <= data_a_in xor data_b_in;
                
            --8XY6: SHR Vx {, Vy}
            when I_SHR =>
                result_out <= '0' & data_a_in(7 downto 1);
                vf_flag    <= data_a_in(0);
                
            --8XYE: SHL Vx {, Vy}
            when I_SHL =>
                result_out <= data_a_in(6 downto 0) & '0';
                vf_flag    <= data_a_in(7);
                
            --7XKK: ADD Vx, kk
            when I_ADD_Vx_kk =>
                temp_result_8bit := unsigned(data_a_in) + unsigned(data_b_in);
                result_out <= std_logic_vector(temp_result_8bit);
                
            --FX1E: ADD I, Vx (This operation has a 16-bit output)
            when I_ADD_I_Vx =>
                i_add_out <= std_logic_vector(unsigned(i_reg_in) + resize(unsigned(data_a_in), 12));

            --If the opcode is not a known ALU operation, set outputs to a default value
            when others =>
                result_out <= (others => '0');
                vf_flag    <= '0';
                i_add_out  <= (others => '0');
                
        end case;
    end process;
end architecture behavioral;