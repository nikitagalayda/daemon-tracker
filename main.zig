// Getting statuses of processes with PIDs [x1, x2, x2..]
// 1. For each PID, open the corresponding file in /proc
// 2. Read the State section of the file
// 3. Print out the results

const std = @import("std");

const PROC_FILE_BUF_SIZE = 64;
const PROC_PATH = "/proc/";

const FileOpenError = error{
    FileNotFound,
};

// ! before void means the function can return an error
pub fn main() !void {
    // .{...} is a struct literal
    // It initializes a struct with named fields
    var file_content_buf: [PROC_FILE_BUF_SIZE]u8 = undefined;
    // This allocator is ONLY responsible for the path_buffer
    var fba: std.heap.FixedBufferAllocator = std.heap.FixedBufferAllocator.init(&file_content_buf);
    const allocator = fba.allocator();

    var dir: std.fs.Dir = try std.fs.openDirAbsolute(PROC_PATH, .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    defer dir.close();

    const mem = try allocator.alloc(u8, PROC_FILE_BUF_SIZE);
    defer allocator.free(mem);
    var d: std.fs.Dir = try findDir(
        dir,
        "1",
    );
    defer d.close();

    const file: std.fs.File = try findFile(
        d,
        "status",
    );

    const file_reader = file.reader();
    const bytes_read = try file_reader.read(mem);
    std.debug.print("{d}\n", .{bytes_read});
    std.debug.print("{s}\n", .{mem});
}

fn findFile(dir: std.fs.Dir, file_name: []const u8) anyerror!std.fs.File {
    var dir_iterator = dir.iterate();

    while (try dir_iterator.next()) |path| {
        if (!std.mem.eql(u8, path.name, file_name)) {
            continue;
        }

        const file: std.fs.File = try std.fs.Dir.openFile(dir, path.name, .{});

        return file;
    }
    return error.FileNotFound;
}

fn findDir(dir: std.fs.Dir, dir_name: []const u8) anyerror!std.fs.Dir {
    var dir_iterator = dir.iterate();

    while (try dir_iterator.next()) |path| {
        if (!std.mem.eql(u8, path.name, dir_name)) {
            continue;
        }

        const d: std.fs.Dir = try std.fs.Dir.openDir(dir, path.name, .{
            .iterate = true,
        });

        return d;
    }
    return error.FileNotFound;
}
