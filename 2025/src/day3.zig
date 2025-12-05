const std = @import("std");

const input_bytes = @embedFile("day3input.txt");
const K = 12;

fn topKConsecutive(line: []const u8) u64 {
    if (line.len < K) return 0;

    var stack: [K]u8 = undefined;
    var top: usize = 0;

    // At most this many digits can be removed:
    var drops: usize = line.len - K;

    for (line) |c| {
        if (c == ' ') continue;
        const d = c - '0';

        // pop while better digit arrives
        while (top > 0 and stack[top - 1] < d and drops > 0) {
            top -= 1;
            drops -= 1;
        }

        // push if still space to fill
        if (top < K) {
            stack[top] = d;
            top += 1;
        } else {
            // can't push; we are full; digit must be discarded
            drops -= 1; // must count it as dropped
        }
    }

    // Build result number
    var out: u64 = 0;
    var i: usize = 0;
    while (i < K) : (i += 1) {
        out = out * 10 + stack[i];
    }
    return out;
}

fn topTwoConsec(line: []const u8) u64 {
    var nums: [2]u64 = [2]u64{ 0, 0 };

    for (line) |c| {
        if (c == ' ') continue;
        const num = c - '0';

        if (nums[1] > nums[0]) {
            nums[0] = nums[1];
            nums[1] = num;
        }
        if (num >= nums[1]) {
            nums[1] = num;
        }
    }

    return nums[0] * 10 + nums[1];
}

pub fn main() !void {
    @setEvalBranchQuota(100_000);
    const finalSum: u64 = comptime blk: {
        var sum: u64 = 0;
        var it = std.mem.splitScalar(u8, input_bytes, '\n');

        while (it.next()) |raw_line| {
            const clean =
                if (raw_line.len > 0 and raw_line[raw_line.len - 1] == '\r')
                    raw_line[0 .. raw_line.len - 1]
                else
                    raw_line;

            sum += topKConsecutive(clean);
        }

        break :blk sum;
    };

    std.debug.print("Final sum: {d}\n", .{finalSum});
}
