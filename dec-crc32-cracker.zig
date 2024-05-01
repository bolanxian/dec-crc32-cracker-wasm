const zeroes = @import("std").mem.zeroes;

var table = zeroes([256]u32);
var lastIndex = zeroes([256]u8);
pub export fn init(POLY: u32) usize {
    for (0..256) |i| {
        var j: u32 = @intCast(i);
        for (0..8) |_| {
            j = if ((j & 1) != 0)
                (j >> 1) ^ POLY
            else
                j >> 1;
        }
        table[i] = j;
    }
    for (table, 0..256) |value, i| {
        lastIndex[value >> 24] = @intCast(i);
    }
    return @intFromPtr(&table);
}
pub var crc_index: u8 = 0;
pub fn crc32(buf: []const u8) u32 {
    var crc = ~@as(u32, 0);
    for (buf) |value| {
        crc_index = @truncate(crc ^ value);
        crc = (crc >> 8) ^ table[crc_index];
    }
    return crc;
}
const Indexes = extern union {
    value: u32,
    bytes: [4]u8,
};
pub var indexes: Indexes = zeroes(Indexes);
pub export fn getIndexes(_crc: u32) u32 {
    var crc = _crc;
    for ([_]u5{ 3, 2, 1, 0 }, [_]u5{ 0, 1, 2, 3 }) |i, j| {
        const _crc_index = lastIndex[crc >> (i << 3)];
        indexes.bytes[j] = _crc_index;
        crc ^= table[_crc_index] >> (j << 3);
    }
    return indexes.value;
}
pub fn swap(comptime T: type, a: *T, b: *T) void {
    const tmp: T = a.*;
    a.* = b.*;
    b.* = tmp;
}
pub fn itoa(num: u32, buf: *[10]u8) []const u8 {
    var i: u8 = 0;
    var tmp = num;
    while (true) {
        buf[i] = @truncate((tmp % 10) + '0');
        i += 1;
        tmp /= 10;
        if (tmp == 0) break;
    }
    var j: u8 = 0;
    while (j <= (i - 1) / 2) : (j += 1) {
        swap(u8, &buf[i - 1 - j], &buf[j]);
    }

    return buf[0..i];
}
pub var str = zeroes([10]u8);
pub export fn crc32_dec(i: u32) u32 {
    return crc32(itoa(i, &str));
}
pub fn check(_i: u32) i32 {
    var crc: u32 = crc32(itoa(_i, &str));
    if (crc_index != indexes.bytes[3]) {
        return -1;
    }
    var low: u12 = 0;
    for ([_]u8{ 2, 1, 0 }) |i| {
        const num: u8 = @as(u8, @truncate(crc)) ^ indexes.bytes[i];
        if (num < '0' or num > '9') {
            return -1;
        }
        low = (low << 4) | (num - '0');
        crc = (crc >> 8) ^ table[indexes.bytes[i]];
    }
    return low;
}
pub export fn checkIndex(i: i32, indexes_value: u32) i32 {
    indexes.value = indexes_value;
    return check(@intCast(i));
}
pub export fn findIndex(indexes_value: u32, begin: i32, end: i32) i32 {
    indexes.value = indexes_value;
    var i = begin;
    while (i < end) : (i += 1) {
        const low = check(@intCast(i));
        if (low >= 0) {
            return i;
        }
    }
    return -1;
}
