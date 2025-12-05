const std = @import("std");

const input_bytes = @embedFile("day4input.txt");
const boardSize = 140;

const State = enum {
    Empty,
    Occupied,
    Accessible,
};

fn stateFromChar(char: u8) State {
    return switch (char) {
        '@' => State.Occupied,
        else => State.Empty,
    };
}

fn printBoard(toiletPaperLocs: *[boardSize][boardSize]State) void {
    for (toiletPaperLocs) |row| {
        for (row) |cell| {
            switch (cell) {
                State.Empty => std.debug.print(".", .{}),
                State.Occupied => std.debug.print("@", .{}),
                State.Accessible => std.debug.print("x", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
}

fn countAccessible(toiletPaperLocs: *[boardSize][boardSize]State) usize {
    var count: usize = 0;
    for (toiletPaperLocs) |row| {
        for (row) |cell| {
            if (cell == State.Accessible) {
                count += 1;
            }
        }
    }
    return count;
}

fn removeAccessible(toiletPaperLocs: *[boardSize][boardSize]State) usize {
    var count: usize = 0;
    for (toiletPaperLocs, 0..) |row, rowIndex| {
        for (row, 0..) |cell, colIndex| {
            if (cell == State.Accessible) {
                count += 1;
                toiletPaperLocs[rowIndex][colIndex] = State.Empty;
            }
        }
    }
    return count;
}

fn setAccessible(toiletPaperLocs: *[boardSize][boardSize]State, row: usize, col: usize) void {
    var count: usize = 0;
    const left = if (col == 0) 0 else col - 1;
    const right = if (col == boardSize - 1) boardSize - 1 else col + 1;
    const top = if (row == 0) 0 else row - 1;
    const bottom = if (row == boardSize - 1) boardSize - 1 else row + 1;

    for (top..bottom + 1) |r| {
        for (left..right + 1) |c| {
            if (r == row and c == col) continue;
            if (toiletPaperLocs[r][c] == State.Occupied or toiletPaperLocs[r][c] == State.Accessible) {
                count += 1;
            }
        }
    }
    if (count < 4 and toiletPaperLocs[row][col] == State.Occupied) {
        toiletPaperLocs[row][col] = State.Accessible;
    }
    return;
}

pub fn main() !void {
    @setEvalBranchQuota(100_000_000);
    // This is part 1.
    var toiletPaperLocs = comptime blk: {
        var it = std.mem.splitScalar(u8, input_bytes, '\n');
        var toiletPaperLocs: [boardSize][boardSize]State = undefined;
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
