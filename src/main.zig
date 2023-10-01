const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Shader = @import("./Shader.zig");
const zstbi = @import("zstbi");
const common = @import("./common.zig");

const WindowSize = struct {
    pub const width: u32 = 800;
    pub const height: u32 = 600;
};

var success: c_int = undefined;

var infoLog: [512]u8 = [_]u8{0} ** 512;

pub fn main() !void {

    // glfw: initialize and configure
    // ------------------------------
    if (!glfw.init(.{})) {
        std.log.err("GLFW initialization failed", .{});
        return;
    }
    defer glfw.terminate();

    // glfw window creation
    // --------------------
    const window = glfw.Window.create(WindowSize.width, WindowSize.height, "mach-glfw + zig-opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 1,
    }) orelse {
        std.log.err("GLFW Window creation failed", .{});
        return;
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.Window.setFramebufferSizeCallback(window, framebuffer_size_callback);

    // Load all OpenGL function pointers
    // ---------------------------------------
    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    // Create vertex shader

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    const vertices = [_]f32{
        // positions      // colors        // texture coords
        0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
        0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
        -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
    };

    const indices = [_]c_uint{
        // note that we start from 0!
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;
    var EBO: c_uint = undefined;

    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);

    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);

    gl.genBuffers(1, &EBO);
    defer gl.deleteBuffers(1, &EBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(f32) * indices.len, &indices, gl.STATIC_DRAW);

    // position attr
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    const col_offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), col_offset);
    gl.enableVertexAttribArray(1);

    const tex_offset: [*c]c_uint = (6 * @sizeOf(f32));
    gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), tex_offset);
    gl.enableVertexAttribArray(2);

    const our_shader = try Shader.create(allocator, "content/vs.glsl", "content/fs.glsl");

    // load image

    zstbi.init(allocator);
    defer zstbi.deinit();

    // image 1
    const image1_path = try common.pathToContent(allocator, "content/wall.jpg");
    var image1 = try zstbi.Image.loadFromFile(&image1_path, 0);
    defer image1.deinit();

    var texture1: c_uint = undefined;
    gl.genTextures(1, &texture1);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture1);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, @as(c_int, @intCast(image1.width)), @as(c_int, @intCast(image1.height)), 0, gl.RGB, gl.UNSIGNED_BYTE, @as([*c]const u8, @ptrCast(image1.data)));
    gl.generateMipmap(gl.TEXTURE_2D);

    // image 2

    zstbi.setFlipVerticallyOnLoad(true);
    const image2_path = try common.pathToContent(allocator, "content/awesomeface.png");
    var image2 = try zstbi.Image.loadFromFile(&image2_path, 0);
    defer image2.deinit();

    var texture2: c_uint = undefined;
    gl.genTextures(1, &texture2);
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, texture2);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, @as(c_int, @intCast(image2.width)), @as(c_int, @intCast(image2.height)), 0, gl.RGBA, gl.UNSIGNED_BYTE, @as([*c]const u8, @ptrCast(image2.data)));
    gl.generateMipmap(gl.TEXTURE_2D);

    our_shader.use();
    our_shader.setInt("texture1", 0);
    our_shader.setInt("texture2", 1);

    while (!window.shouldClose()) {
        processInput(window);

        // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

        // s.setVec3f(name: [*c]const u8, value: [3]f32)
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture1);

        gl.bindVertexArray(VAO);
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

fn framebuffer_size_callback(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    gl.viewport(0, 0, @as(c_int, @intCast(width)), @as(c_int, @intCast(height)));
}

fn processInput(window: glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        _ = glfw.Window.setShouldClose(window, true);
    }
}
