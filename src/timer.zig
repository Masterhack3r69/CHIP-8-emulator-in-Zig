//! CHIP-8 Timer Module
//!
//! CHIP-8 has two timers that count down at 60Hz:
//! - Delay Timer: Used for timing game events
//! - Sound Timer: Beeps while non-zero

/// Timer subsystem (60Hz countdown)
pub const Timer = struct {
    /// Delay timer (counts down at 60Hz)
    delay: u8,

    /// Sound timer (beeps while non-zero, counts down at 60Hz)
    sound: u8,

    /// Initialize timers to zero
    pub fn init() Timer {
        return Timer{
            .delay = 0,
            .sound = 0,
        };
    }

    /// Tick timers (call at 60Hz)
    pub fn tick(self: *Timer) void {
        if (self.delay > 0) {
            self.delay -= 1;
        }
        if (self.sound > 0) {
            self.sound -= 1;
        }
    }

    /// Check if sound should be playing
    pub fn isSoundPlaying(self: *const Timer) bool {
        return self.sound > 0;
    }
};
