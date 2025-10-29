package framebuffer_constants is
  constant HSYNC    : integer := 96;
  constant H_BP     : integer := 48;
  constant H_ACTIVE : integer := 640;
  constant H_FP     : integer := 16;
  constant H_TOTAL  : integer := 800;

  constant VSYNC    : integer := 2;
  constant V_BP     : integer := 33;
  constant V_ACTIVE : integer := 480;
  constant V_FP     : integer := 10;
  constant V_TOTAL  : integer := 525;

  constant CHIP8_W  : integer := 64;
  constant CHIP8_H  : integer := 32;
end package framebuffer_constants;