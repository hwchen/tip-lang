const std = @import("std");
const lex = @import("./lex.zig");
const Allocator = std.mem.Allocator;

pub const Parser = struct {
    alloc: *Allocator,
    source: []const u8,

    const Self = @This();

    pub fn parse(self: *Self) !void {
        var lexer = lex.Lexer{
            .alloc = self.alloc,
            .source = self.source,
        };

        const tokens = try lexer.lex();
        defer tokens.deinit();

        for (tokens.items) |token| {
            token.debug_print(self.source);
        }
    }
};
