//! CHIP-8 Input Module
//!
//! Maps host keyboard to CHIP-8's 16-key hex keypad.
//!
//! CHIP-8 Keypad:    Keyboard Mapping:
//! 1 2 3 C           1 2 3 4
//! 4 5 6 D           Q W E R
//! 7 8 9 E           A S D F
//! A 0 B F           Z X C V

/// Input handler for 16-key hex keypad
pub const Input = struct {
    /// Key state (true = pressed)
    keys: [16]bool,

    /// Key waiting state for FX0A
    waiting_for_key: bool,
    last_key: ?u4,

    /// Initialize input (all keys released)
    pub fn init() Input {
        return Input{
            .keys = [_]bool{false} ** 16,
            .waiting_for_key = false,
            .last_key = null,
        };
    }

    /// Set key as pressed
    pub fn keyDown(self: *Input, key: u4) void {
        self.keys[key] = true;
        if (self.waiting_for_key) {
            self.last_key = key;
            self.waiting_for_key = false;
        }
    }

    /// Set key as released
    pub fn keyUp(self: *Input, key: u4) void {
        self.keys[key] = false;
    }

    /// Check if key is pressed
    pub fn isPressed(self: *const Input, key: u4) bool {
        return self.keys[key];
    }

    /// Start waiting for key press (FX0A)
    pub fn startWaitingForKey(self: *Input) void {
        self.waiting_for_key = true;
        self.last_key = null;
    }

    /// Check if waiting for key
    pub fn isWaitingForKey(self: *const Input) bool {
        return self.waiting_for_key;
    }

    /// Get the last pressed key (for FX0A)
    pub fn getLastKey(self: *const Input) ?u4 {
        return self.last_key;
    }
};
