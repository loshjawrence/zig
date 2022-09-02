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

const Vec3 = struct {
    // = means that's its default and isnt required during ctor
    // no = means you MUST supply something during ctor.
    x: f32 = undefined,
    y: f32 = 0,
    z: f32,
};

test "struct usage" {
    const myVec = Vec3{
        .z = 0,
    };
    _ = myVec;
}

const Stuff = struct {
    x: i32,
    y: i32,

    fn swap(self: *Stuff) void {
        // Structs have the unique property that when given a pointer to a struct,
        // one level of dereferencing is done automatically when accessing fields.
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "auto deref self" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}

const Result = union {
    int: i64,
    double: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    // can NOT do this, must assign new object
    // result.double = 12.34;
    result = Result{ .double = 12.34 };
    _ = result;
}

// Tagged unions are like std::variant
const Tag = enum { a, b, c };
const Tagged = union(Tag) { a: u8, b: f32, c: bool };
// another way to do the above (where enum names are same as the union names) is
// (also a demonstration of void value "none", maybe as away to do std::Optional)
// const Tagged = union(enum) { a: u8, b: f32, c: bool, none };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        // the lhs is the enum name, the rhs is the point to the union value for corresponding enum
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}

// Zig supports hex, octal, and binary integer literals
// NOTE: can use _ as visual separator
// const decimal: u8 = 255;
// const hex: u32 = 0xff_ff_00_00;
// const oct: u8 = 0o77;
// const bin: u8 = 0b11110000;

test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}

test "@intCast" {
    const x: u64 = 200;
    // NOTE: this will complain if there are bits set outside the range of u8
    const y: u8 = @intCast(u8, x);
    try expect(@TypeOf(y) == u8);
}

// integers are not allowed to overflow. overflows are detectable illegal behavior.
// decorate your arith operator with %, ex: +% or +%=
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}

test "float widening" {
    // floats are IEEE unless you
    // @setFloatMode(.Optimized);
    // this is gcc -ffast-math
    const a: f16 = 0;
    const b: f32 = a;
    const c: f64 = b;
    try expect(c == @as(f128, a));
}

test "int to float conversion" {
    const a: i32 = 0;
    const b = @intToFloat(f32, a);
    const c = @floatToInt(i32, b);
    try expect(c == a);
}

test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}

// Labelled loops
test "nested continue" {
    var count: usize = 0;
    var i: usize = 1;
    outer: while (i < 9) : (i += 1) {
        var j: usize = 1;
        while (j < 6) : (j += 1) {
            count += 1;
            continue :outer;
        }
    }

    try expect(count == 8);
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}

// Optionals use the syntax ?T and are used to store null or a value of type T.
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}

// orelse acts when optional is null. Unwraps the optional to its child type.
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}

// .? is shorthand for orelse unreachable
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}

// Here we use an if optional payload capture; a and b are equivalent here.
// if (b) |value| captures the value of b (in the cases where b is not null),
// and makes it available as value.
// As in the union example, the captured value is immutable,
// but we can still use a pointer capture to modify the value stored in b.
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}

var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}

// optional pointer and optional slice types don't take up extra memory
// internally they use the 0 value of the pointer for null
// this is how null pointers work in zig - they ust be unwrapped to a non-optional
// before dereferencing, which stops null poitner deref from happening accidentally.

fn fibonacci(n: u32) u32 {
    if (0 == n or 1 == n) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}

test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}

test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}

test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}

fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    const matType = Matrix(f32, 2, 2);
    try expect(matType == [2][2]f32);
    // const grid = matType{[2]f32{0, 1},[2]f32{2, 3}};
    // try expect(grid[0][0] == 0);
    // try expect(grid[0][1] == 1);
    // try expect(grid[1][0] == 2);
    // try expect(grid[1][1] == 3);
}

// reflection reflect uppon types using built-in @typeInfo
// which takes a type and returns a tagged union
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeInfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}

// can use @Type to create a type from a @typeInfo.
// @Type not implemented for enums, unions, functions, structs
// anonymous syntax is .{}
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },

    });


}

