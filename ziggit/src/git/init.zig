const std = @import("std");

pub fn init() !void {
    std.debug.print("Git init", .{});

    // create .ziggit
    // create .ziggit/objects
    const cwd = std.fs.cwd();
    try cwd.makePath(".ziggit/objects");
}
