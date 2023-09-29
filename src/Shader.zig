const std = @import("std");
const Shader = @This();
const gl = @import("gl");

id: c_uint,

pub fn create(arena: std.mem.Allocator, vertex_path: []const u8, frag_path: []const u8) !Shader {
    var vertexCode: c_uint = undefined;
    var fragementCode: c_uint = undefined;
    _ = fragementCode;

    var v_shader_file = try std.fs.cwd().openFile(vertex_path, .{});
    var f_shader_file = try std.fs.cwd().openFile(frag_path, .{});

    var size: u64 = @max((try v_shader_file.stat()).size, (try f_shader_file.stat()).size);
    var buffer = try arena.alloc(u8, size);
    var read_len = try v_shader_file.readAll(buffer);

    vertexCode = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexCode, 1, @as([*c]const [*c]const u8, @ptrCast(&buffer)), 0);
    gl.compileShader(vertexCode);

    read_len = try f_shader_file.readAll(buffer);
    gl.shaderSource(vertexCode, 1, @as([*c]const [*c]const u8, @ptrCast(&buffer)), 0);
    gl.compileShader(vertexCode);

    defer gl.deleteShader(vertexCode);

    const shaderProgram = gl.createProgram();
    _ = shaderProgram;

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
