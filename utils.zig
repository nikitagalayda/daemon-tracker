const std = @import("std");

pub fn inSliceArray(collection: []const []const u8, match: []u8) bool {
    for (collection) |item| {
        std.debug.print("comparing {s} to valid arg {s}\n", .{ match, item });
        if (std.mem.eql(u8, item, match)) {
            return true;
        }
    }

    return false;
}
