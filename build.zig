const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get zsdl dependency
    const zsdl = b.dependency("zsdl", .{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "console-emulator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zsdl2", .module = zsdl.module("zsdl2") },
            },
        }),
    });

    // Link libc (required for SDL)
    exe.linkLibC();

    // Link against SDL2 (using prebuilt)
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2main");

    // Add library paths for prebuilt SDL2
    @import("zsdl").prebuilt_sdl2.addLibraryPathsTo(exe);

    // Install SDL2 DLLs alongside executable
    if (@import("zsdl").prebuilt_sdl2.install(b, target.result, .bin, .{
        .ttf = false,
        .image = false,
    })) |install_sdl2_step| {
        b.getInstallStep().dependOn(install_sdl2_step);
    }

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the emulator");
    run_step.dependOn(&run_cmd.step);

    // Test step
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
