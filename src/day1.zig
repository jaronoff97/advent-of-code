const std = @import("std");

const totalNumbers = 100;

const RotationDirection = enum(u2) {
    Left = 0,
    Right = 1,
};

const Move = struct { dir: RotationDirection, amount: u16 };

const Dial = struct {
    position: u16,
    timesZero: u16,

    fn create(allocator: std.mem.Allocator, start: u16) !*Dial {
        const dial = try allocator.create(Dial);
        errdefer allocator.destroy(dial);
        dial.position = start;
        dial.timesZero = 0;
        return dial;
    }

    fn rotate(self: *Dial, dir: RotationDirection, amount: u16) void {
        const fixedAmount = amount % totalNumbers;
        var timesAtZero = amount / totalNumbers;
        const delta = switch (dir) {
            .Left => (100 -% fixedAmount),
            .Right => fixedAmount,
        };
        const crossedZero: bool = switch (dir) {
            .Left => (self.position != 0 and fixedAmount > self.position),
            .Right => (self.position != 0 and self.position + fixedAmount > totalNumbers),
        };
        self.position = (self.position + delta) % totalNumbers;
        if (self.position == 0) {
            timesAtZero += 1;
        }
        if (crossedZero) {
            timesAtZero += 1;
        }
        self.timesZero += timesAtZero;
    }
};

fn parseLine(line: []const u8) !?Move {
    if (line.len < 2) return null;
    const dir: RotationDirection = if (line[0] == 'R') .Right else .Left;
    const amount = try std.fmt.parseInt(u16, line[1..], 10);
    return Move{ .dir = dir, .amount = amount };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const dial = try Dial.create(allocator, 50);
    defer allocator.destroy(dial);

    var file = try std.fs.cwd().openFile("day1input.txt", .{ .mode = .read_only });
    defer file.close();

    // Create buffered reader
    var file_buf: [8192]u8 = undefined;
    var file_reader = file.reader(&file_buf);
    const reader = &file_reader.interface;

    // Read lines using takeDelimiterExclusive
    while (reader.takeDelimiterExclusive('\n')) |line| {
        // Handle Windows line endings
        var trimmed_line = line;
        if (line.len > 0 and line[line.len - 1] == '\r') {
            trimmed_line = line[0 .. line.len - 1];
        }

        if (trimmed_line.len == 0) continue;

        const parsed = try parseLine(trimmed_line) orelse {
            std.debug.print("Invalid: {s}\n", .{trimmed_line});
            continue;
        };
        dial.rotate(parsed.dir, parsed.amount);
        _ = try reader.take(1);
    } else |err| switch (err) {
        error.EndOfStream => {},
        error.StreamTooLong => return err,
        else => return err,
    }

    std.debug.print("Final position: {d}, times crossed zero: {d}\n", .{ dial.position, dial.timesZero });
}
