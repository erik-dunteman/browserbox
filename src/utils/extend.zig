const std = @import("std");

/// Zero-extends a value of type T to u64.
/// T must be an integer type.
pub fn zero_extend(comptime T: type, val: T) u64 {
    return @as(u64, @intCast(val));
}

/// Sign-extends a value of type T to u64.
/// The value is interpreted as a signed integer of the same bit-width as T,
/// then widened to i64, then bitcast to u64.
pub fn sign_extend(comptime T: type, val: T) u64 {
    const bits = @bitSizeOf(T);
    const SignedT = std.meta.Int(.signed, bits);
    const signed_val: SignedT = @bitCast(val);
    const widened: i64 = @intCast(signed_val);
    return @bitCast(widened);
}
