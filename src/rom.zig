//! CHIP-8 ROM Loader Module
//!
//! Loads ROM files into memory at address 0x200.

const std = @import("std");
const memory = @import("memory.zig");
const MAX_ROM_SIZE = memory.MAX_ROM_SIZE;

pub const RomError = error{
    FileNotFound,
    ReadError,
    RomTooLarge,
    EmptyRom,
};

/// ROM loader and validator
pub const Rom = struct {
    data: []const u8,
    size: usize,

    /// Load ROM from file path
    pub fn load(allocator: std.mem.Allocator, path: []const u8) !Rom {
        const file = std.fs.cwd().openFile(path, .{}) catch {
            return RomError.FileNotFound;
        };
        defer file.close();

        const stat = file.stat() catch {
            return RomError.ReadError;
        };

        if (stat.size == 0) {
            return RomError.EmptyRom;
        }

        if (stat.size > MAX_ROM_SIZE) {
            return RomError.RomTooLarge;
        }

        const data = file.readToEndAlloc(allocator, MAX_ROM_SIZE) catch {
            return RomError.ReadError;
        };

        return Rom{
            .data = data,
            .size = data.len,
        };
    }

    /// Free ROM data
    pub fn deinit(self: *Rom, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
        self.data = &.{};
        self.size = 0;
    }
};
