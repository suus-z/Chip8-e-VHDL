package ram_constants is
    constant font_size          : integer := 80;    --Memory block for sprites                  (0x000 to 0x04F)
    constant system_data_size   : integer := 432;   --Memory block for other system data        (0x050 to 0x1FF)
    constant prog_limit_size    : integer := 3328;  --Memory block for programs                 (0x200 to 0xEFF)
    constant display_size       : integer := 256;   --Memory block for the VGA display          (0xF00 to 0xFFF)
end package ram_constants;