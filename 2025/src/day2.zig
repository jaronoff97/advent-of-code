const std = @import("std");

const Range = struct {
    start: u128,
    end: u128,

    fn init(start: u128, end: u128) Range {
        return .{ .start = start, .end = end };
    }

    fn findInvalidIds(self: Range, allocator: std.mem.Allocator) ![]u128 {
        var invalid = std.ArrayList(u128).empty;
        var cur = self.start;
        while (cur <= self.end) {
            if (isInvalidIdNew(cur)) {
                try invalid.append(allocator, cur);
            }
            cur += 1;
        }

        return invalid.toOwnedSlice(allocator);
    }
};

fn numberToDigits(n: u128, out: *[40]u8) []const u8 {
    var x = n;
    var len: usize = 0;

    if (x == 0) {
        out[0] = 0;
        return out[0..1];
    }

    while (x > 0) : (x /= 10) {
        const casted: u8 = @intCast(x % 10);
        out[len] = casted;
        len += 1;
    }

    std.mem.reverse(u8, out[0..len]);
    return out[0..len];
}
fn computePrefixFunction(digits: []const u8, pi: []usize) void {
    const n = digits.len;
    pi[0] = 0;

    var i: usize = 1;
    var j: usize = 0;

    while (i < n) : (i += 1) {
        while (j > 0 and digits[i] != digits[j]) {
            j = pi[j - 1];
        }
        if (digits[i] == digits[j]) {
            j += 1;
        }
        pi[i] = j;
    }
}
fn isPeriodicDigits(digits: []const u8) bool {
    const n = digits.len;
    if (n <= 1) return false;

    var pi_buf: [40]usize = undefined;
    const pi = pi_buf[0..n];

    computePrefixFunction(digits, pi);

    const longest = pi[n - 1];
    const period = n - longest;

    return longest > 0 and (n % period == 0);
}
// This is the optimal answer with backtracking
fn isInvalidIdNew(n: u128) bool {
    var buf: [40]u8 = undefined;
    const digits = numberToDigits(n, &buf);
    return isPeriodicDigits(digits);
}

// This was the answer to the first part of the question
fn isInvalidIdStrOld(id_str: []const u8) bool {
    if (id_str.len % 2 != 0) return false;

    const mid = id_str.len / 2;
    const first = id_str[0..mid];
    const second = id_str[mid..];

    return std.mem.eql(u8, first, second);
}

// This is the answer to the second part of the question
fn isInvalidIdStr(id_str: []const u8) bool {
    var i: usize = 1;
    while (i <= (id_str.len / 2)) {
        const slice = id_str[0..i];
        if (isRepeated(slice, id_str)) {
            return true;
        }
        i += 1;
    }

    return false;
}

fn isRepeated(slice: []const u8, id_str: []const u8) bool {
    if (id_str.len % slice.len != 0) return false;
    var i: usize = 0;
    while (i < id_str.len) {
        if (!std.mem.eql(u8, id_str[i .. i + slice.len], slice)) return false;
        i += slice.len;
    }
    return true;
}

fn isInvalidId(number: u128) !bool {
    var buf: [64]u8 = undefined; // Enough room for u128 as decimal
    const str = try std.fmt.bufPrint(&buf, "{d}", .{number});
    return isInvalidIdStr(str);
}

fn comptimeIsInvalidId(comptime number: u128) bool {
    const str = std.fmt.comptimePrint("{d}", .{number});
    return isInvalidIdStr(str);
}

/// ------------------------------------------------------------
///  MAIN PROGRAM
/// ------------------------------------------------------------
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("day2input.txt", .{ .mode = .read_only });
    defer file.close();

    var buf: [8192]u8 = undefined;
    var reader = file.reader(&buf);
    const r = &reader.interface;

    var invalidIdSum: u128 = 0;
    while (r.takeDelimiterExclusive('\n')) |line| {
        // strip Windows \r
        var trimmed = line;
        if (trimmed.len > 0 and trimmed[trimmed.len - 1] == '\r') {
            trimmed = trimmed[0 .. trimmed.len - 1];
        }
        if (trimmed.len == 0) continue;

        var it = std.mem.splitScalar(u8, trimmed, ',');
        while (it.next()) |part| {
            const dash = std.mem.indexOfScalar(u8, part, '-') orelse
                return error.InvalidInput;

            const start = try std.fmt.parseUnsigned(u128, part[0..dash], 10);
            const end = try std.fmt.parseUnsigned(u128, part[dash + 1 ..], 10);

            const range = Range.init(start, end);
            const invalid_ids = try range.findInvalidIds(allocator);
            defer allocator.free(invalid_ids);

            for (invalid_ids) |id| {
                invalidIdSum += id;
            }
        }

        // consume delimiter
        _ = try r.take(1);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
    std.debug.print("invalid id sum: {d}\n", .{invalidIdSum});
}
