//! CHIP-8 Emulator - Main Entry Point

const std = @import("std");
const sdl = @import("zsdl2");

const memory_module = @import("memory.zig");
const Memory = memory_module.Memory;
const Bus = @import("bus.zig").Bus;
const Rom = @import("rom.zig").Rom;
const Cpu = @import("cpu.zig").Cpu;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;
const Timer = @import("timer.zig").Timer;

const SCALE: u32 = 10;
const WINDOW_WIDTH: u32 = 64 * SCALE;
const WINDOW_HEIGHT: u32 = 32 * SCALE;

// CHIP-8 typically runs at 500-1000 Hz. Pong works well at ~500 Hz.
const CPU_HZ: u32 = 500;
const CYCLES_PER_FRAME: u32 = CPU_HZ / 60; // ~8 cycles per frame

/// Map SDL scancode to CHIP-8 key (0-F)
fn mapKey(scancode: sdl.Scancode) ?u4 {
    return switch (scancode) {
        .@"1" => 0x1,
        .@"2" => 0x2,
        .@"3" => 0x3,
        .@"4" => 0xC,
        .q => 0x4,
        .w => 0x5,
        .e => 0x6,
        .r => 0xD,
        .a => 0x7,
        .s => 0x8,
        .d => 0x9,
        .f => 0xE,
        .z => 0xA,
        .x => 0x0,
        .c => 0xB,
        .v => 0xF,
        else => null,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: console-emulator <rom_path>\n", .{});
        return;
    }

    var memory = Memory.init();
    var display = Display.init();
    var cpu = Cpu.init();
    var input = Input.init();
    var timer = Timer.init();

    var rom = Rom.load(allocator, args[1]) catch |err| {
        switch (err) {
            error.FileNotFound => std.debug.print("Error: ROM not found: {s}\n", .{args[1]}),
            error.RomTooLarge => std.debug.print("Error: ROM too large\n", .{}),
            error.EmptyRom => std.debug.print("Error: Empty ROM\n", .{}),
            error.ReadError => std.debug.print("Error: Read failed\n", .{}),
        }
        return;
    };
    defer rom.deinit(allocator);

    try memory.loadRom(rom.data);
    std.debug.print("Loaded: {s} ({d} bytes)\n", .{ args[1], rom.size });

    var bus = Bus.init(&memory);

    try sdl.init(.{ .video = true, .events = true });
    defer sdl.quit();

    const window = try sdl.Window.create(
        "CHIP-8 Emulator",
        sdl.Window.pos_undefined,
        sdl.Window.pos_undefined,
        @intCast(WINDOW_WIDTH),
        @intCast(WINDOW_HEIGHT),
        .{},
    );
    defer window.destroy();

    const renderer = try sdl.Renderer.create(window, null, .{ .accelerated = true, .present_vsync = true });
    defer renderer.destroy();

    std.debug.print("Running. Keys: 1/Q (up/down). ESC to exit.\n", .{});

    var running = true;
    var event: sdl.Event = undefined;

    // Frame timing
    var last_time = std.time.milliTimestamp();

    while (running) {
        // Events
        while (sdl.pollEvent(&event)) {
            switch (event.type) {
                .quit => running = false,
                .keydown => {
                    if (event.key.keysym.sym == .escape) {
                        running = false;
                    } else if (mapKey(event.key.keysym.scancode)) |chip8_key| {
                        input.keyDown(chip8_key);
                    }
                },
                .keyup => {
                    if (mapKey(event.key.keysym.scancode)) |chip8_key| {
                        input.keyUp(chip8_key);
                    }
                },
                else => {},
            }
        }

        // Frame timing - 60 FPS
        const now = std.time.milliTimestamp();
        const elapsed = now - last_time;

        if (elapsed >= 16) { // ~60 FPS (16.67ms per frame)
            last_time = now;

            // CPU cycles for this frame
            for (0..CYCLES_PER_FRAME) |_| {
                cpu.cycle(&bus, &display, &input, &timer);
            }

            // Timer tick (60Hz)
            timer.tick();

            // Always render every frame (reduces flicker)
            try renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
            try renderer.clear();

            try renderer.setDrawColor(.{ .r = 255, .g = 255, .b = 255, .a = 255 });
            for (0..32) |y| {
                for (0..64) |x| {
                    if (display.getPixel(@intCast(x), @intCast(y))) {
                        try renderer.fillRect(.{
                            .x = @intCast(x * SCALE),
                            .y = @intCast(y * SCALE),
                            .w = @intCast(SCALE),
                            .h = @intCast(SCALE),
                        });
                    }
                }
            }

            renderer.present();
            display.clearDirty();
        } else {
            // Small sleep to avoid busy-waiting
            std.Thread.sleep(1_000_000); // 1ms
        }
    }

    std.debug.print("Exited.\n", .{});
}
