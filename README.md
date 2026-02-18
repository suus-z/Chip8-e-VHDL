<pre> ```mermaid <em>
  %% Diagrama de blocos da arquitetura Chip8 (Beta Syntax)
block-beta
    %% Definindo duas colunas principais
    columns 2

    %% CPU do CHIP-8
    block:CPU
        CPU[CPU Chip8]
        FetchDecode[Fetch & Decode]
        Exec[Execution Unit]
    end

    %% Memória e Periféricos
    block:MEMORY_IO
        RAM[(Memory / RAM)]
        ROM[(ROM / Font)]
        DISP[Display & VRAM]
        KEYPAD[Keypad]
        TIMER[Timers]
        SOUND[Sound Timer]
    end

    %% Entradas e saídas
    block:IO
        CLK(Clock)
        RESET(Reset)
    end

    %% Conexões
    CLK --> CPU
    RESET --> CPU

    CPU --> FetchDecode
    FetchDecode --> Exec
    Exec --> RAM
    Exec --> ROM
    Exec --> DISP
    Exec --> KEYPAD
    Exec --> TIMER
    Exec --> SOUND

</em> ``` </pre>
