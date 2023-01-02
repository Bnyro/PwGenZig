const capy = @import("capy");
const std = @import("std");
const fmt = @import("std").fmt;

const Allocator = std.mem.Allocator;

var allocator: Allocator = undefined;

var passwordLength: capy.Label_Impl = undefined;
var result: capy.Label_Impl = undefined;

const MIN_LENGTH = 4;
const MAX_LENGTH = 32;
var length: u8 = 8;

pub fn main() !void {
    try capy.backend.init();

    // create the globally used allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (comptime !@import("builtin").target.isWasm()) {
        _ = gpa.deinit();
    };
    if (comptime !@import("builtin").target.isWasm()) {
        allocator = gpa.allocator();
    } else {
        allocator = std.heap.page_allocator;
    }

    var window = try capy.Window.init();

    passwordLength = capy.Label(.{ .text = "8" });
    result = capy.Label(.{ .text = "Hello World", .alignment = .Center });

    const content = capy.Column(.{ .spacing = 10 }, .{
        capy.Align(.{ .x = 0.5, .y = 0.5 }, capy.Row(.{ .spacing = 10 }, .{
            capy.Button(.{ .label = "-", .onclick = minusPassword }),
            &passwordLength,
            capy.Button(.{ .label = "+", .onclick = plusPassword }),
        })),
        capy.Button(.{ .label = "Generate", .onclick = generatePassword }),
        &result,
    });
    try window.set(capy.Expanded(capy.Align(.{ .x = 0.5, .y = 0.5 }, content)));

    window.resize(800, 600);
    window.show();
    capy.runEventLoop();
}

fn generatePassword(_: *anyopaque) anyerror!void {
    const password = try getPassword(length);
    result.setText(password[0..length]);
}

fn minusPassword(_: *anyopaque) anyerror!void {
    if (length > MIN_LENGTH) {
        updatePasswordLength(length - 1);
    }
}

fn plusPassword(_: *anyopaque) anyerror!void {
    if (length < MAX_LENGTH) {
        updatePasswordLength(length + 1);
    }
}

// Update the text of the length label
fn updatePasswordLength(newLength: u8) void {
    length = newLength;
    var buf: [2]u8 = undefined;
    const res = fmt.bufPrint(&buf, "{}", .{length}) catch return;
    passwordLength.setText(res);
}

// Returns a random password from the given length
fn getPassword(l: u8) ![]u8 {
    // Array of numbers
    const numbers = "0123456789";

    // Array of small alphabets
    const letters = "abcdefghijklmnoqprstuvwyzx";

    // Array of capital alphabets
    const capitals = "ABCDEFGHIJKLMNOQPRSTUYWVZX";

    // Array of all the special symbols
    const symbols = "!@#$^&*?";

    // Array of all possible chars
    const chars = numbers ++ letters ++ capitals ++ symbols;

    var password = std.ArrayList(u8).init(allocator);
    // defer password.deinit();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var index: u8 = 0;
    while (index < l) : (index += 1) {
        const i = random.uintLessThan(u8, chars.len);
        try password.append(chars[i]);
    }

    const pw = password.items;
    return pw;
}
