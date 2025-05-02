// Getting statuses of processes with PIDs [x1, x2, x2..]
// 1. For each PID, open the corresponding file in /proc
// 2. Read the State section of the file
// 3. Print out the results

const std = @import("std");
const _constants = @import("config.zig");
const _errors = @import("errors.zig");
const _argparser = @import("argparser.zig");
const _utils = @import("utils.zig");

// ! before void means the function can return an error
pub fn main() !void {
    // Args
    var argsGPA = std.heap.GeneralPurposeAllocator(.{}){};
    const argsAllocator = argsGPA.allocator();
    defer _ = argsGPA.deinit();
    const args: [][:0]u8 = try std.process.argsAlloc(argsAllocator);
    defer std.process.argsFree(argsAllocator, args);
    std.debug.print("---------ARGS INFO---------\n", .{});
    std.debug.print("There are {d} args:\n", .{args.len});
    for (args) |arg| {
        std.debug.print("  {s}\n", .{arg});
    }

    std.debug.print("---------------------------\n", .{});

    // Processing the proc files
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

    try _argparser.processArgs(args[1..], &pids);
    defer pids.deinit();

    var dir: std.fs.Dir = try std.fs.openDirAbsolute(_constants.PROC_PATH, .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    defer dir.close();

    const mem = try file_content_allocator.alloc(u8, _constants.PROC_FILE_BUF_SIZE);
    defer file_content_allocator.free(mem);

    // OUTPUT
    std.debug.print("PID\t\tSTATE\n", .{});
    // Finding proc file for all PIDs
    for (pids.items) |pid| {
        const pid_string = try std.fmt.allocPrint(pid_string_allocator, "{d}", .{pid});

        var d: std.fs.Dir = try _utils.findDir(
            dir,
            pid_string,
        );
        defer d.close();

        const file: std.fs.File = try _utils.findFile(
            d,
            _constants.STATUS_FILENAME,
        );
        const file_reader = file.reader();
        _ = try file_reader.read(mem);
        const processState = try getProcessState(mem);

        std.debug.print("{d}\t\t{s}\n", .{ pid, processState });
    }
}

fn getProcessState(buf: []const u8) ![]const u8 {
    var newline_split = std.mem.splitSequence(u8, buf, "\n");
    while (newline_split.next()) |line| {
        if (std.mem.eql(u8, line[0..6], "State:")) {
            var tab_split = std.mem.splitSequence(u8, line, "\t");
            _ = tab_split.first();

            // TODO: add verification
            return tab_split.rest();
        }
    }

    // TODO: make a better error name
    return _errors.MatchError.MatchNotFound;
}
