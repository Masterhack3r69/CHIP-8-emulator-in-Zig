//! CHIP-8 Emulator - Main Entry Point
//!
//! Initializes SDL2, loads ROM, and runs the main emulator loop.

const std = @import("std");
const sdl = @import("zsdl2");

// Emulator modules
const memory_module = @import("memory.zig");
const Memory = memory_module.Memory;
const PROGRAM_START = memory_module.PROGRAM_START;
const Bus = @import("bus.zig").Bus;
const Rom = @import("rom.zig").Rom;
const Cpu = @import("cpu.zig").Cpu;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;
const Timer = @import("timer.zig").Timer;

// CHIP-8 display is 64x32, we scale by 10 for visibility
const SCALE: u32 = 10;
const WINDOW_WIDTH: u32 = 64 * SCALE;
const WINDOW_HEIGHT: u32 = 32 * SCALE;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: console-emulator <rom_path>\n", .{});
        std.debug.print("Example: console-emulator roms/test.ch8\n", .{});
        return;
    }

    const rom_path = args[1];

    // Initialize memory with fontset
    var memory = Memory.init();
    std.debug.print("Memory initialized (4KB with fontset)\n", .{});

    // Load ROM
    var rom = Rom.load(allocator, rom_path) catch |err| {
        switch (err) {
            error.FileNotFound => std.debug.print("Error: ROM file not found: {s}\n", .{rom_path}),
            error.RomTooLarge => std.debug.print("Error: ROM too large (max 3584 bytes)\n", .{}),
            error.EmptyRom => std.debug.print("Error: ROM file is empty\n", .{}),
            error.ReadError => std.debug.print("Error: Failed to read ROM file\n", .{}),
        }
        return;
    };
    defer rom.deinit(allocator);

    // Load ROM into memory
    try memory.loadRom(rom.data);
    std.debug.print("Loaded ROM: {s} ({d} bytes)\n", .{ rom_path, rom.size });

    // Create bus
    var bus = Bus.init(&memory);

    // Print first opcode for verification
    const first_opcode = bus.readWord(PROGRAM_START);
    std.debug.print("PC starting at: 0x{X:0>3}\n", .{PROGRAM_START});
    std.debug.print("First opcode: 0x{X:0>4}\n", .{first_opcode});

    // Initialize SDL2
    try sdl.init(.{ .video = true, .events = true });
    defer sdl.quit();

    // Create window
    const window = try sdl.Window.create(
        "CHIP-8 Emulator",
        sdl.Window.pos_undefined,
        sdl.Window.pos_undefined,
        @intCast(WINDOW_WIDTH),
        @intCast(WINDOW_HEIGHT),
        .{},
    );
    defer window.destroy();

    // Create renderer
    const renderer = try sdl.Renderer.create(window, null, .{ .accelerated = true, .present_vsync = true });
    defer renderer.destroy();

    std.debug.print("CHIP-8 Emulator started. Press ESC or close window to exit.\n", .{});

    // Main loop
    var running = true;
    var event: sdl.Event = undefined;

    while (running) {
        // Handle events
        while (sdl.pollEvent(&event)) {
            switch (event.type) {
                .quit => running = false,
                .keydown => {
                    if (event.key.keysym.sym == .escape) {
                        running = false;
                    }
                },
                else => {},
            }
        }

        // Clear screen (black)
        try renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
        try renderer.clear();

        // Present
        renderer.present();
    }

    std.debug.print("Emulator shutdown complete.\n", .{});
}
