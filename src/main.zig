const std = @import("std");
const fmt = @import("fmt.zig");
const tui = @import("tui.zig");

pub fn main() !void {
    const stdin = fmt.getStdIn();
    const hn = fmt.getHandle();
    try tui.enableRaw(hn);
    defer tui.disableRaw(hn);

    fmt.print("\x1b[2J\x1b[H"); // clear the screen and reset cursor pos
    fmt.print("\x1b[?25l"); // hide the cursor

    const cv: tui.Canvas = try .init(hn, null, null);
    var protag: tui.Protag = .init(cv, cv.width / 2, cv.height / 2);

    while (true) {
        // render
        protag.draw();
        fmt.flush();

        // poll events
        const key = try stdin.takeByte();
        if (key == 'q') break;
        protag.move(key);
    }

    fmt.print("\x1b[?25h"); // show cursor
    fmt.print("\x1b[2J\x1b[H"); // clear the screen and reset cursor pos
    fmt.flush();
}
