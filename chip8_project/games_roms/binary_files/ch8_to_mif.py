# ch8_to_mif.py
# Converts any .ch8 file to .mif ready to use on Quartus
import os

# ===== CONFIGS =====
input_file = input("File name .ch8 (with extension): ").strip()
output_file = os.path.splitext(input_file)[0] + ".mif"

MEMORY_DEPTH = 4096
MEMORY_WIDTH = 8
PROGRAM_START = 0x200  # Chip-8 programs start here

# ===== CHIP-8 FONT SET =====
# Each sprite (0–F) ocupa 5 bytes
FONT_SET = [
    0xF0, 0x90, 0x90, 0x90, 0xF0,  # 0
    0x20, 0x60, 0x20, 0x20, 0x70,  # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,  # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,  # 3
    0x90, 0x90, 0xF0, 0x10, 0x10,  # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,  # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,  # 6
    0xF0, 0x10, 0x20, 0x40, 0x40,  # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,  # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,  # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,  # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,  # B
    0xF0, 0x80, 0x80, 0x80, 0xF0,  # C
    0xE0, 0x90, 0x90, 0x90, 0xE0,  # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,  # E
    0xF0, 0x80, 0xF0, 0x80, 0x80   # F
]
FONT_END = len(FONT_SET)  # Deve ser 80 bytes (0x50)

# ===== READ .CH8 FILE =====
with open(input_file, "rb") as f:
    data = f.read()

# ===== GENERATE .MIF =====
with open(output_file, "w") as f:
    f.write(f"WIDTH={MEMORY_WIDTH};\n")
    f.write(f"DEPTH={MEMORY_DEPTH};\n\n")
    f.write("ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    # Escreve os sprites 0–F (0x000–0x04F)
    for addr, byte in enumerate(FONT_SET):
        f.write(f"  {addr:03X} : {byte:02X};\n")

    # Preenche o restante até o início do programa (0x200) com 0x00
    f.write(f"  [{FONT_END:03X}..{PROGRAM_START-1:03X}] : 00;\n")

    # Escreve o programa a partir de 0x200
    for addr, byte in enumerate(data):
        f.write(f"  {addr + PROGRAM_START:03X} : {byte:02X};\n")

    # Preenche o restante até o final da RAM com 0x00
    last_addr = len(data) + PROGRAM_START
    f.write(f"  [{last_addr:03X}..{MEMORY_DEPTH-1:03X}] : 00;\n")

    f.write("END;\n")

print(f"\n✅ MIF file successfully generated: {output_file}")