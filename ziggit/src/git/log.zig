const std = @import("std");
const utils = @import("../utils/utils.zig");

fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (std.mem.eql(u8, path, "")) {
        return "";
    }

    const cwd = std.fs.cwd();
    if (try utils.isDirectory(cwd, path)) {
        return "";
    }


    const file = try cwd.openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;

    const buf = try allocator.alloc(u8, size);
    _ = try file.read(buf);

    return buf;
}

pub fn log(allocator: std.mem.Allocator) !void {
    // Read .ziggit/HEAD -> headhash
    // Read .ziggit/objects/<headhash>

    const head_ref_content = try read_file(".ziggit/HEAD", allocator);

    var buffer: [1000]u8 = undefined;
    var head_content =  try read_file(try std.fmt.bufPrint(&buffer, ".ziggit/{s}", .{head_ref_content}), allocator);

    // var head_content = try read_file(head_ref_content, allocator);

    var is_end_of_commit_tree = false;

    var buf: [56]u8 = undefined;
    var tr: std.mem.SplitIterator(u8, std.mem.DelimiterType.any) = undefined;

    // TODO: add err checks
    while (!is_end_of_commit_tree) {
        const path = try std.fmt.bufPrint(&buf, ".ziggit/objects/{s}", .{head_content});
        const f = try read_file(path, allocator);

        std.debug.print("{s}\n---\n", .{f});

        var it = std.mem.splitAny(u8, f, "\n");
        _ = it.next();
        if (it.next()) |parent_line| {
            if (std.mem.eql(u8, parent_line, "")) {
                is_end_of_commit_tree = true;
                continue;
            }

            tr = std.mem.splitAny(u8, parent_line, " ");
            _ = tr.next();

            const hash = tr.rest();
            const mutable_hash = try allocator.dupe(u8, hash);
            head_content = mutable_hash;
        } else {
            is_end_of_commit_tree = true;
        }

    }
}
