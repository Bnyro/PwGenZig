const capy = @import("capy");
const std = @import("std");
const fmt = @import("std").fmt;
const Allocator = std.mem.Allocator;

// Array of numbers
const NUMBERS = "0123456789";

// Array of small alphabets
const LETTERS = "abcdefghijklmnoqprstuvwyzx";

// Array of capital alphabets
const CAPITALS = "ABCDEFGHIJKLMNOQPRSTUYWVZX";

// Array of all the special symbols
const SYMBOLS = "!@#$^&*?";

var allocator: Allocator = undefined;

var passwordLength: capy.Label_Impl = undefined;
var result: capy.Label_Impl = undefined;
var includeNumbers: bool = true;
var includeLetters: bool = true;
var includeCapitals: bool = true;
var includeSymbols: bool = true;

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
    result = capy.Label(.{ .alignment = .Center });

    const content = capy.Column(.{ .spacing = 10 }, .{
        capy.Align(.{ .x = 0.5, .y = 0.5 }, capy.Row(.{ .spacing = 10 }, .{
            capy.Button(.{ .label = "-", .onclick = minusPassword }),
            &passwordLength,
            capy.Button(.{ .label = "+", .onclick = plusPassword }),
            capy.Button(.{ .label = "Generate", .onclick = generatePassword }),
        })),
        capy.Row(.{ .spacing = 10 }, .{
            try createCheckBox(1, "Include numbers"),
            try createCheckBox(2, "Include letters"),
        }),
        capy.Row(.{ .spacing = 10 }, .{
            try createCheckBox(3, "Include capitals"),
            try createCheckBox(4, "Include symbols"),
        }),
        &result,
    });
    try window.set(capy.Expanded(capy.Align(.{ .x = 0.5, .y = 0.5 }, content)));

    window.resize(800, 600);
    window.show();
    capy.runEventLoop();
}

fn generatePassword(_: *anyopaque) anyerror!void {
    if (!includeCapitals and !includeLetters and !includeNumbers and !includeSymbols) {
        result.setText("Please allow some chars first!");
        return;
    }
    const password = try getPassword(length);
    defer allocator.free(password);

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

// React to the value change of a checkbox
fn onCheckedChange(newValue: bool, userdata: usize) void {
    switch (userdata) {
        1 => includeNumbers = newValue,
        2 => includeLetters = newValue,
        3 => includeCapitals = newValue,
        4 => includeSymbols = newValue,
        else => return,
    }
}

// Create a new checkbox with the given userdata
fn createCheckBox(userdata: usize, label: [:0]const u8) !capy.CheckBox_Impl {
    var checkBox = capy.CheckBox(.{ .checked = true, .label = label });
    _ = try checkBox.checked.addChangeListener(.{ .function = onCheckedChange, .userdata = userdata });
    return checkBox;
}

// Returns a random password from the given length
fn getPassword(l: u8) ![]u8 {
    // Array of all possible, selected chars
    const chars = try getChars();
    defer allocator.free(chars);

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
        const i = random.uintLessThan(u8, @intCast(u8, chars.len));
        try password.append(chars[i]);
    }

    return password.items;
}

// Get the chars checked by the user
fn getChars() ![]u8 {
    var chars = std.ArrayList(u8).init(allocator);
    if (includeNumbers) try chars.appendSlice(NUMBERS);
    if (includeLetters) try chars.appendSlice(LETTERS);
    if (includeCapitals) try chars.appendSlice(CAPITALS);
    if (includeSymbols) try chars.appendSlice(SYMBOLS);
    return chars.items;
}
