const std = @import("std");
const git_add = @import("add.zig").add;
const git_init = @import("init.zig").init;
const git_status = @import("status.zig").status;
const git_commit = @import("commit.zig").commit;
const git_log = @import("log.zig").log;

var gpa = std.heap.DebugAllocator(.{}){};

pub const ObjectType = union(enum) {
    Blob: Blob,
    Tree: Tree,
};

pub const Object = struct {
    type: []const u8,
    blob: Blob,
    tree: Tree,
};

pub const Blob = struct{
    hash: []const u8,
    path: []const u8,
};

pub const Tree = struct {
    hash: []const u8,
    path: []const u8,
    objects: std.ArrayList(Object),

    pub fn init() Tree {
        return Tree{
            .blobs = .empty,
            .trees = .empty,
        };
    }
};

pub const Git = struct {
    allocator: std.mem.Allocator,

    pub fn init() Git {
        return Git{
            .allocator = gpa.allocator(),
        };
    }

    pub fn call(self: Git, args: [][*:0]u8) !void {
        const cmd = std.mem.span(args[2]);

        if (std.mem.eql(u8, cmd, "init")) {
            try self.zinit();
        } else if (std.mem.eql(u8, cmd, "status")) {
            try self.zstatus();
        } else if (std.mem.eql(u8, cmd, "add")) {
            const add_path = std.mem.span(args[3]);
            try self.zadd(add_path);
        } else if (std.mem.eql(u8, cmd, "commit")) {
            const message = std.mem.span(args[3]);
            try self.zcommit(message);
        } else if (std.mem.eql(u8, cmd, "log")) {
            try self.zlog();
        }
    }

    fn zinit(_: Git) !void {
        try git_init();
    }

    fn zstatus(self: Git) !void {
        try git_status(self.allocator);
    }

    fn zadd(self: Git, path: []const u8) !void {
        _ = try git_add(path, self.allocator);
    }

    fn zcommit(self: Git, message: []const u8) !void {
        _ = try git_commit(message, self.allocator);
    }

    fn zlog(self: Git) !void {
        _ = try git_log(self.allocator);
    }

};
