const std = @import("std");
const _errors = @import("errors.zig");

pub fn inSliceArray(collection: []const []const u8, match: []u8) bool {
    for (collection) |item| {
        if (std.mem.eql(u8, item, match)) {
            return true;
        }
    }

    return false;
}

pub fn findFile(dir: std.fs.Dir, file_name: []const u8) anyerror!std.fs.File {
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

pub fn findDir(dir: std.fs.Dir, dir_name: []const u8) anyerror!std.fs.Dir {
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
