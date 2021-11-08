const std = @import("std");
const tok = @import("./token.zig");
const util = @import("./util.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Token = tok.Token;
const TokenType = tok.TokenType;

pub const Lexer = struct {
    alloc: *Allocator,
    source: []const u8,
    start: u32 = 0,
    curr: u32 = 0,

    const Self = @This();

    pub fn lex(self: *Self) !ArrayList(Token) {
        var tokens = ArrayList(Token).init(self.alloc);

        while (!self.isAtEnd()) {
            self.start = self.curr;
            if (self.lexToken()) |token| {
                try tokens.append(token);
            }
        }

        try tokens.append(Token{
            .token_type = .EOF,
            .start = @intCast(u32, self.source.len),
            .len = @intCast(u32, self.source.len),
        });

        return tokens;
    }

    pub fn lexToken(self: *Self) ?Token {
        const c = self.advance();
        return switch (c) {
            '(' => self.makeToken(.left_paren),
            ')' => self.makeToken(.right_paren),
            '{' => self.makeToken(.left_brace),
            '}' => self.makeToken(.right_brace),
            ',' => self.makeToken(.comma),
            '.' => self.makeToken(.dot),
            '-' => self.makeToken(.minus),
            '+' => self.makeToken(.plus),
            ';' => self.makeToken(.semicolon),
            '*' => self.makeToken(.star),
            '&' => self.makeToken(.ampersand),

            '!' => self.makeToken(if (self.match('=')) .bang_equal else .bang),
            '=' => self.makeToken(if (self.match('=')) .equal_equal else .equal),
            '<' => self.makeToken(if (self.match('=')) .less_equal else .less),
            '>' => self.makeToken(if (self.match('=')) .greater_equal else .greater),

            '/' => if (self.match('/')) blk: {
                self.advanceComment();
                break :blk null;
            } else self.makeToken(.slash),

            ' ', '\r', '\n', '\t' => null,

            '0'...'9' => self.parseInt(),

            'a'...'z', 'A'...'Z', '_' => self.parseIdentifier(),

            else => self.unexpectedCharacterError(),
        };
    }

    // consume and more to next token
    fn advance(self: *Self) u8 {
        const res = self.source[self.curr];
        self.curr += 1;
        return res;
    }

    // consumes if matches
    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.curr] != expected) return false;

        self.curr += 1;
        return true;
    }

    /// Like advance, but does not consume
    fn peek(self: Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.curr];
    }

    fn peek2(self: Self) u8 {
        const idx = self.curr + 1;

        // idx out of bounds
        if (idx >= self.source.len) return 0;

        return self.source[idx];
    }

    fn makeToken(self: *Self, token_type: TokenType) Token {
        return Token{
            .token_type = token_type,
            .start = self.start,
            .len = self.curr - self.start,
        };
    }

    fn unexpectedCharacterError(self: *Self) Token {
        return Token{
            .token_type = .error_unexpected_char,
            .start = self.start,
            .len = self.curr - self.start,
        };
    }

    fn isAtEnd(self: Self) bool {
        return self.curr >= self.source.len;
    }

    fn advanceComment(self: *Self) void {
        while (self.peek() != '\n' and !self.isAtEnd()) {
            _ = self.advance();
        }
    }

    fn parseInt(self: *Self) Token {
        const isDigit = std.ascii.isDigit;

        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        return self.makeToken(.int);
    }

    fn parseIdentifier(self: *Self) Token {
        while (isIdentChar(self.peek())) {
            _ = self.advance();
        }

        if (TokenType.getKeyword(self.source[self.start..self.curr])) |keyword| {
            return self.makeToken(keyword);
        }

        return self.makeToken(.id);
    }
};

fn isIdentChar(c: u8) bool {
    return switch (c) {
        '0'...'9', 'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}
