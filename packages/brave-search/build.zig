const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    // pkg-config pulls gtk4/glib/gobject cflags+libs transitively.
    mod.linkSystemLibrary("webkitgtk-6.0", .{});

    const exe = b.addExecutable(.{
        .name = "brave-search",
        .root_module = mod,
    });
    b.installArtifact(exe);
}
