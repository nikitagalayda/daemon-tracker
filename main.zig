// Getting statuses of processes with PIDs [x1, x2, x2..]
// 1. For each PID, open the corresponding file in /proc
// 2. Read the State section of the file
// 3. Print out the results

const std = @import("std");

const PROC_FILE_BUF_SIZE = 64;
const PID_ARRAY_BUF_SIZE = 1024;
const PID_STRING_BUF_SIZE = 32;

const PROC_PATH = "/proc/";
const STATUS_FILENAME = "status";

const FileOpenError = error{
    FileNotFound,
    DirNotFound,
};

// ! before void means the function can return an error
pub fn main() !void {
    // .{...} is a struct literal
    // It initializes a struct with named fields
    var file_content_buf: [PROC_FILE_BUF_SIZE]u8 = undefined;
    var pids_buf: [PID_ARRAY_BUF_SIZE]u8 = undefined;
    var pid_string_buf: [PID_STRING_BUF_SIZE]u8 = undefined;

    // This allocator is ONLY responsible for its buffer
    var file_content_buf_fba: std.heap.FixedBufferAllocator = std.heap.FixedBufferAllocator.init(&file_content_buf);
    var pids_buf_fba: std.heap.FixedBufferAllocator = std.heap.FixedBufferAllocator.init(&pids_buf);
    var pid_string_buf_fba: std.heap.FixedBufferAllocator = std.heap.FixedBufferAllocator.init(&pid_string_buf);

    const file_content_allocator = file_content_buf_fba.allocator();
    const pids_buf_allocator = pids_buf_fba.allocator();
    const pid_string_allocator = pid_string_buf_fba.allocator();

    var pids = std.ArrayList(u32).init(pids_buf_allocator);
    defer pids.deinit();

    try pids.append(1);
    try pids.append(2);

    var dir: std.fs.Dir = try std.fs.openDirAbsolute(PROC_PATH, .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    defer dir.close();

    const mem = try file_content_allocator.alloc(u8, PROC_FILE_BUF_SIZE);
    defer file_content_allocator.free(mem);

    for (pids.items) |pid| {
        const pid_string = try std.fmt.allocPrint(pid_string_allocator, "{d}", .{pid});

        std.debug.print("Getting directory {s}\n", .{pid_string});

        var d: std.fs.Dir = try findDir(
            dir,
            pid_string,
        );
        defer d.close();

        std.debug.print("Looking for file status", .{});
        const file: std.fs.File = try findFile(
            d,
            STATUS_FILENAME,
        );

        const file_reader = file.reader();
        const bytes_read = try file_reader.read(mem);
        std.debug.print("{d}\n", .{bytes_read});
        std.debug.print("{s}\n", .{mem});
    }
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
    return error.DirNotFound;
}
