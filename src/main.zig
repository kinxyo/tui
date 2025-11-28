const std = @import("std");
const fmt = @import("fmt.zig");
const tui = @import("tui.zig");

pub fn main() !void {
    const stdin = fmt.getStdIn();
    const hn = fmt.getHandle();
    try tui.enableRaw(hn);
    defer tui.disableRaw(hn);

    fmt.print("\x1b[2J\x1b[H");
    fmt.print("\x1b[?25l");

    const cv: tui.Canvas = try .init(hn, null, null);
    var pos_x: usize = 10;
    var pos_y: usize = 5;

    // cv.draw();
    while (true) {
        // render
        fmt.print("\x1b[2J\x1b[H");
        fmt.print("\x1b[33m");
        cv.point(pos_y, pos_x);
        fmt.print("\x1b[0m");
        fmt.flush();

        // poll events
        const key = try stdin.takeByte();
        if (key == 'q') break;
        if (key == 'h' and pos_x < cv.width) pos_x += 1;
        if (key == 'l' and pos_x > 0) pos_x -= 1;
        if (key == 'k' and pos_y < cv.height) pos_y += 1;
        if (key == 'j' and pos_y > 0) pos_y -= 1;
    }

    fmt.print("\x1b[?25h");
    fmt.print("\x1b[2J\x1b[H");
    fmt.flush();
}
