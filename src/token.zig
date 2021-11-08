const std = @import("std");
const util = @import("./util.zig");

pub const TokenType = enum {
    // Single-character tokens
    left_paren,
    right_paren,
    left_brace,
    right_brace,
    comma,
    dot,
    minus,
    plus,
    semicolon,
    slash,
    star,
    ampersand,

    // one or two character tokens
    bang,
    bang_equal,
    equal,
    equal_equal,
    greater,
    greater_equal,
    less,
    less_equal,

    // literals
    // Only identifiers and integers, no string literals
    id,
    int,

    // keywords,

    // special fns
    input,
    output,

    // Functions
    @"var",
    @"return",

    // Pointers
    alloc,
    @"null",

    // control flow
    @"while",
    @"if",
    @"else",

    // bool?
    @"false",
    @"true",

    EOF,
    error_unexpected_char,

    // from zig's stringToEnum. ComptimeStringMap is same strategy used for keywords in zig.
    // https://github.com/ziglang/zig/pull/5359#issuecomment-634171853
    //
    // See usage here https://github.com/ziglang/zig/blob/6a5094872f10acc629543cc7f10533b438d0283a/lib/std/meta.zig#L62
    //
    // A subset of TokenType is keywords.
    pub fn getKeyword(ident: []const u8) ?TokenType {
        const kvs = comptime build_kvs: {
            // This list should be kept in sync with the enum. It's manual, but done very rarely
            const keywords = [_]TokenType{
                .input,
                .output,
                .@"var",
                .@"return",
                .alloc,
                .@"null",
                .@"while",
                .@"if",
                .@"else",
                .@"false",
                .@"true",
            };

            const KV = struct {
                @"0": []const u8,
                @"1": TokenType,
            };
            var kvs_array: [keywords.len]KV = undefined;
            for (keywords) |keyword, i| {
                kvs_array[i] = KV{ .@"0" = std.meta.tagName(keyword), .@"1" = keyword };
            }
            break :build_kvs kvs_array[0..];
        };
        const map = comptime std.ComptimeStringMap(TokenType, kvs);
        return map.get(ident);
    }
};

pub const Token = struct {
    token_type: TokenType,
    start: u32,
    len: u32,

    pub const Index = u32;

    pub fn line(self: Token, source: []const u8) u32 {
        return util.line(self.start, source);
    }

    pub fn lexeme(self: Token, source: []const u8) []const u8 {
        return source[self.start .. self.start + self.len];
    }

    pub fn debug_print(self: Token, bytes: []const u8) void {
        if (self.token_type == .EOF) {
            std.debug.print("{}\n", .{self.token_type});
        } else {
            std.debug.print("{} \"{s}\" at {d}\n", .{ self.token_type, bytes[self.start .. self.start + self.len], self.start });
        }
    }
};
