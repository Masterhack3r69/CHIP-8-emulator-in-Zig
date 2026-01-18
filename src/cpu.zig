//! CHIP-8 CPU Module
//!
//! Implements the CPU with registers, stack, and instruction execution.

const std = @import("std");
const Bus = @import("bus.zig").Bus;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;
const Timer = @import("timer.zig").Timer;
const memory_module = @import("memory.zig");
const PROGRAM_START = memory_module.PROGRAM_START;

/// CHIP-8 CPU state
pub const Cpu = struct {
    v: [16]u8, // V0-VF registers
    i: u16, // Index register
    pc: u16, // Program counter
    sp: u8, // Stack pointer
    stack: [16]u16, // 16-level stack

    /// Initialize CPU
    pub fn init() Cpu {
        return Cpu{
            .v = [_]u8{0} ** 16,
            .i = 0,
            .pc = PROGRAM_START,
            .sp = 0,
            .stack = [_]u16{0} ** 16,
        };
    }

    /// Execute one CPU cycle
    pub fn cycle(self: *Cpu, bus: *Bus, display: *Display, input: *Input, timer: *Timer) void {
        // If waiting for key, don't execute
        if (input.isWaitingForKey()) {
            return;
        }

        const opcode = bus.readWord(self.pc);
        self.pc += 2;
        self.execute(opcode, bus, display, input, timer);
    }

    fn execute(self: *Cpu, opcode: u16, bus: *Bus, display: *Display, input: *Input, timer: *Timer) void {
        const nnn = opcode & 0x0FFF;
        const n: u4 = @truncate(opcode & 0x000F);
        const x: u4 = @truncate((opcode & 0x0F00) >> 8);
        const y: u4 = @truncate((opcode & 0x00F0) >> 4);
        const kk: u8 = @truncate(opcode & 0x00FF);

        const first_nibble: u4 = @truncate((opcode & 0xF000) >> 12);
        switch (first_nibble) {
            0x0 => switch (opcode) {
                0x00E0 => display.clear(),
                0x00EE => {
                    self.sp -= 1;
                    self.pc = self.stack[self.sp];
                },
                else => {},
            },
            0x1 => self.pc = nnn,
            0x2 => {
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = nnn;
            },
            0x3 => if (self.v[x] == kk) {
                self.pc += 2;
            },
            0x4 => if (self.v[x] != kk) {
                self.pc += 2;
            },
            0x5 => if (self.v[x] == self.v[y]) {
                self.pc += 2;
            },
            0x6 => self.v[x] = kk,
            0x7 => self.v[x] +%= kk,
            0x8 => self.execute_8xy(x, y, n),
            0x9 => if (self.v[x] != self.v[y]) {
                self.pc += 2;
            },
            0xA => self.i = nnn,
            0xB => self.pc = nnn + self.v[0],
            0xC => {
                var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
                self.v[x] = prng.random().int(u8) & kk;
            },
            0xD => self.op_drw(x, y, n, bus, display),
            0xE => self.execute_ex(opcode, x, input),
            0xF => self.execute_fx(opcode, x, bus, input, timer),
        }
    }

    fn execute_8xy(self: *Cpu, x: u4, y: u4, n: u4) void {
        switch (n) {
            0x0 => self.v[x] = self.v[y],
            0x1 => self.v[x] |= self.v[y],
            0x2 => self.v[x] &= self.v[y],
            0x3 => self.v[x] ^= self.v[y],
            0x4 => {
                const result = @as(u16, self.v[x]) + @as(u16, self.v[y]);
                self.v[0xF] = if (result > 255) 1 else 0;
                self.v[x] = @truncate(result);
            },
            0x5 => {
                self.v[0xF] = if (self.v[x] >= self.v[y]) 1 else 0;
                self.v[x] -%= self.v[y];
            },
            0x6 => {
                self.v[0xF] = self.v[x] & 0x1;
                self.v[x] >>= 1;
            },
            0x7 => {
                self.v[0xF] = if (self.v[y] >= self.v[x]) 1 else 0;
                self.v[x] = self.v[y] -% self.v[x];
            },
            0xE => {
                self.v[0xF] = (self.v[x] & 0x80) >> 7;
                self.v[x] <<= 1;
            },
            else => {},
        }
    }

    fn execute_ex(self: *Cpu, opcode: u16, x: u4, input: *Input) void {
        switch (opcode & 0x00FF) {
            0x9E => { // EX9E - Skip if key pressed
                if (input.isPressed(@truncate(self.v[x] & 0x0F))) {
                    self.pc += 2;
                }
            },
            0xA1 => { // EXA1 - Skip if key not pressed
                if (!input.isPressed(@truncate(self.v[x] & 0x0F))) {
                    self.pc += 2;
                }
            },
            else => {},
        }
    }

    fn execute_fx(self: *Cpu, opcode: u16, x: u4, bus: *Bus, input: *Input, timer: *Timer) void {
        switch (opcode & 0x00FF) {
            0x07 => self.v[x] = timer.delay, // LD Vx, DT
            0x0A => { // LD Vx, K (wait for key)
                if (input.getLastKey()) |key| {
                    self.v[x] = key;
                } else {
                    input.startWaitingForKey();
                    self.pc -= 2; // Repeat this instruction
                }
            },
            0x15 => timer.delay = self.v[x], // LD DT, Vx
            0x18 => timer.sound = self.v[x], // LD ST, Vx
            0x1E => self.i +%= self.v[x],
            0x29 => self.i = memory_module.Memory.getFontAddress(@truncate(self.v[x])),
            0x33 => {
                bus.write(self.i, self.v[x] / 100);
                bus.write(self.i + 1, (self.v[x] / 10) % 10);
                bus.write(self.i + 2, self.v[x] % 10);
            },
            0x55 => {
                for (0..@as(usize, x) + 1) |idx| {
                    bus.write(self.i + @as(u16, @intCast(idx)), self.v[idx]);
                }
            },
            0x65 => {
                for (0..@as(usize, x) + 1) |idx| {
                    self.v[idx] = bus.read(self.i + @as(u16, @intCast(idx)));
                }
            },
            else => {},
        }
    }

    fn op_drw(self: *Cpu, x: u4, y: u4, n: u4, bus: *Bus, display: *Display) void {
        const x_pos = self.v[x] % 64;
        const y_pos = self.v[y] % 32;
        self.v[0xF] = 0;

        for (0..n) |row| {
            const sprite_byte = bus.read(self.i + @as(u16, @intCast(row)));
            for (0..8) |col| {
                if ((sprite_byte & (@as(u8, 0x80) >> @as(u3, @intCast(col)))) != 0) {
                    const px = (x_pos + @as(u8, @intCast(col))) % 64;
                    const py = (y_pos + @as(u8, @intCast(row))) % 32;
                    if (display.togglePixel(px, py)) {
                        self.v[0xF] = 1;
                    }
                }
            }
        }
    }
};
