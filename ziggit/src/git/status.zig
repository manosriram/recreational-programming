const std = @import("std");
const utils = @import("../utils/utils.zig");
const Sha1 = std.crypto.hash.Sha1;

pub fn status(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();

    const dir = try cwd.openDir(".", .{ .iterate = true });
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    const ignored_paths = [_][]const u8{
        ".git",
        ".zig-cache",
        ".ziggit",
        "zig-out",
    };

    while (try walker.next()) |x| {
        if (utils.is_str_in_slice(&ignored_paths, x.path)) {
            continue;
        }

        if (try utils.isDirectory(cwd, x.path)) {
            continue;
        }

        const file = try cwd.openFile(x.path, .{.mode = .read_only});
        defer file.close();

        const stat = try file.stat();
        const size = stat.size;

        const buf = try allocator.alloc(u8, size);

        _ = try file.read(buf);

        var hash_out: [20]u8 = undefined;

        Sha1.hash(buf, &hash_out, .{});
        const hash_string = try std.fmt.allocPrint(std.heap.page_allocator, "{x}", .{hash_out});

        var buffer: [56]u8 = undefined;
        const new_path = try std.fmt.bufPrint(&buffer, ".ziggit/objects/{s}", .{hash_string});
        // TODO: check if new_path exists

        if (std.fs.cwd().openFile(new_path, .{})) |new_file| {
            std.debug.print("{s} (exists)\n", .{x.basename});
            defer new_file.close();
        } else |err| switch (err) {
            error.FileNotFound => {
                std.debug.print("{s} (not staged)\n", .{x.basename});
            },
            error.IsDir => {
            },
            else => {}
        }
    }
}

