const std = @import("std");
const clap = @import("clap");
const parse = @import("./parse.zig");

const io = std.io;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Writer = std.io.Writer;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = &gpa.allocator;

    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --help             Display this help and exit.              ") catch unreachable,
        clap.parseParam("<PATH>                 Execute file path.                       ") catch unreachable,
    };

    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer args.deinit();

    if (args.flag("--help")) {
        var wtr = std.io.getStdOut().writer();
        _ = try wtr.write("USAGE: ");
        try clap.usage(std.io.getStdOut().writer(), &params);
        _ = try wtr.write("\n\nOPTIONS:\n");
        try clap.help(std.io.getStdOut().writer(), &params);
    }

    if (args.positionals().len == 0) {
        return error.NoFile;
    } else if (args.positionals().len == 1) {
        try run(alloc, args.positionals()[0]);
    } else {
        return error.IncorrectArg;
    }
}

fn run(alloc: *Allocator, path: []const u8) !void {
    // Read file
    const file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer file.close();

    const max_size = 1024 * 8;
    const source = try file.readToEndAlloc(alloc, max_size);
    defer alloc.free(source);

    std.debug.print("{s}", .{source});

    // Parse
    var parser = parse.Parser{
        .alloc = alloc,
        .source = source,
    };

    try parser.parse();

    // Analysis
    // Execution
}
