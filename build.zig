const std = @import("std");

const grubbery_url = "https://github.com/gwbtc/grubbery";
const grubbery_commit = "20ef61108f4ffae0c40ccd90e0ee7ae4d475709f";
const dependency_dir = "desk-deps/grubbery";

const Action = enum { build, clean, clear };

const DeskStep = struct {
    step: std.Build.Step,
    action: Action,
    install_path: []const u8,
    desk_path: ?[]const u8,

    fn create(b: *std.Build, name: []const u8, action: Action, desk_path: ?[]const u8) *DeskStep {
        const self = b.allocator.create(DeskStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = name,
                .owner = b,
                .makeFn = make,
            }),
            .action = action,
            .install_path = b.install_path,
            .desk_path = desk_path,
        };
        return self;
    }

    fn make(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
        const self: *DeskStep = @fieldParentPtr("step", step);
        switch (self.action) {
            .build => try buildDesk(step, self.install_path, self.desk_path),
            .clean => try deleteTree(self.install_path),
            .clear => {
                try deleteTree(self.install_path);
                try deleteTree("desk-deps");
            },
        }
    }
};

pub fn build(b: *std.Build) void {
    const desk_path = b.option([]const u8, "desk", "Replace this mounted desk after building");

    const assemble = DeskStep.create(b, "assemble desk", .build, desk_path);
    b.default_step.dependOn(&assemble.step);
    b.step("build", "Assemble Grubbery and the harness overlay").dependOn(&assemble.step);

    const clean = DeskStep.create(b, "clean output", .clean, null);
    b.step("clean", "Remove assembled output").dependOn(&clean.step);

    const clear = DeskStep.create(b, "clear output and dependencies", .clear, null);
    b.step("clear", "Remove assembled output and the Grubbery checkout").dependOn(&clear.step);
}

fn buildDesk(step: *std.Build.Step, install_path: []const u8, desk_path: ?[]const u8) !void {
    const allocator = step.owner.allocator;
    try run(step, &.{ "npm", "ci", "--prefix", "fe", "--no-audit", "--no-fund" });
    try run(step, &.{ "npm", "run", "build", "--prefix", "fe" });
    try checkoutGrubbery(step);

    try recreateDir(install_path);
    try copyDir(allocator, dependency_dir ++ "/desk", install_path);
    try copyDir(allocator, "desk", install_path);

    if (desk_path) |raw_path| {
        const target = try expandHome(allocator, step, raw_path);
        if (!exists(target)) return step.fail("desk path '{s}' does not exist", .{target});
        try clearDir(allocator, target);
        try copyDir(allocator, install_path, target);
    }
}

fn checkoutGrubbery(step: *std.Build.Step) !void {
    if (!exists(dependency_dir ++ "/.git")) {
        try std.fs.cwd().makePath(dependency_dir);
        try run(step, &.{ "git", "-C", dependency_dir, "init", "--quiet" });
        try run(step, &.{ "git", "-C", dependency_dir, "remote", "add", "origin", grubbery_url });
    }

    const commit_ref = grubbery_commit ++ "^{commit}";
    if (!try succeeds(step, &.{ "git", "-C", dependency_dir, "cat-file", "-e", commit_ref })) {
        try run(step, &.{ "git", "-C", dependency_dir, "fetch", "--depth", "1", "--filter=blob:none", "origin", grubbery_commit });
    }
    try run(step, &.{ "git", "-C", dependency_dir, "checkout", "--detach", "--force", "--quiet", grubbery_commit });
}

fn run(step: *std.Build.Step, argv: []const []const u8) !void {
    const result = std.process.Child.run(.{
        .allocator = step.owner.allocator,
        .argv = argv,
        .max_output_bytes = 1024 * 1024,
    }) catch |err| {
        if (err == error.FileNotFound) return step.fail("'{s}' was not found", .{argv[0]});
        return step.fail("could not run '{s}': {s}", .{ argv[0], @errorName(err) });
    };
    if (result.term == .Exited and result.term.Exited == 0) return;
    std.debug.print("{s}{s}", .{ result.stdout, result.stderr });
    return step.fail("'{s}' failed", .{argv[0]});
}

fn succeeds(step: *std.Build.Step, argv: []const []const u8) !bool {
    const result = std.process.Child.run(.{
        .allocator = step.owner.allocator,
        .argv = argv,
        .max_output_bytes = 64 * 1024,
    }) catch |err| {
        if (err == error.FileNotFound) return step.fail("'{s}' was not found", .{argv[0]});
        return false;
    };
    return result.term == .Exited and result.term.Exited == 0;
}

fn copyDir(allocator: std.mem.Allocator, source_path: []const u8, target_path: []const u8) !void {
    var source = try std.fs.cwd().openDir(source_path, .{ .iterate = true });
    defer source.close();
    try std.fs.cwd().makePath(target_path);

    var entries = source.iterate();
    while (try entries.next()) |entry| {
        const from = try std.fs.path.join(allocator, &.{ source_path, entry.name });
        const to = try std.fs.path.join(allocator, &.{ target_path, entry.name });
        switch (entry.kind) {
            .directory => try copyDir(allocator, from, to),
            .file => try std.fs.cwd().copyFile(from, std.fs.cwd(), to, .{}),
            else => {},
        }
    }
}

fn clearDir(allocator: std.mem.Allocator, path: []const u8) !void {
    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var names = std.ArrayList([]const u8){};
    defer names.deinit(allocator);
    var entries = dir.iterate();
    while (try entries.next()) |entry| try names.append(allocator, try allocator.dupe(u8, entry.name));

    for (names.items) |name| {
        const child = try std.fs.path.join(allocator, &.{ path, name });
        try std.fs.cwd().deleteTree(child);
    }
}

fn expandHome(allocator: std.mem.Allocator, step: *std.Build.Step, path: []const u8) ![]const u8 {
    if (!std.mem.eql(u8, path, "~") and !std.mem.startsWith(u8, path, "~/")) return path;
    const home = std.process.getEnvVarOwned(allocator, "HOME") catch |err| {
        return step.fail("cannot expand '~': {s}", .{@errorName(err)});
    };
    return if (path.len == 1) home else std.fs.path.join(allocator, &.{ home, path[2..] });
}

fn recreateDir(path: []const u8) !void {
    try deleteTree(path);
    try std.fs.cwd().makePath(path);
}

fn deleteTree(path: []const u8) !void {
    if (exists(path)) try std.fs.cwd().deleteTree(path);
}

fn exists(path: []const u8) bool {
    std.fs.cwd().access(path, .{}) catch return false;
    return true;
}
