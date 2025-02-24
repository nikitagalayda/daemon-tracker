// Getting statuses of processes with PIDs [x1, x2, x2..]
// 1. For each PID, open the corresponding file in /proc
// 2. Read the State section of the file
// 3. Print out the results

const std = @import("std");
const _constants = @import("constants.zig");
const _errors = @import("errors.zig");

// ! before void means the function can return an error
pub fn main() !void {
    // .{...} is a struct literal
    // It initializes a struct with named fields
    var file_content_buf: [_constants.PROC_FILE_BUF_SIZE]u8 = undefined;
    var pids_buf: [_constants.PID_ARRAY_BUF_SIZE]u8 = undefined;
    var pid_string_buf: [_constants.PID_STRING_BUF_SIZE]u8 = undefined;

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
    // try pids.append(2);

    var dir: std.fs.Dir = try std.fs.openDirAbsolute(_constants.PROC_PATH, .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    defer dir.close();

    const mem = try file_content_allocator.alloc(u8, _constants.PROC_FILE_BUF_SIZE);
    defer file_content_allocator.free(mem);

    for (pids.items) |pid| {
        const pid_string = try std.fmt.allocPrint(pid_string_allocator, "{d}", .{pid});

        // std.debug.print("Getting directory {s}\n", .{pid_string});

        var d: std.fs.Dir = try findDir(
            dir,
            pid_string,
        );
        defer d.close();

        // std.debug.print("Looking for file status", .{});
        const file: std.fs.File = try findFile(
            d,
            _constants.STATUS_FILENAME,
        );
        const file_reader = file.reader();
        _ = try file_reader.read(mem);
        const result = try getProcessState(mem);
        std.debug.print("{s}", .{result});
    }
}

fn getProcessState(buf: []const u8) ![]const u8 {
    // std.debug.print("{s}", .{buf});
    // return;
    var newline_split = std.mem.splitSequence(u8, buf, "\n");
    while (newline_split.next()) |line| {
        // std.debug.print("{s}", .{x});
        if (std.mem.eql(u8, line[0..6], "State:")) {
            std.debug.print("FOUND\n", .{});
            var tab_split = std.mem.splitSequence(u8, line, "\t");
            _ = tab_split.first();

            // TODO: add verification
            return tab_split.rest();
        }
    }

    // TODO: make a better error name
    return _errors.MatchError.MatchNotFound;
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
    return _errors.FileOpenError.FileNotFound;
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
    return _errors.FileOpenError.DirNotFound;
}
