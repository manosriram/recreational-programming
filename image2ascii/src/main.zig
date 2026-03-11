const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const file: []const u8 = "/Users/manosriram/dev/recreational/image2ascii/ziglang.png";
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(allocator,  file, read_buffer[0..]);
    defer image.deinit(allocator);


    const argv = &[_][]const u8{ "sips", "-Z", "70", file};
    // Initialize the child process with arguments and an allocator.
    var child = std.process.Child.init(argv, std.heap.page_allocator);

    // Spawn the child process.
    try child.spawn();

    // Wait for the child process to complete and get the exit code.
    const exit_code = try child.wait();

    // Assert that the command exited successfully (exit code 0).
    try std.testing.expectEqual(exit_code, std.process.Child.Term{ .Exited = 0 });

    // Decide on symbols
    // */$@!+=
    // 0 -> black
    // 255 -> white
    //
    // 0-50 -> *
    // 51-100 -> =
    // 101-150 -> @
    // 151-200 -> +
    // 201-255 -> #

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const hallocator = gpa.allocator();

    var ascii: std.ArrayList(u8) = .empty;

    // var ascii = std.ArrayList(u8).init(hallocator);
    // defer ascii.deinit();

    // const count: i32 = 10;
    var it: i32 = 0;
    // var current_sum: i32 = 0;

    // const rows: i32 = 50;
    // const cols: i32 = 50;

    // const row_size: i32 = image.rowByteSize();

    for (image.rawBytes()) |pixel| {
        it += 1;
        if (@mod(it, 210) == 0) {
            try ascii.append(allocator, '\n');
            continue;
        }

        // if (@mod(it, count) == 0) {
        // std.debug.print("{any}\n", .{pixel});
        // switch (@divTrunc(current_sum, count)) {
        switch (pixel) {
            0...50 => {
                try ascii.append(allocator, '*');
            },
            51...100 => {
                try ascii.append(allocator, '=');
            },
            101...150 => {
                try ascii.append(allocator, '@');
            },
            151...200 => {
                try ascii.append(allocator, '+');
            },
            201...255 => {
                try ascii.append(allocator, '.');
            },

            // }
            // }
            // it += 1;
            // current_sum += pixel;
        }

    }
    // std.debug.print("{d}\n", .{ascii.items.len});
    // std.debug.print("{d}\n", .{image.rowByteSize()});
    std.debug.print("{s}\n", .{ascii.items});
}
