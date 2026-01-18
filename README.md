# CHIP-8 Emulator

A cycle-accurate CHIP-8 emulator written in Zig with SDL3 for graphics and input.

## Building

```bash
zig build
```

## Running

```bash
zig build run
# Or directly:
./zig-out/bin/console-emulator.exe
```

## Architecture

```
CPU → Bus → RAM / ROM / IO
```

All memory access goes through the Bus - no direct CPU access to memory.

## Modules

| Module        | Purpose                   |
| ------------- | ------------------------- |
| `cpu.zig`     | Fetch-decode-execute loop |
| `bus.zig`     | Memory address routing    |
| `memory.zig`  | 4KB RAM/ROM storage       |
| `display.zig` | 64×32 framebuffer         |
| `input.zig`   | 16-key hex keypad         |
| `timer.zig`   | Delay and sound timers    |
| `rom.zig`     | ROM file loading          |

## Controls

| Key  | CHIP-8 Key    |
| ---- | ------------- |
| 1-4  | 1-C (top row) |
| QWER | 4-D           |
| ASDF | 7-E           |
| ZXCV | A-F           |
| ESC  | Quit          |

## Status

🚧 Phase 0 - Project setup complete
