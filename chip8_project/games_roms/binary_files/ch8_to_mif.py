# ch8_to_mif.py
# Converts any .ch8 file to .mif ready to use on Quartus
import os

# ===== CONFIGS =====
input_file = input("File name .ch8 (with extension): ").strip()
output_file = os.path.splitext(input_file)[0] + ".mif"

MEMORY_DEPTH = 4096
MEMORY_WIDTH = 8
PROGRAM_START = 0x200  # Chip-8 programs start here

# ===== BINARY FILE READ =====
with open(input_file, "rb") as f:
    data = f.read()

# ===== .MIF FILE GENERATION =====
with open(output_file, "w") as f:
    f.write(f"WIDTH={MEMORY_WIDTH};\n")
    f.write(f"DEPTH={MEMORY_DEPTH};\n\n")
    f.write("ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    # Fill memory before program with zeros
    f.write(f"  [000..{PROGRAM_START-1:03X}] : 00;\n")

    # Write program bytes starting at 0x200
    for addr, byte in enumerate(data):
        f.write(f"  {addr + PROGRAM_START:03X} : {byte:02X};\n")

    # Fill the rest with zeros
    f.write(f"  [{len(data)+PROGRAM_START:03X}..{MEMORY_DEPTH-1:03X}] : 00;\n")
    f.write("END;\n")

print(f"\nMIF file successfully generated: {output_file}")