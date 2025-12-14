const std = @import("std");

pub fn build(b: *std.Build) void {
    // const wasm_target = b.standardTargetOptions(.{ .default_target = .{
    //     .cpu_arch = .wasm32,
    //     .os_tag = .wasi,
    // } });

    const wasm_exe = b.addExecutable(.{
        .name = "wasmutter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.standardTargetOptions(.{ .default_target = .{
                .cpu_arch = .wasm32,
                .os_tag = .wasi,
            } }),
            .optimize = .ReleaseSafe,
            .imports = &.{},
        }),
    });

    const native_exe = b.addExecutable(.{
        .name = "wasmutter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
            .imports = &.{},
        }),
    });

    b.installArtifact(wasm_exe);
    b.installArtifact(native_exe);

    // add run cli
    const run_exe = b.addRunArtifact(native_exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    // native test
    const test_exe = b.addTest(.{
        .name = "wasmutter_test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
            .imports = &.{},
        }),
    });

    const test_run_exe = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_run_exe.step);
}
