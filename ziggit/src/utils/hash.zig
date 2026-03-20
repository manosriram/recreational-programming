const std = @import("std");
const Sha1 = std.crypto.hash.Sha1;

pub fn hash(content: []u8) ![]const u8 {
    var hash_out: [20]u8 = undefined;

    Sha1.hash(content, &hash_out, .{});
    return try std.fmt.allocPrint(std.heap.page_allocator, "{x}", .{hash_out});
}

// add a comment
