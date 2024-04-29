const zeroes = @import("std").mem.zeroes;

var table: [256]u32 = zeroes([256]u32);
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
    return @intFromPtr(&table);
}
pub var crc_index: u8 = zeroes(u8);
pub fn crc32(buf: [*]u8, len: u8) u32 {
    var crc = ~@as(u32, 0);
    for (buf, 0..len) |value, _| {
        crc_index = @truncate(crc ^ value);
        crc = (crc >> 8) ^ table[crc_index];
    }
    return crc;
}
pub fn lastIndex(crc: u8) u8 {
    for (table, 0..256) |value, i| {
        if (crc == @as(u8, @intCast(value >> 24))) {
            return @truncate(i);
        }
    }
    return 0;
}
const Indexes = extern union {
    value: u32,
    bytes: [4]u8,
};
pub var indexes: Indexes = zeroes(Indexes);
pub export fn getIndexes(_crc: u32) u32 {
    var crc = _crc;
    for ([_]u5{ 3, 2, 1, 0 }, [_]u5{ 0, 1, 2, 3 }) |i, j| {
        const _crc_index = lastIndex(@truncate(crc >> (i << 3)));
        indexes.bytes[j] = _crc_index;
        crc ^= table[_crc_index] >> (j << 3);
    }
    return indexes.value;
}
pub fn itoa(_unum: u32, buf: [*]u8) u8 {
    var i: u8 = 0;
    var unum = _unum;
    while (true) {
        buf[i] = @truncate((unum % 10) + '0');
        i += 1;
        unum /= 10;
        if (!(unum != 0)) break;
    }
    var j: u8 = 0;
    while (j <= (i - 1) / 2) {
        const temp: u8 = buf[j];
        buf[j] = buf[i - 1 - j];
        buf[i - 1 - j] = temp;
        j += 1;
    }

    return i;
}
pub var str = zeroes([10]u8);
pub export fn crc32_dec(i: u32) u32 {
    const len = itoa(i, &str);
    const crc = crc32(&str, len);
    return crc;
}
pub fn check(_i: u32) i32 {
    const len: u8 = itoa(_i, &str);
    var crc: u32 = crc32(&str, len);
    if (crc_index != indexes.bytes[3]) {
        return -1;
    }
    var low: u12 = 0;
    for ([_]u8{ 2, 1, 0 }) |i| {
        const num: u8 = @as(u8, @truncate(crc)) ^ indexes.bytes[i];
        if (num < 48 or num > 57) {
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
