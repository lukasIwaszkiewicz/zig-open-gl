const std = @import("std");

pub fn pathToContent(allocator: std.mem.Allocator, relative_path: []const u8) ![4096:0]u8 {
    const exe_path = try std.fs.selfExeDirPathAlloc(allocator);
    const content_path = try std.fs.path.join(allocator, &.{ exe_path, relative_path });
    var content_path_zero: [4096:0]u8 = undefined;
    if (content_path.len >= 4096) return error.NameTooLong;
    std.mem.copy(u8, &content_path_zero, content_path);
    content_path_zero[content_path.len] = 0;
    return content_path_zero;
}
