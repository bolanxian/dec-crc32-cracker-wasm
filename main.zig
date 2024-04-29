const cracker = @import("./dec-crc32-cracker.zig");
const init = cracker.init;
const getIndexes = cracker.getIndexes;
const itoa = cracker.itoa;
const str = &cracker.str;
const crc32_dec = cracker.crc32_dec;
const findIndex = cracker.findIndex;
const checkIndex = cracker.checkIndex;

test "!" {
    const std = @import("std");
    const expect = std.testing.expect;

    _ = init(0xEDB88320);

    const crc: u32 = crc32_dec(1234567890);
    const _indexes = getIndexes(crc);
    const begin: i32 = 1;
    const end: i32 = 2000000;

    var i = begin;
    while (i < end) : (i += 1) {
        i = findIndex(_indexes, i, end);
        if (i < 0) {
            break;
        }
        const last = checkIndex(i, _indexes);
        var num: i64 = @as(i64, i) * 1000;
        num += (last >> 8 & 0xF) * 100;
        num += (last >> 4 & 0xF) * 10;
        num += last & 0xF;
        try expect(switch (num) {
            729601752, 1234567890 => true,
            else => false,
        });
    }
    try expect(~crc == 0x261DAEE5);
}

pub fn main() !void {
    const std = @import("std");

    var _gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = _gpa.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    _ = init(0xEDB88320);

    for (args[1..]) |arg| {
        var crc: u32 = 0;
        for (arg) |char| {
            crc = crc << 4 | try switch (char) {
                '0'...'9' => char - '0',
                'A'...'F' => char - 'A' + 10,
                'a'...'f' => char - 'a' + 10,
                else => error.OutOfBounds,
            };
        }
        crc = ~crc;
        const _indexes = getIndexes(crc);
        const begin: i32 = 1;
        const end: i32 = 2000000;
        var i = begin;
        while (i < end) : (i += 1) {
            i = findIndex(_indexes, i, end);
            if (i < 0) {
                break;
            }
            const last = checkIndex(i, _indexes);
            const pre = str[0..itoa(@intCast(i), str)];
            var suf = [3]u8{ 0, 0, 0 };
            suf[0] = @intCast((last >> 8 & 0xF) + '0');
            suf[1] = @intCast((last >> 4 & 0xF) + '0');
            suf[2] = @intCast((last & 0xF) + '0');

            std.debug.print("crc32(\"{s}{s}\") = {s}\n", .{ pre, suf, arg });
        }
    }
}
