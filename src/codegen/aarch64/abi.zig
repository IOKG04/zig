const assert = @import("std").debug.assert;
const std = @import("std");
const Type = @import("../../Type.zig");
const Zcu = @import("../../Zcu.zig");

pub const Class = union(enum) {
    memory,
    byval,
    integer,
    double_integer,
    float_array: u8,
};

/// For `float_array` the second element will be the amount of floats.
pub fn classifyType(ty: Type, zcu: *Zcu) Class {
    assert(ty.hasRuntimeBitsIgnoreComptime(zcu));

    var maybe_float_bits: ?u16 = null;
    switch (ty.zigTypeTag(zcu)) {
        .@"struct" => {
            if (ty.containerLayout(zcu) == .@"packed") return .byval;
            const float_count = countFloats(ty, zcu, &maybe_float_bits);
            if (float_count <= sret_float_count) return .{ .float_array = float_count };

            const bit_size = ty.bitSize(zcu);
            if (bit_size > 128) return .memory;
            if (bit_size > 64) return .double_integer;
            return .integer;
        },
        .@"union" => {
            if (ty.containerLayout(zcu) == .@"packed") return .byval;
            const float_count = countFloats(ty, zcu, &maybe_float_bits);
            if (float_count <= sret_float_count) return .{ .float_array = float_count };

            const bit_size = ty.bitSize(zcu);
            if (bit_size > 128) return .memory;
            if (bit_size > 64) return .double_integer;
            return .integer;
        },
        .int, .@"enum", .error_set, .float, .bool => return .byval,
        .vector => {
            const bit_size = ty.bitSize(zcu);
            // TODO is this controlled by a cpu feature?
            if (bit_size > 128) return .memory;
            return .byval;
        },
        .optional => {
            assert(ty.isPtrLikeOptional(zcu));
            return .byval;
        },
        .pointer => {
            assert(!ty.isSlice(zcu));
            return .byval;
        },
        .error_union,
        .frame,
        .@"anyframe",
        .noreturn,
        .void,
        .type,
        .comptime_float,
        .comptime_int,
        .undefined,
        .null,
        .@"fn",
        .@"opaque",
        .enum_literal,
        .array,
        => unreachable,
    }
}

const sret_float_count = 4;
fn countFloats(ty: Type, zcu: *Zcu, maybe_float_bits: *?u16) u8 {
    const ip = &zcu.intern_pool;
    const target = zcu.getTarget();
    const invalid = std.math.maxInt(u8);
    switch (ty.zigTypeTag(zcu)) {
        .@"union" => {
            const union_obj = zcu.typeToUnion(ty).?;
            var max_count: u8 = 0;
            for (union_obj.field_types.get(ip)) |field_ty| {
                const field_count = countFloats(Type.fromInterned(field_ty), zcu, maybe_float_bits);
                if (field_count == invalid) return invalid;
                if (field_count > max_count) max_count = field_count;
                if (max_count > sret_float_count) return invalid;
            }
            return max_count;
        },
        .@"struct" => {
            const fields_len = ty.structFieldCount(zcu);
            var count: u8 = 0;
            var i: u32 = 0;
            while (i < fields_len) : (i += 1) {
                const field_ty = ty.fieldType(i, zcu);
                const field_count = countFloats(field_ty, zcu, maybe_float_bits);
                if (field_count == invalid) return invalid;
                count += field_count;
                if (count > sret_float_count) return invalid;
            }
            return count;
        },
        .float => {
            const float_bits = maybe_float_bits.* orelse {
                maybe_float_bits.* = ty.floatBits(target);
                return 1;
            };
            if (ty.floatBits(target) == float_bits) return 1;
            return invalid;
        },
        .void => return 0,
        else => return invalid,
    }
}

pub fn getFloatArrayType(ty: Type, zcu: *Zcu) ?Type {
    const ip = &zcu.intern_pool;
    switch (ty.zigTypeTag(zcu)) {
        .@"union" => {
            const union_obj = zcu.typeToUnion(ty).?;
            for (union_obj.field_types.get(ip)) |field_ty| {
                if (getFloatArrayType(Type.fromInterned(field_ty), zcu)) |some| return some;
            }
            return null;
        },
        .@"struct" => {
            const fields_len = ty.structFieldCount(zcu);
            var i: u32 = 0;
            while (i < fields_len) : (i += 1) {
                const field_ty = ty.fieldType(i, zcu);
                if (getFloatArrayType(field_ty, zcu)) |some| return some;
            }
            return null;
        },
        .float => return ty,
        else => return null,
    }
}
