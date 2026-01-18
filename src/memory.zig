//! CHIP-8 Memory Module
//!
//! Manages 4KB RAM with built-in fontset.
//!
//! Memory Map:
//! 0x000-0x04F: Fontset (80 bytes)
//! 0x050-0x1FF: Reserved
//! 0x200-0xFFF: Program ROM + RAM

const std = @import("std");

/// Total addressable memory (4KB)
pub const MEMORY_SIZE: u16 = 4096;

/// Program start address
pub const PROGRAM_START: u16 = 0x200;

/// Maximum ROM size (0xFFF - 0x200 + 1 = 3584 bytes)
pub const MAX_ROM_SIZE: u16 = MEMORY_SIZE - PROGRAM_START;

/// CHIP-8 built-in fontset (0-F characters, 5 bytes each = 80 bytes)
/// Each character is 4 pixels wide × 5 pixels tall
const FONTSET: [80]u8 = .{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

/// Memory storage
pub const Memory = struct {
    ram: [MEMORY_SIZE]u8,

    /// Initialize memory with fontset
    pub fn init() Memory {
        var mem = Memory{
            .ram = [_]u8{0} ** MEMORY_SIZE,
        };
        // Load fontset at 0x000
        @memcpy(mem.ram[0..FONTSET.len], &FONTSET);
        return mem;
    }

    /// Read byte from memory
    pub fn read(self: *const Memory, addr: u16) u8 {
        if (addr >= MEMORY_SIZE) {
            std.debug.print("Memory read out of bounds: 0x{X:0>3}\n", .{addr});
            return 0;
        }
        return self.ram[addr];
    }

    /// Write byte to memory
    pub fn write(self: *Memory, addr: u16, value: u8) void {
        if (addr >= MEMORY_SIZE) {
            std.debug.print("Memory write out of bounds: 0x{X:0>3}\n", .{addr});
            return;
        }
        self.ram[addr] = value;
    }

    /// Load ROM data into memory at PROGRAM_START (0x200)
    pub fn loadRom(self: *Memory, data: []const u8) !void {
        if (data.len > MAX_ROM_SIZE) {
            return error.RomTooLarge;
        }
        @memcpy(self.ram[PROGRAM_START .. PROGRAM_START + data.len], data);
    }

    /// Get font sprite address for character (0-F)
    pub fn getFontAddress(char: u4) u16 {
        return @as(u16, char) * 5;
    }
};
