const std = @import("std");
const hash_utils = @import("../utils/hash.zig");
const utils = @import("../utils/utils.zig");
const Sha1 = std.crypto.hash.Sha1;
const Blob = @import("../git/git.zig").Blob;
const Tree = @import("../git/git.zig").Tree;
const Object = @import("../git/git.zig").Object;
const ObjectType = @import("../git/git.zig").ObjectType;


fn hash_and_store(path: []const u8, allocator: std.mem.Allocator) !Blob {
    const cwd = std.fs.cwd();

    const file = try cwd.openFile(path, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;

    const buf = try allocator.alloc(u8, size);
    _ = try file.read(buf);

    const hash_string = try hash_utils.hash(buf);

    var buffer: [56]u8 = undefined;
    const new_path = try std.fmt.bufPrint(&buffer, ".ziggit/objects/{s}", .{hash_string});

    _ = std.fs.cwd().openFile(new_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            const f = try std.fs.cwd().createFile(new_path, .{});
            _ = try f.writeAll(buf);
        } else {
            return err;
        }
    };

    return Blob{
        .hash = hash_string,
        .path = path,
    };
}

pub fn add(path: []const u8, allocator: std.mem.Allocator) !Object {
    // Create a hash of the file path's content -> hash
    // Use the hash to create .ziggit/objects/<hash>
    // If its a file, create the path
    // If its a dir, ?

    const cwd = std.fs.cwd();
    const base_path = try cwd.realpathAlloc(allocator, path); // realpathAlloc("."\

    if (try utils.isDirectory(cwd, path)) {
        const dir = try cwd.openDir(path, .{ .iterate = true });
        var walker = try dir.walk(allocator);
        defer walker.deinit();

        var objects: std.ArrayList(Object) = .empty;

        while (try walker.next()) |x| {
            const absolute_path = try std.fs.path.join(allocator, &[_][]const u8{
                base_path,
                x.path,
            });

            const object = try add(absolute_path, allocator); // creates blob object recursively
            // std.debug.print("{s} typee\n", .{object.type});

            try objects.append(allocator, object);
        }

        var raw_tree_content: []u8 = "";
        for (objects.items) |obj| {
            // raw_tree_content += "{s} {s}\n";
            if (std.mem.eql(u8, obj.type, "blob")) {
                raw_tree_content = try std.mem.concat(allocator, u8, &[_][]const u8{raw_tree_content, try std.fmt.allocPrint(allocator, "{s} {s} {s}\n", .{obj.type, obj.blob.hash, obj.blob.path})});
            } else {
                raw_tree_content = try std.mem.concat(allocator, u8, &[_][]const u8{raw_tree_content, try std.fmt.allocPrint(allocator, "{s} {s} {s}\n", .{obj.type, obj.tree.hash, obj.tree.path})});
            }
        }

        std.debug.print("{s}\n", .{raw_tree_content});

        const hash_string = try hash_utils.hash(raw_tree_content);


        // Store raw_tree_content at .git/objects/<hash_string>

        var buffer: [56]u8 = undefined;
        const new_path = try std.fmt.bufPrint(&buffer, ".ziggit/objects/{s}", .{hash_string});

        _ = std.fs.cwd().openFile(new_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                const f = try std.fs.cwd().createFile(new_path, .{});
                _ = try f.writeAll(raw_tree_content);
            } else {
                return err;
            }
        };


        return Object{
            .blob = undefined,
            .tree = Tree{
                .hash = hash_string,
                .path = path,
                .objects = objects,
            },
            .type = "tree",
        };

        // Create a tree for all the blobs above
    } else {
        const blob = try hash_and_store(path, allocator);

        _ = std.fs.cwd().openFile(".ziggit/index", .{}) catch |err| {
            if (err == error.FileNotFound) {
                _ = try std.fs.cwd().createFile(".ziggit/index", .{});
            } else {
                return err;
            }
        };
        const f = try cwd.openFile(".ziggit/index", .{.mode = .read_write});
        defer f.close();

        const stat = try f.stat();
        const size = stat.size;

        const buf = try allocator.alloc(u8, size);
        _ = try f.read(buf);

        const content = try std.mem.concat(allocator, u8, &[_][]const u8{"", try std.fmt.allocPrint(allocator, "{s} {s}\n", .{blob.hash, blob.path})});
        try f.writeAll(content);

        return Object{
            .type = "blob",
            .blob = blob,
            .tree = undefined,
        };
    }
}
