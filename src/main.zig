const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Shader = @import("./Shader.zig");

const vertexShaderSource =
    \\ #version 410 core
    \\
    \\ layout (location = 0) in vec3 aPos;
    \\ layout (location = 1) in vec3 aColor;
    \\
    \\ out vec3 ourColor;
    \\
    \\ void main()
    \\ {
    \\   gl_Position = vec4(aPos, 1.0);
    \\   ourColor = aColor;
    \\ }
;

const fragmentShaderSource =
    \\ #version 410 core
    \\
    \\ out vec4 FragColor;
    \\ in vec3 ourColor;
    \\
    \\ void main() {
    \\  FragColor = vec4(ourColor, 1.0);
    \\ }
;

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
    const s = try Shader.create(allocator, "", "");

    _ = s;

    var vertexShader: c_uint = undefined;
    vertexShader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);

    // Attach the shader source to the vertex shader object and compile it
    gl.shaderSource(vertexShader, 1, @as([*c]const [*c]const u8, @ptrCast(&vertexShaderSource)), 0);
    gl.compileShader(vertexShader);

    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);

    var nrAttribiute: c_int = undefined;
    gl.getIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttribiute);
    std.log.info("Max number of vertex attributes: {} ", .{nrAttribiute});

    if (success == 0) {
        gl.getShaderInfoLog(vertexShader, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }

    // Fragment shader
    const fragShader = compile_frag_shader(fragmentShaderSource);
    defer gl.deleteShader(fragShader);

    // create a program object
    var shaderProgram: c_uint = undefined;
    shaderProgram = gl.createProgram();
    defer gl.deleteProgram(shaderProgram);

    // attach compiled shader objects to the program object and link
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragShader);
    gl.linkProgram(shaderProgram);

    // check if shader linking was successfull
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shaderProgram, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    const vertices = [_]f32{
        // Positions     Colors
        0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // bottom let
        0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top
    };

    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;

    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);

    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);

    // position attr
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    const offset: [*c]c_uint = (3 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), offset);
    gl.enableVertexAttribArray(1);

    gl.useProgram(shaderProgram);

    while (!window.shouldClose()) {
        processInput(window);

        // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.bindVertexArray(VAO);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

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

fn compile_frag_shader(source: []const u8) c_uint {
    var fragmentShader: c_uint = undefined;
    fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(fragmentShader, 1, @as([*c]const [*c]const u8, @ptrCast(&source)), 0);
    gl.compileShader(fragmentShader);

    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);

    if (success == 0) {
        gl.getShaderInfoLog(fragmentShader, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }
    return fragmentShader;
}
