const std = @import("std");
const _utils = @import("utils.zig");
const _errors = @import("errors.zig");

const VALID_ARGS = [_][]const u8{ "attach", "kill", "ps" };

pub fn allArgsValid(args: [][:0]u8) bool {
    for (args) |arg| {
        if (!_utils.inSliceArray(&VALID_ARGS, arg)) {
            return false;
        }
    }

    return true;
}

pub fn processArgs(args: [][:0]u8, pids: *std.ArrayList(u32)) !void {
    for (args) |arg| {
        if (!_utils.inSliceArray(&VALID_ARGS, arg)) {
            return _errors.ArgumentError.InvalidArgument;
        }
        if (std.mem.eql(u8, arg, "attach")) {
            // Ingest next N arguments as PIDs
            const numAttachedPids = try attachPids(args, pids);
            std.debug.print("NUM OF ATTACHED PIDS: {any}\n", .{numAttachedPids});
        } else if (std.mem.eql(u8, arg, "ps")) {
            return;
        } else if (std.mem.eql(u8, arg, "kill")) {
            return;
        }
    }
}

pub fn attachPids(args: [][:0]u8, pids: *std.ArrayList(u32)) !u8 {
    // Assuming "attach" argument exists
    var attaching: bool = false;
    var numAttachedPids: u8 = 0;
    for (args) |arg| {
        if (std.mem.eql(u8, "attach", arg) and !attaching) {
            // Start of attach argument
            attaching = true;
            continue;
        }
        if (attaching) {
            if (_utils.inSliceArray(&VALID_ARGS, arg)) {
                return numAttachedPids;
            }
            if (std.fmt.parseInt(u32, arg, 10)) |parsedPid| {
                try pids.append(parsedPid);
                numAttachedPids += 1;
            } else |err| {
                std.debug.print("Error: Could not parse argument as a PID: {!}\n", .{err});
                continue;
            }
        }
    }

    return numAttachedPids;
}
