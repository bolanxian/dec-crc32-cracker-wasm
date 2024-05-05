const std = @import("std");
const cracker = @import("./dec-crc32-cracker.zig");
const init = cracker.init;
const getIndexes = cracker.getIndexes;
const itoa = cracker.itoa;
const crc32_dec = cracker.crc32_dec;
const findIndex = cracker.findIndex;
const checkIndex = cracker.checkIndex;

pub fn concat(i: i32, j: i32) i64 {
    var ret: i64 = @as(i64, i) * 1000;
    ret += (j >> 8 & 0xF) * 100;
    ret += (j >> 4 & 0xF) * 10;
    ret += j & 0xF;
    return ret;
}

const POLY = 0xEDB88320;
const begin: i32 = 1;
const end: i32 = 2000000;

test "!" {
    const expect = std.testing.expect;
    _ = init(POLY);
    const crc: u32 = crc32_dec(1234567890);
    const _indexes = getIndexes(crc);

    var i = begin;
    var count: u8 = 0;
    while (i < end) : (i += 1) {
        i = findIndex(_indexes, i, end);
        if (i < 0) {
            break;
        }
        const last = checkIndex(i, _indexes);
        try expect(switch (concat(i, last)) {
            729601752, 1234567890 => true,
            else => false,
        });
        count += 1;
    }
    try expect(count == 2);
    try expect(~crc == 0x261DAEE5);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = init(POLY);
    _ = args.skip();
    while (args.next()) |arg| {
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
        var i = begin;
        while (i < end) : (i += 1) {
            i = findIndex(_indexes, i, end);
            if (i < 0) {
                break;
            }
            const last = checkIndex(i, _indexes);
            std.debug.print("crc32(\"{d}\") = {s}\n", .{ concat(i, last), arg });
        }
    }
}
