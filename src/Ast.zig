// AST

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;

const tok = @import("./token.zig");
const Token = tok.Token;
const TokenType = tok.TokenType;

pub const TokenList = []const Token;

pub const Tree = @This();

source: []const u8,
tokens: TokenList,
root: Program,

/// Currently don't do cleanup, use an arena otherwise all will leak
pub fn deinit(self: *Tree) void {
    _ = self;
}

pub const Program = struct {
    functions: ArrayList(FunctionDecl),
};

pub const FunctionDecl = struct {
    name: Id,
    params: ArrayList(Id),
    var_decls: ArrayList(Id),
    body: ArrayList(Statement),
    ret: Expr,
};

pub const Expr = union(enum) {
    int: isize,
    id: Id,
    unary: Unary,
    binary: Binary,
    group: *Expr,
    input,
    // functions
    function_call: FunctionCall,
    function_value: FunctionValue,
    // records
    record_decl: HashMap(Id, Expr),
    field_access: FieldAccess,
    // pointers
    alloc: *Expr,
    pointer: Id, // create pointer to variable
    deref: *Expr, // dereferences a point value
    nul,

    pub const Unary = struct {
        op: TokenType,
        lhs: *Expr,
        rhs: *Expr,
    };

    pub const Binary = struct {
        op: TokenType,
        lhs: *Expr,
        rhs: *Expr,
    };

    pub const FunctionCall = struct {
        name: Id,
        arguments: ArrayList(Expr),
    };

    // the function called is an expression which evaluates to
    // a function value
    pub const FunctionValue = struct {
        name: *Expr,
        arguments: ArrayList(Expr),
    };

    pub const FieldAccess = struct {
        record: *Expr,
        field: Id,
    };
};

pub const Statement = union(enum) {
    assignment: Assignment,
    output: *Expr,
    if_stmt: IfStatement,
    whil: WhileLoop,
    field_assignment: FieldAssignment,
    field_assignment_deref: FieldAssignmentDeref,

    pub const Assignment = struct {
        id: Id,
        expr: *Expr,
    };

    pub const IfStatement = struct {
        condition: *Expr,
        then: *Statement,
        els: ?*Statement,
    };

    pub const WhileLoop = struct {
        condition: *Expr,
        body: *Statement,
    };

    pub const FieldAssignment = struct {
        record: Id,
        field: Id,
        expr: *Expr,
    };

    pub const FieldAssignmentDeref = struct {
        record: Expr,
        field: Id,
        expr: *Expr,
    };
};

pub const Id = struct {
    value: []const u8,
};
