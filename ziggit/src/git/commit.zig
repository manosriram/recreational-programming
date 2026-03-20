const std = @import("std");
const hash_utils = @import("../utils/hash.zig");

fn write_path(path: []const u8, content: []const u8) !void {
    _ = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            _ = try std.fs.cwd().createFile(path, .{});
        } else {
            return err;
        }
    };

    const f = try std.fs.cwd().openFile(path, .{.mode = .read_write});
    defer f.close();
    try f.writeAll(content);
}

fn read_file(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();

    const file = try cwd.openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;

    const buf = try allocator.alloc(u8, size);
    _ = try file.read(buf);

    return buf;
}

pub fn commit(message: []const u8, allocator: std.mem.Allocator) !void {
    // const cwd = std.fs.cwd();
    const index_path: []const u8 = ".ziggit/index";
    const fetch_head_path: []const u8 = ".ziggit/HEAD";


    var does_fetch_head_exist: bool = true;
    _ = std.fs.cwd().openFile(fetch_head_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            const f = try std.fs.cwd().createFile(fetch_head_path, .{});
            try f.writeAll("refs/heads/main");
            try std.fs.cwd().makePath(".ziggit/refs/heads");
            does_fetch_head_exist = false;
        }
    };

    const head_ref_content = try read_file(".ziggit/HEAD", allocator);
    // const default_working_branch: []const u8 = "main";

    const buf = try read_file(index_path, allocator);
    const index_tree_hash = try hash_utils.hash(buf);

    var commit_content: []u8 = "";

    commit_content = try std.mem.concat(allocator, u8, &[_][]const u8{commit_content, try std.fmt.allocPrint(allocator, "tree {s}\n", .{index_tree_hash})});

    if (does_fetch_head_exist) {
        var head_buffer: [1000]u8 = undefined;
        const head_content =  try read_file(try std.fmt.bufPrint(&head_buffer, ".ziggit/{s}", .{head_ref_content}), allocator);
        commit_content = try std.mem.concat(allocator, u8, &[_][]const u8{commit_content, try std.fmt.allocPrint(allocator, "parent {s}\n", .{head_content})});
    }

    commit_content = try std.mem.concat(allocator, u8, &[_][]const u8{commit_content, try std.fmt.allocPrint(allocator, "{s}\n", .{message})});

    const hashed_commit_content = try hash_utils.hash(commit_content);

    var buffer: [56]u8 = undefined;
    const new_path = try std.fmt.bufPrint(&buffer, ".ziggit/objects/{s}", .{hashed_commit_content});

    std.debug.print("{s}\n", .{hashed_commit_content});

    var index_buffer: [56]u8 = undefined;
    const index_tree_path = try std.fmt.bufPrint(&index_buffer, ".ziggit/objects/{s}", .{index_tree_hash});

    try write_path(index_tree_path, buf);
    try write_path(new_path, commit_content);

   var file = try std.fs.cwd().createFile(index_path, .{});
   defer file.close();

    // Truncate the file to 0 bytes
    try file.setEndPos(0);

    try write_path(".ziggit/refs/heads/main", hashed_commit_content);

    // Read .ziggit/index
    // Hash the contents -> tree hash
    // Create commit content:
    //
    // tree <tree hash>
    // parent <parent tree>
    //
    // <commit message>
    //
    // Hash the above contents -> commit hash
    // Create .ziggit/objects/<commit hash> and write the above content to it
    //
    // Write the commit hash to .ziggit/FETCH_HEAD


    return;
}
