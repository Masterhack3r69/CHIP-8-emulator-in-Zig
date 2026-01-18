//! CHIP-8 Display Module
//!
//! Manages the 64x32 monochrome framebuffer.

/// Display width in pixels
pub const WIDTH: usize = 64;

/// Display height in pixels
pub const HEIGHT: usize = 32;

/// Display framebuffer and rendering
pub const Display = struct {
    /// Pixel buffer (64×32 = 2048 pixels)
    /// Each pixel is 0 (off) or 1 (on)
    pixels: [WIDTH * HEIGHT]u8,

    /// Flag indicating display was modified
    dirty: bool,

    /// Initialize display (all pixels off)
    pub fn init() Display {
        return Display{
            .pixels = [_]u8{0} ** (WIDTH * HEIGHT),
            .dirty = false,
        };
    }

    /// Clear the display (all pixels off)
    pub fn clear(self: *Display) void {
        @memset(&self.pixels, 0);
        self.dirty = true;
    }

    /// Get pixel at (x, y)
    pub fn getPixel(self: *const Display, x: u8, y: u8) bool {
        if (x >= WIDTH or y >= HEIGHT) return false;
        const index = @as(usize, y) * WIDTH + @as(usize, x);
        return self.pixels[index] != 0;
    }

    /// Toggle pixel at (x, y), returns true if pixel was turned OFF (collision)
    pub fn togglePixel(self: *Display, x: u8, y: u8) bool {
        if (x >= WIDTH or y >= HEIGHT) return false;
        const index = @as(usize, y) * WIDTH + @as(usize, x);
        const was_on = self.pixels[index] != 0;
        self.pixels[index] ^= 1;
        self.dirty = true;
        return was_on;
    }

    /// Check if display needs redraw
    pub fn isDirty(self: *const Display) bool {
        return self.dirty;
    }

    /// Mark display as rendered
    pub fn clearDirty(self: *Display) void {
        self.dirty = false;
    }
};
