const std = @import("std");

const input_bytes = @embedFile("day4input.txt");
const boardSize = 140;

const Empty: u2 = 0;
const Occupied: u2 = 1;
const Accessible: u2 = 2;

fn stateFromChar(char: u8) u2 {
    return switch (char) {
        '@' => Occupied,
        else => Empty,
    };
}

fn printBoard(toiletPaperLocs: *[boardSize][boardSize]u2) void {
    for (toiletPaperLocs) |row| {
        for (row) |cell| {
            switch (cell) {
                Empty => std.debug.print(".", .{}),
                Occupied => std.debug.print("@", .{}),
                Accessible => std.debug.print("x", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
}

fn countAccessible(toiletPaperLocs: *[boardSize][boardSize]u2) usize {
    var count: usize = 0;
    for (toiletPaperLocs) |row| {
        for (row) |cell| {
            if (cell == Accessible) {
                count += 1;
            }
        }
    }
    return count;
}

fn removeAccessible(toiletPaperLocs: *[boardSize][boardSize]u2) usize {
    var count: usize = 0;
    for (toiletPaperLocs, 0..) |row, rowIndex| {
        for (row, 0..) |cell, colIndex| {
            if (cell == Accessible) {
                count += 1;
                toiletPaperLocs[rowIndex][colIndex] = Empty;
            }
        }
    }
    return count;
}

/// Set a cell to Accessible if it is occupied and has less than 4 occupied neighbors.
inline fn setAccessible(toiletPaperLocs: *[boardSize][boardSize]u2, row: usize, col: usize) void {
    var count: usize = 0;
    const left = if (col == 0) 0 else col - 1;
    const right = if (col == boardSize - 1) boardSize - 1 else col + 1;
    const top = if (row == 0) 0 else row - 1;
    const bottom = if (row == boardSize - 1) boardSize - 1 else row + 1;

    for (top..bottom + 1) |r| {
        for (left..right + 1) |c| {
            if (r == row and c == col) continue;
            if (toiletPaperLocs[r][c] != Empty) {
                count += 1;
            }
        }
    }
    if (count < 4 and toiletPaperLocs[row][col] == Occupied) {
        toiletPaperLocs[row][col] = Accessible;
        return;
    }
    return;
}

pub fn main() !void {
    @setEvalBranchQuota(100_000_000);
    // This is part 1.
    var toiletPaperLocs = comptime blk: {
        var it = std.mem.splitScalar(u8, input_bytes, '\n');
        var toiletPaperLocs: [boardSize][boardSize]u2 = undefined;
        var rowIter: usize = 0;

        while (it.next()) |raw_line| {
            const clean =
                if (raw_line.len > 0 and raw_line[raw_line.len - 1] == '\r')
                    raw_line[0 .. raw_line.len - 1]
                else
                    raw_line;
            for (clean, 0..) |char, i| {
                toiletPaperLocs[rowIter][i] = stateFromChar(char);
            }
            rowIter += 1;
        }
        for (toiletPaperLocs, 0..) |row, rowIndex| {
            for (row, 0..) |_, colIndex| {
                setAccessible(&toiletPaperLocs, rowIndex, colIndex);
            }
        }
        break :blk toiletPaperLocs;
    };
    // this is part 2.
    var removedCount: usize = removeAccessible(&toiletPaperLocs);
    var totalRemoved: usize = 0;
    while (removedCount > 0) {
        for (toiletPaperLocs, 0..) |row, rowIndex| {
            for (row, 0..) |_, colIndex| {
                setAccessible(&toiletPaperLocs, rowIndex, colIndex);
            }
        }
        totalRemoved += removedCount;
        removedCount = removeAccessible(&toiletPaperLocs);
    }
    std.log.info("Total removed: {any}", .{totalRemoved});
    std.log.info("Final accessible count: {any}", .{countAccessible(&toiletPaperLocs)});
}
