const builtin = @import("builtin");
const std = @import("std");
const expect = std.testing.expect;

test "simple switch loop" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        fn doTheTest() !void {
            var start: u32 = undefined;
            start = 32;
            const result: u32 = s: switch (start) {
                0 => 0,
                1 => 1,
                2 => 2,
                3 => 3,
                else => |x| continue :s x / 2,
            };
            try expect(result == 2);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop with ranges" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        fn doTheTest() !void {
            var start: u32 = undefined;
            start = 32;
            const result = s: switch (start) {
                0...3 => |x| x,
                else => |x| continue :s x / 2,
            };
            try expect(result == 2);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop on enum" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        const E = enum { a, b, c };

        fn doTheTest() !void {
            var start: E = undefined;
            start = .a;
            const result: u32 = s: switch (start) {
                .a => continue :s .b,
                .b => continue :s .c,
                .c => 123,
            };
            try expect(result == 123);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop with error set" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        const E = error{ Foo, Bar, Baz };

        fn doTheTest() !void {
            var start: E = undefined;
            start = error.Foo;
            const result: u32 = s: switch (start) {
                error.Foo => continue :s error.Bar,
                error.Bar => continue :s error.Baz,
                error.Baz => 123,
            };
            try expect(result == 123);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop on tagged union" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_riscv64) return error.SkipZigTest;

    const S = struct {
        const U = union(enum) {
            a: u32,
            b: f32,
            c: f32,
        };

        fn doTheTest() !void {
            var start: U = undefined;
            start = .{ .a = 80 };
            const result = s: switch (start) {
                .a => |x| switch (x) {
                    0...49 => continue :s .{ .b = @floatFromInt(x) },
                    50 => continue :s .{ .c = @floatFromInt(x) },
                    else => continue :s .{ .a = x / 2 },
                },
                .b => |x| x,
                .c => return error.TestFailed,
            };
            try expect(result == 40.0);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop dispatching instructions" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        const Inst = union(enum) {
            set: u32,
            add: u32,
            sub: u32,
            end,
        };

        fn doTheTest() !void {
            var insts: [5]Inst = undefined;
            @memcpy(&insts, &[5]Inst{
                .{ .set = 123 },
                .{ .add = 100 },
                .{ .sub = 50 },
                .{ .sub = 10 },
                .end,
            });
            var i: u32 = 0;
            var cur: u32 = undefined;
            eval: switch (insts[0]) {
                .set => |x| {
                    cur = x;
                    i += 1;
                    continue :eval insts[i];
                },
                .add => |x| {
                    cur += x;
                    i += 1;
                    continue :eval insts[i];
                },
                .sub => |x| {
                    cur -= x;
                    i += 1;
                    continue :eval insts[i];
                },
                .end => {},
            }
            try expect(cur == 163);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "switch loop with pointer capture" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest; // TODO

    const S = struct {
        const U = union(enum) {
            a: u32,
            b: u32,
            c: u32,
        };

        fn doTheTest() !void {
            var a: U = .{ .a = 100 };
            var b: U = .{ .b = 200 };
            var c: U = .{ .c = 300 };
            inc: switch (a) {
                .a => |*x| {
                    x.* += 1;
                    continue :inc b;
                },
                .b => |*x| {
                    x.* += 10;
                    continue :inc c;
                },
                .c => |*x| {
                    x.* += 50;
                },
            }
            try expect(a.a == 101);
            try expect(b.b == 210);
            try expect(c.c == 350);
        }
    };
    try S.doTheTest();
    try comptime S.doTheTest();
}

test "unanalyzed continue with operand" {
    @setRuntimeSafety(false);
    label: switch (false) {
        false => if (false) continue :label true,
        true => {},
    }
}

test "switch loop on larger than pointer integer" {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_c) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    var entry: @Type(.{ .int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(usize) + 1,
    } }) = undefined;
    entry = 0;
    loop: switch (entry) {
        0 => {
            entry += 1;
            continue :loop 1;
        },
        1 => |x| {
            entry += 1;
            continue :loop x + 1;
        },
        2 => entry += 1,
        else => unreachable,
    }
    try expect(entry == 3);
}
