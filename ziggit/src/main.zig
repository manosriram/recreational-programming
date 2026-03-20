const std = @import("std");
const git = @import("git/git.zig").Git;

/// Setup args
/// Create Git module
/// Create commands in Git

pub fn main() !void {
    if (std.os.argv.len > 1) {
        const arg1 = std.os.argv[1];
        if (std.mem.eql(u8, std.mem.span(arg1), "git")) {
            if (std.os.argv.len > 2) {
            const g = git.init();
            try g.call(std.os.argv);

            } else {
                std.debug.print("Error: required arg 2", .{});
                std.process.exit(1);
            }
        }
    }
}
