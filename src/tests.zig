const expect = @import("std").testing.expect;

fn createFile() !void {
    // Error unions returned from a function can have their error sets inferred by not having an explicit error set.
    // This inferred error set contains all possible errors which the function may return.
    return error.AccessDenied;
}

test "inferred error set" {
    // type coercion takes place
    const x: error{AccessDenied}!void = createFile();

    // Zig does not let us ignore error unions via _ = x;
    // // we must unrwapr it with a try, catch or if by any means
    _ = x catch {};
}

// Error sets can be merged with || or &&
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
// anyerror is the global error set. it can have an error from any set coerce to a value of it.

test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    }; // put ; when switch as expression
    try expect(x == 1);
}

test "out of bounds" {
    // disables detectable undefined behavior for this scope to make it run faster in safe build modes
    // saftey is off for some build modes though
    // @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    // generates different erros when const(compile time) vs var(runtime panic)
    // const index = 5;
    // var index: u8 = 5;
    var index: u8 = 0;
    const b = a[index];
    _ = b;
}

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}
test "unreachable switch" {
    // unreachable is a way to panic when some piece of code is hit.
    // most likely use is in a switch.
    // unreachable coerces to what ever type it needs to (like noreturn does)
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}

fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}

test "naughty pointer" {
    // can't set poitners to 0, will cause "panic: cast causes pointer to be null"
    // var x: u16 = 0;
    var x: u16 = 1;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}

test "const pointers" {
    // pointers remember the constness of their payload so you can't deref and change them
    // const x = 1;
    var x: u8 = 1;
    var y = &x;
    y.* += 1;
}

test "usize/isize is size of a pointer" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };

    // second index is one past last
    const slice = array[0..3];

    try expect(total(slice) == 6);
}

test "slices type" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };

    // the n.. syntax is used when you want to go to the end
    const slice = array[2..];

    try expect(@TypeOf(slice) == *const [3]u8);
}

const Direction = enum(u32) { north = 10, south = 20, east = 30, west };

const Value = enum(u2) { zero, one, two };

test "enum ordinal value" {
    try expect(@enumToInt(Direction.north) == 10);
    try expect(@enumToInt(Direction.south) == 20);
    try expect(@enumToInt(Direction.east) == 30);
    try expect(@enumToInt(Direction.west) == 31);

    try expect(@enumToInt(Value.zero) == 0);
    try expect(@enumToInt(Value.one) == 1);
    try expect(@enumToInt(Value.two) == 2);
}

// Methods can be given to enums. These are just namespaced function that can be called with dot syntax
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,

    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    // The second is called an enum literal, see docs
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}

const Mode = enum {
    // var and const members in an enum are like static members in a struct
    var count: u32 = 0;
    on,
    off,
};

test "static enum members" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
