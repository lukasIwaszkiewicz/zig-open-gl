const std = @import("std");
const Shader = @This();
const gl = @import("gl");

id: c_uint,

pub fn create(arena: std.mem.Allocator, vertex_path: []const u8, frag_path: []const u8) !Shader {
    _ = frag_path;
    _ = arena;
    var vertexShader: c_uint = undefined;
    vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    var v_shader_file = try std.fs.cwd().openFile(vertex_path, .{});
    _ = v_shader_file;
    std.debug.print("file read", .{});

    return Shader{ .id = 0 };
}

pub fn setBool(self: Shader, name: [*c]const u8, value: bool) void {
    _ = value;
    _ = name;
    _ = self;
}
pub fn setInt(self: Shader, name: [*c]const u8, value: u32) void {
    _ = value;
    _ = name;
    _ = self;
}
pub fn setFloat(self: Shader, name: [*c]const u8, value: f32) void {
    _ = value;
    _ = name;
    _ = self;
}
