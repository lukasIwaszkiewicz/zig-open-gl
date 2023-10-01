const std = @import("std");
const Shader = @This();
const gl = @import("gl");

id: c_uint,

fn fullPath(arena: std.mem.Allocator, relative_path: []const u8) ![]const u8 {
    return try std.fs.path.join(arena, &.{ try std.fs.selfExeDirPathAlloc(arena), relative_path });
}

pub fn create(arena: std.mem.Allocator, vertex_path: []const u8, frag_path: []const u8) !Shader {
    var vertexShader: c_uint = undefined;
    vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);

    var v_shader_full_path = try fullPath(arena, vertex_path);
    var v_shader_file = try std.fs.openFileAbsolute(v_shader_full_path, .{});
    defer v_shader_file.close();

    const vs_code = v_shader_file.readToEndAllocOptions(arena, (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    gl.shaderSource(vertexShader, 1, @as([*c]const [*c]const u8, @ptrCast(&vs_code)), 0);
    gl.compileShader(vertexShader);

    var success: c_int = undefined;
    var infoLog: [512]u8 = [_]u8{0} ** 512;

    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);

    if (success == 0) {
        gl.getShaderInfoLog(vertexShader, 512, 0, &infoLog);
        std.log.err("vertex shader error: {s}", .{infoLog});
    } else {
        std.log.info("vertex shader compliled ok \n", .{});
    }

    var fragmentShader: c_uint = undefined;
    fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fragmentShader);

    var f_shader_full_path = try fullPath(arena, frag_path);
    var f_shader_file = try std.fs.openFileAbsolute(f_shader_full_path, .{});
    defer f_shader_file.close();

    const fs_code = f_shader_file.readToEndAllocOptions(arena, (10 * 1024), null, @alignOf(u8), 0) catch unreachable;
    gl.shaderSource(fragmentShader, 1, @as([*c]const [*c]const u8, @ptrCast(&fs_code)), 0);
    gl.compileShader(fragmentShader);

    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);

    if (success == 0) {
        gl.getShaderInfoLog(fragmentShader, 512, 0, &infoLog);
        std.log.err("fragment shader: {s}", .{infoLog});
    } else {
        std.log.info("frag shader compliled ok \n", .{});
    }
    const shaderProgram = gl.createProgram();

    // attach compiled shader objects to the program object and link
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    // check if shader linking was successfull
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shaderProgram, 512, 0, &infoLog);
        std.log.err("[shader program] {s}", .{infoLog});
    }

    return Shader{ .id = shaderProgram };
}

pub fn use(self: Shader) void {
    gl.useProgram(self.id);
}

pub fn setBool(self: Shader, name: [*c]const u8, value: bool) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @as(c_int, @intCast(value)));
}

pub fn setInt(self: Shader, name: [*c]const u8, value: u32) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @as(c_int, @intCast(value)));
}

pub fn setFloat(self: Shader, name: [*c]const u8, value: f32) void {
    gl.uniform1f(gl.getUniformLocation(self.id, name), value);
}

pub fn setVec3f(self: Shader, name: [*c]const u8, value: [3]f32) void {
    gl.uniform3f(gl.getUniformLocation(self.id, name), value[0], value[1], value[2]);
}

pub fn setMat4f(self: Shader, name: [*c]const u8, value: [16]f32) void {
    const matLoc = gl.getUniformLocation(self.ID, name);
    gl.uniformMatrix4fv(matLoc, 1, gl.FALSE, &value);
}
