const std = @import("std");

const input_bytes = @embedFile("day5input.txt");

const Range = struct {
    start: usize,
    end: usize,

    fn contains(self: Range, num: usize) bool {
        return num >= self.start and num <= self.end;
    }
};

pub fn main() !void {
    @setEvalBranchQuota(100_000_000);
    const alloc = std.heap.page_allocator;
    // This is part 1.
    var it = std.mem.splitScalar(u8, input_bytes, '\n');
    var freshIngredients: usize = 0;

    var ingredientRanges = try std.ArrayList(Range).initCapacity(alloc, 6);
    defer ingredientRanges.deinit(alloc);
    var availableIngredients = try std.ArrayList(usize).initCapacity(alloc, 6);
    defer availableIngredients.deinit(alloc);

    var blankFound = false;
    while (it.next()) |raw_line| {
        const clean =
            if (raw_line.len > 0 and raw_line[raw_line.len - 1] == '\r')
                raw_line[0 .. raw_line.len - 1]
            else
                raw_line;
        if (raw_line.len == 0) {
            blankFound = true;
            continue;
        }
        if (!blankFound) {
            const dash = std.mem.indexOfScalar(u8, clean, '-') orelse
                return error.InvalidInput;

            const start = try std.fmt.parseUnsigned(usize, clean[0..dash], 10);
            const end = try std.fmt.parseUnsigned(usize, clean[dash + 1 ..], 10);
            try ingredientRanges.append(alloc, Range{ .start = start, .end = end });
        } else {
            const ingredientId = try std.fmt.parseUnsigned(usize, clean, 10);
            try availableIngredients.append(alloc, ingredientId);
        }
    }
    for (availableIngredients.items) |ingredient| {
        var isFresh = false;
        for (ingredientRanges.items) |range| {
            if (range.contains(ingredient)) {
                isFresh = true;
            }
        }
        if (isFresh) {
            freshIngredients += 1;
        }
    }
    std.log.info("Fresh ingredients count: {any}", .{freshIngredients});
    // The above is part 1.

    // Make a mutable copy of the ranges
    var ranges = try alloc.alloc(Range, ingredientRanges.items.len);
    defer alloc.free(ranges);
    std.mem.copyForwards(Range, ranges, ingredientRanges.items);

    // Sort by .start
    std.mem.sort(Range, ranges, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    var total_fresh: u128 = 0;

    // Start with the first range
    var current = ranges[0];

    for (ranges[1..]) |r| {
        if (r.start <= current.end + 1) {
            // Overlapping or touching: merge
            if (r.end > current.end)
                current.end = r.end;
        } else {
            // Disjoint: commit previous interval
            total_fresh += (current.end - current.start + 1);
            current = r;
        }
    }

    // Add final interval
    total_fresh += (current.end - current.start + 1);

    std.log.info("Total possible Fresh ingredients count: {d}", .{total_fresh});
}
