const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // first, compile asm/src/*.zig targeting risc-v
    // to generate examples
    const riscv_exe = b.addExecutable(.{
        .name = "fib_riscv",
        .root_module = b.createModule(.{
            .root_source_file = b.path("asm/src/fibonocci.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .riscv64,
                .os_tag = .freestanding,
                .cpu_features_add = std.Target.riscv.featureSet(&.{.@"64bit"}),
                .cpu_features_sub = std.Target.riscv.featureSet(&.{ .c, .m, .a, .f, .d }), // disable compressed instructions (can add later)
            }),
            .optimize = .ReleaseSmall, // small binary
        }),
    });

    const wasm_exe = b.addExecutable(.{
        .name = "wasmutter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi }),
            .optimize = optimize,
            .imports = &.{},
        }),
    });

    const native_exe = b.addExecutable(.{
        .name = "wasmutter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .optimize = optimize,
            .imports = &.{},
        }),
    });

    // Convert RISC-V ELF to raw binary (extract only .text section)
    const objcopy_cmd = b.addSystemCommand(&.{
        "riscv64-unknown-elf-objcopy",
        "-O",
        "binary",
        "--only-section=.text",
    });
    objcopy_cmd.addArtifactArg(riscv_exe);
    const riscv_bin = objcopy_cmd.addOutputFileArg("fib_riscv.bin");
    // Copy to asm/bin directory
    const copy_cmd = b.addSystemCommand(&.{ "cp", "-f" });
    copy_cmd.addFileArg(riscv_bin);
    copy_cmd.addArg("asm/bin/fib_riscv.bin");
    const install_bin = &copy_cmd.step;

    b.installArtifact(wasm_exe);
    b.installArtifact(native_exe);
    b.installArtifact(riscv_exe);
    b.getInstallStep().dependOn(install_bin);

    // add run cli
    const run_exe = b.addRunArtifact(native_exe);
    if (b.args) |args| {
        run_exe.addArgs(args);
    }
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
