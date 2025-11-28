const std = @import("std");
const fmt = @import("fmt.zig");

const Corner = enum {
    TopRight,
    TopLeft,
    BottomRight,
    BottomLeft,

    fn str(self: Corner) []const u8 {
        return switch (self) {
            // ┌─┐│└┘
            .TopRight => "┐",
            .TopLeft => "┌",
            .BottomLeft => "└",
            .BottomRight => "┘",
        };
    }
};

pub const Point = struct {
    row: usize,
    col: usize,
};

// ========== Drawing ==========

pub const Protag = struct {
    cv: Canvas,
    x: usize,
    y: usize,

    pub fn init(cv: Canvas, x: ?usize, y: ?usize) Protag {
        return .{ .cv = cv, .x = x orelse 1, .y = y orelse 1 };
    }

    pub fn clearPrev(self: *Protag) void {
        self.cv.point(self.y, self.x, " ");
        // fmt.printf("\x1b[{d};{d}H", .{ self.y, self.x });
    }

    pub fn draw(self: *Protag) void {
        fmt.print("\x1b[33m");
        self.cv.point(self.y, self.x, "*");
        fmt.print("\x1b[0m");
    }

    pub fn move(self: *Protag, key: u8) void {
        switch (key) {
            'h' => {
                if (self.x < self.cv.width) {
                    self.clearPrev();
                    self.x += 1;
                }
            },
            'l' => {
                if (self.x > 0) {
                    self.clearPrev();
                    self.x -= 1;
                }
            },
            'k' => {
                if (self.y < self.cv.height) {
                    self.clearPrev();
                    self.y += 1;
                }
            },
            'j' => {
                if (self.y > 0) {
                    self.clearPrev();
                    self.y -= 1;
                }
            },
            else => {},
        }
    }
};

pub const Canvas = struct {
    width: usize,
    height: usize,

    pub fn init(hn: std.fs.File.Handle, width: ?usize, height: ?usize) !Canvas {
        const size = try getSize(hn);
        return .{ .height = height orelse size.row, .width = width orelse size.col };
    }

    pub fn draw(self: *const Canvas) void {
        rect(.{ .col = 0, .row = 0 }, self.height, self.width);
    }

    pub fn point(self: *const Canvas, height: usize, width: usize, label: []const u8) void {
        dot(self.height - height, self.width - width, label);
    }
};

pub fn corner(r: usize, c: usize, pos: Corner) void {
    fmt.printf("\x1b[{d};{d}H{s}", .{ r, c, pos.str() });
}

pub fn dot(r: usize, c: usize, label: []const u8) void {
    fmt.printf("\x1b[{d};{d}H{s}", .{ r, c, label });
}

pub fn vline(c: usize, r1: usize, r2: usize) void {
    for (r1..r2) |idx| {
        fmt.printf("\x1b[{d};{d}H│", .{ idx, c });
    }
}

pub fn hline(r: usize, c1: usize, c2: usize) void {
    for (c1..c2) |idx| {
        fmt.printf("\x1b[{d};{d}H─", .{ r, idx });
    }
}

pub fn rect(origin: Point, height: usize, width: usize) void {
    hline(origin.row, origin.col, origin.col + width + 1);
    hline(origin.row + height, origin.col, origin.col + width + 1);
    vline(origin.col, origin.row, origin.row + height + 1);
    vline(origin.col + width, origin.row, origin.row + height + 1);

    corner(origin.row, origin.col, .TopLeft);
    corner(origin.row, origin.col + width, .TopRight);
    corner(origin.row + height, origin.col, .BottomLeft);
    corner(origin.row + height, origin.col + width, .BottomRight);
}

// ========== Config ==========

var original: std.posix.termios = undefined;

fn getSize(handle: std.fs.File.Handle) !std.posix.winsize {
    var s: std.posix.winsize = undefined;
    const result = std.posix.system.ioctl(handle, std.posix.T.IOCGWINSZ, @intFromPtr(&s));
    if (result != 0) return error.IoctlFailed else return s;
}

pub fn enableRaw(handle: std.fs.File.Handle) !void {
    original = try std.posix.tcgetattr(handle);

    var raw = original;
    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;

    try std.posix.tcsetattr(handle, .FLUSH, raw);
}

pub fn disableRaw(handle: std.fs.File.Handle) void {
    std.posix.tcsetattr(handle, .FLUSH, original) catch {};
}
