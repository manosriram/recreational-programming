const std = @import("std");
const Object = @import("../git/git.zig").Object;

pub fn is_str_in_slice(haystack: []const []const u8, needle: []const u8) bool {
    // Iterate over each item in the slice of strings.
    for (haystack) |item| {
        // Use std.mem.eql to compare the current item with the target string.
        if (std.mem.indexOf(u8, needle, item) != null) {
            return true; // Found a match
        }
    }
    return false; // No match found after checking all items
}

pub fn isDirectory(dir: std.fs.Dir, path: []const u8) !bool {
    var sub_dir = dir.openDir(path, .{}) catch |err| switch (err) {
        error.NotDir => return false,
        error.FileNotFound => return false, // The path doesn't exist
        else => return err, // Other errors should be propagated
    };
    defer sub_dir.close();
    return true;
}

// pub fn object_to_string(obj: Object) []const u8 {
    // return switch (obj.type) {
        // .Tree => return "tree",
        // .Blob => return "blob",
    // };
// }
