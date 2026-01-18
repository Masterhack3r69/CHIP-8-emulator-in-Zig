//! CHIP-8 Bus Module
//!
//! The Bus is the single point of access for all memory operations.
//! CPU never accesses RAM/ROM/IO directly - everything goes through Bus.
//!
//! Memory Map:
//! 0x000-0x1FF: Reserved (fontset + interpreter)
//! 0x200-0xFFF: Program ROM and RAM

const Memory = @import("memory.zig").Memory;

/// Memory Bus - routes reads/writes to appropriate components
pub const Bus = struct {
    memory: *Memory,

    /// Create bus with memory reference
    pub fn init(memory: *Memory) Bus {
        return Bus{
            .memory = memory,
        };
    }

    /// Read byte from address
    pub fn read(self: *const Bus, addr: u16) u8 {
        return self.memory.read(addr);
    }

    /// Write byte to address
    pub fn write(self: *Bus, addr: u16, value: u8) void {
        self.memory.write(addr, value);
    }

    /// Read 16-bit word (big-endian, for opcodes)
    pub fn readWord(self: *const Bus, addr: u16) u16 {
        const high: u16 = self.read(addr);
        const low: u16 = self.read(addr + 1);
        return (high << 8) | low;
    }
};
