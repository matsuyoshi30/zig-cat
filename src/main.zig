const std = @import("std");

pub fn main() anyerror!void {
    const stderr = std.io.getStdErr().writer();
    const stdout = std.io.getStdOut().writer();

    const argv = std.os.argv;
    if (argv.len < 2) {
        try stderr.print("give me some filenames\n", .{});
        return;
    }

    const cwd_fd = std.fs.cwd().fd;
    for (argv) |filepath, i| {
        if (i == 0) {
            continue;
        }

        var file: std.fs.File = undefined;
        if (std.fs.path.isAbsoluteZ(filepath)) {
            file = std.fs.openFileAbsoluteZ(filepath, .{ .read = true }) catch |err| {
                if (err == error.FileNotFound) {
                    try stderr.print("zig-cat: {s}: No such file or directory\n", .{filepath});
                }
                continue;
            };
        } else {
            const fd = std.os.openatZ(cwd_fd, filepath, std.os.O.RDONLY, 0) catch |err| {
                if (err == error.FileNotFound) {
                    try stderr.print("zig-cat: {s}: No such file or directory\n", .{filepath});
                }
                continue;
            };
            file = std.fs.File{ .handle = fd };
        }
        defer file.close();

        var buf: [4096]u8 = undefined;
        const buf_reads = try file.readAll(&buf);
        try stdout.print("{s}", .{buf[0..buf_reads]});
    }
}
