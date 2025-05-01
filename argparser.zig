const _utils = @import("utils.zig");
const std = @import("std");

const VALID_ARGS = [_][]const u8{ "attach", "kill", "ps" };

pub fn allArgsValid(args: [][:0]u8) bool {
    for (args) |arg| {
        std.debug.print("checking arg {s}\n", .{arg});
        if (!_utils.inSliceArray(&VALID_ARGS, arg)) {
            return false;
        }
    }

    return true;
}
