const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();

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

    const make_elf_dir = b.addSystemCommand(&.{ "mkdir", "-p", "asm/elf" });

    // Generate RISC-V binaries for every file in asm/src/
    var asm_src_dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "asm/src", .{ .iterate = true }) catch @panic("Failed to open asm/src directory");
    var iter = asm_src_dir.iterate();
    while (iter.next(io) catch @panic("Failed to iterate asm/src directory")) |entry| {
        if (entry.kind != .file) continue;
        const ext = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, ext, ".zig")) continue;

        const basename = std.fs.path.stem(entry.name);
        const riscv_exe = b.addExecutable(.{
            .name = basename,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("asm/src/{s}", .{entry.name})),
                .target = b.resolveTargetQuery(.{
                    .cpu_arch = .riscv64,
                    .os_tag = .freestanding,
                    .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 }, // required to skip .c features, not sure why
                    .cpu_features_sub = std.Target.riscv.featureSet(&.{ .c, .m, .a, .f, .d }), // disable compressed instructions (can add later)
                }),
                .optimize = .ReleaseSmall, // small binary
            }),
        });

        // Copy RISC-V ELF to asm/elf directory
        const copy_elf = b.addSystemCommand(&.{ "cp", "-f" });
        copy_elf.addArtifactArg(riscv_exe);
        copy_elf.addArg(b.fmt("asm/elf/{s}.elf", .{basename}));
        copy_elf.step.dependOn(&make_elf_dir.step);

        b.installArtifact(riscv_exe);
        b.getInstallStep().dependOn(&copy_elf.step);
        test_step.dependOn(&copy_elf.step);
    }

    b.installArtifact(wasm_exe);
    b.installArtifact(native_exe);

    // add run cli
    const run_exe = b.addRunArtifact(native_exe);
    if (b.args) |args| {
        run_exe.addArgs(args);
    }
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
