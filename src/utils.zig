const std = @import("std");

pub fn inSliceArray(collection: []const []const u8, match: []u8) bool {
    for (collection) |item| {
        if (std.mem.eql(u8, item, match)) {
            return true;
        }
    }

    return false;
}
