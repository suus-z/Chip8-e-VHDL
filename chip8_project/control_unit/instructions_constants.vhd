--CHIP-8 constants list

--Descriptions written by: 
--https://www.cs.columbia.edu/~sedwards/classes/2016/4840-spring/designs/Chip8.pdf. 

library ieee;
use ieee.std_logic_1164.all;

package instructions_constants is 
        -- instruction encodings (6-bit)
    constant I_CLS      : std_logic_vector(5 downto 0) := "000000"; --Clear the screen
    constant I_RET      : std_logic_vector(5 downto 0) := "000001"; --Return from a subroutine.The interpreter sets the program counter to the address at the top of the stack, then subtracts 1 from the stack pointer.
    constant I_SYS      : std_logic_vector(5 downto 0) := "000010"; --Jump to a machine code routine at nnn. This instruction is only used on the old computers on which Chip-8 was originally implemented. It is ignored by modern interpreters.
    constant I_JP       : std_logic_vector(5 downto 0) := "000011"; --Jump to location nnn. The interpreter sets the program counter to nnn.
    constant I_CALL     : std_logic_vector(5 downto 0) := "000100"; --Call subroutine at nnn. The interpreter increments the stack pointer, then puts the current PC on the top of the stack. The PC is then set to nnn
    constant I_SE_Vx_kk : std_logic_vector(5 downto 0) := "000101"; --Skip next instruction if Vx = kk. The interpreter compares register Vx to kk, and if they are equal, increments the program counter by 2.
    constant I_SNE_Vx_kk: std_logic_vector(5 downto 0) := "000110"; --Skip next instruction if Vx != kk. The interpreter compares register Vx to kk, and if they are not equal, increments the program counter by 2.
    constant I_SE_Vx_Vy : std_logic_vector(5 downto 0) := "000111"; --Skip next instruction if Vx = Vy. The interpreter compares register Vx to register Vy, and if they are equal, increments the program counter by 2.
    constant I_LD_Vx_kk : std_logic_vector(5 downto 0) := "001000"; --Set Vx = kk. The interpreter puts the value kk into register Vx.
    constant I_ADD_Vx_kk: std_logic_vector(5 downto 0) := "001001"; --Set Vx = Vx + kk. Adds the value kk to the value of register Vx, then stores the result in Vx
    constant I_LD_Vx_Vy : std_logic_vector(5 downto 0) := "001010"; --Set Vx = Vy. Stores the value of register Vy in register Vx.
    constant I_OR       : std_logic_vector(5 downto 0) := "001011"; --Set Vx = Vx OR Vy. Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx. A bitwise OR compares the corresponding bits from two values, and if either bit is 1, then the same bit in the result is also 1. Otherwise, it is 0.
    constant I_AND      : std_logic_vector(5 downto 0) := "001100"; --Set Vx = Vx AND Vy. Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx. A bitwise AND compares the corresponding bits from two values, and if both bits are 1, then the same bit in the result is also 1. Otherwise, it is 0.
    constant I_XOR      : std_logic_vector(5 downto 0) := "001101"; --Set Vx = Vx XOR Vy. Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx. An exclusive OR compares the corresponding bits from two values, and if the bits are not both the same, then the corresponding bit in the result is set to 1. Otherwise, it is 0
    constant I_ADD_Vx_Vy: std_logic_vector(5 downto 0) := "001110"; --Set Vx = Vx + Vy, set VF = carry. The values of Vx and Vy are added together. If the result is greater than 8 bits (i.e., 255,) VF is set to 1, otherwise 0. Only the lowest 8 bits of the result are kept, and stored in Vx.
    constant I_SUB      : std_logic_vector(5 downto 0) := "001111"; --Set Vx = Vx- Vy, set VF = NOT borrow. If Vx Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results stored in Vx.
    constant I_SHR      : std_logic_vector(5 downto 0) := "010000"; --Set Vx = Vx SHR 1. If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
    constant I_SUBN     : std_logic_vector(5 downto 0) := "010001"; --Set Vx = Vy- Vx, set VF = NOT borrow. If Vy Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy, and the results stored in Vx.
    constant I_SHL      : std_logic_vector(5 downto 0) := "010010"; --Set Vx = Vx SHL 1. If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
    constant I_SNE_Vx_Vy: std_logic_vector(5 downto 0) := "010011"; --Skip next instruction if Vx != Vy. The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
    constant I_LD_I     : std_logic_vector(5 downto 0) := "010100"; --Set I = nnn. The value of register I is set to nnn.
    constant I_JP_V0    : std_logic_vector(5 downto 0) := "010101"; --Jump to location nnn + V0. The program counter is set to nnn plus the value of V0.
    constant I_RND      : std_logic_vector(5 downto 0) := "010110"; --Set Vx = random byte AND kk. The interpreter generates a random number from 0 to 255, which is then ANDed with the value kk. The results are stored in Vx. See instruction 8xy2 for more information on AND.
    constant I_DRW      : std_logic_vector(5 downto 0) := "010111"; --Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision. The interpreter reads n bytes from memory, starting at the address stored in I. These bytes are then displayed as sprites on screen at coordinates (Vx, Vy). Sprites are XORd onto the existing screen. If this causes any pixels to be erased, VF is set to 1, otherwise it is set to 0. If the sprite is positioned so part of it is outside the coordinates of the display, it wraps around to the opposite side of the screen.
    constant I_SKP      : std_logic_vector(5 downto 0) := "011000"; --Skip next instruction if key with the value of Vx is pressed. Checks the keyboard, and if the key corresponding to the value of Vx is currently in the down position, PC is increased by 2.
    constant I_SKNP     : std_logic_vector(5 downto 0) := "011001"; --Skip next instruction if key with the value of Vx is not pressed. Checks the keyboard, and if the key corresponding to the value of Vx is currently in the up position, PC is increased by 2.
    constant I_LD_Vx_DT : std_logic_vector(5 downto 0) := "011010"; --Set Vx = delay timer value. The value of DT is placed into Vx.
    constant I_LD_Vx_K  : std_logic_vector(5 downto 0) := "011011"; --Wait for a key press, store the value of the key in Vx. All execution stops until a key is pressed, then the value of that key is stored in Vx.
    constant I_LD_DT_Vx : std_logic_vector(5 downto 0) := "011100"; --Set delay timer = Vx. Delay Timer is set equal to the value of Vx.
    constant I_LD_ST_Vx : std_logic_vector(5 downto 0) := "011101"; --Set sound timer = Vx. Sound Timer is set equal to the value of Vx.
    constant I_ADD_I_Vx : std_logic_vector(5 downto 0) := "011110"; --Set I = I + Vx. The values of I and Vx are added, and the results are stored in I.
    constant I_LD_F     : std_logic_vector(5 downto 0) := "011111"; --Set I = location of sprite for digit Vx. The value of I is set to the location for the hexadecimal sprite corresponding to the value of Vx. See section 2.4, Display, for more information on the Chip-8 hexadecimal font. To obtain this value, multiply VX by 5 (all font data stored in rst 80 bytes of memory).
    constant I_LD_B     : std_logic_vector(5 downto 0) := "100000"; --Store BCD representation of Vx in memory locations I, I+1, and I+2. The interpreter takes the decimal value of Vx, and places the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.
    constant I_LD_I_Vx  : std_logic_vector(5 downto 0) := "100001"; --Stores V0 to VX in memory starting at address I. I is then set to I + x + 1.
    constant I_LD_Vx_I  : std_logic_vector(5 downto 0) := "100010"; --Fx65 Fills V0 to VX with values from memory starting at address I. I is then set to I + x + 1.
    constant I_ILLEGAL  : std_logic_vector(5 downto 0) := "111111"; --Illegal instruction.
end package instructions_constants;