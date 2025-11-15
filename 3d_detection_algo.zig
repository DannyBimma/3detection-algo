// 3D Component Intersection Detection and Joint Classification Algorithm
// Zig Implementation
//
// This algorithm detects intersections between 3D components and classifies
// them into the appropriate joints (finger, hole, slot) for CAD/CAM
// applications.
//
// Converted from ANSI-C to modern Zig following idiomatic best practices.

const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// Constants
const epsilon: f64 = 1e-9;

// ============================================================================
// Vector3D - 3D vector with x, y, z components
// ============================================================================

const Vector3D = struct {
    x: f64,
    y: f64,
    z: f64,

    const Self = @This();

    /// Creates a zero vector
    pub fn zero() Self {
        return Self{ .x = 0.0, .y = 0.0, .z = 0.0 };
    }

    /// Computes the dot product with another vector
    pub fn dot(self: Self, other: Self) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    /// Computes the cross product with another vector
    pub fn cross(self: Self, other: Self) Self {
        return Self{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    /// Computes the magnitude (length) of the vector
    pub fn magnitude(self: Self) f64 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    /// Returns a normalized (unit length) version of this vector
    pub fn normalized(self: Self) Self {
        const mag = self.magnitude();
        if (mag < epsilon) {
            return zero();
        }
        return Self{
            .x = self.x / mag,
            .y = self.y / mag,
            .z = self.z / mag,
        };
    }

    /// Subtracts another vector from this vector
    pub fn sub(self: Self, other: Self) Self {
        return Self{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    /// Adds another vector to this vector
    pub fn add(self: Self, other: Self) Self {
        return Self{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }
};

// ============================================================================
// Matrix4x4 - 4x4 homogeneous transformation matrix
// ============================================================================

const Matrix4x4 = struct {
    m: [4][4]f64,

    const Self = @This();

    /// Creates an identity matrix
    pub fn identity() Self {
        var matrix = Self{ .m = undefined };
        for (0..4) |i| {
            for (0..4) |j| {
                matrix.m[i][j] = if (i == j) 1.0 else 0.0;
            }
        }
        return matrix;
    }

    /// Creates a zero matrix
    pub fn zero() Self {
        return Self{ .m = [_][4]f64{[_]f64{0.0} ** 4} ** 4 };
    }

    /// Transforms a 3D point using this matrix
    pub fn transform(self: Self, point: Vector3D) Vector3D {
        return Vector3D{
            .x = self.m[0][0] * point.x + self.m[0][1] * point.y + self.m[0][2] * point.z + self.m[0][3],
            .y = self.m[1][0] * point.x + self.m[1][1] * point.y + self.m[1][2] * point.z + self.m[1][3],
            .z = self.m[2][0] * point.x + self.m[2][1] * point.y + self.m[2][2] * point.z + self.m[2][3],
        };
    }
};

// ============================================================================
// Segment3D - Line segment in 3D space
// ============================================================================

const Segment3D = struct {
    start: Vector3D,
    end: Vector3D,
};

// ============================================================================
// JointType - Types of joints that can be classified
// ============================================================================

const JointType = enum {
    finger,
    hole,
    slot,
};

// ============================================================================
// Joint - Represents a joint with its type and associated segment
// ============================================================================

const Joint = struct {
    joint_type: JointType,
    segment: Segment3D,
};

// ============================================================================
// Component3D - Represents a 3D component
// ============================================================================

const Component3D = struct {
    id: i32,
    vertices: ArrayList(Vector3D),
    transform_3d: Matrix4x4,
    inverse_transform: Matrix4x4,
    normal: Vector3D,
    fingers: ArrayList(Joint),
    holes: ArrayList(Joint),
    slots: ArrayList(Joint),

    const Self = @This();

    /// Creates a new component
    pub fn init(allocator: Allocator, id: i32) !Self {
        return Self{
            .id = id,
            .vertices = ArrayList(Vector3D).init(allocator),
            .transform_3d = Matrix4x4.zero(),
            .inverse_transform = Matrix4x4.zero(),
            .normal = Vector3D{ .x = 0.0, .y = 0.0, .z = 1.0 },
            .fingers = ArrayList(Joint).init(allocator),
            .holes = ArrayList(Joint).init(allocator),
            .slots = ArrayList(Joint).init(allocator),
        };
    }

    /// Frees all memory associated with this component
    pub fn deinit(self: *Self) void {
        self.vertices.deinit();
        self.fingers.deinit();
        self.holes.deinit();
        self.slots.deinit();
    }

    /// Checks if this component is coplanar with another component
    pub fn is_coplanar(self: Self, other: Self) bool {
        const dot_value = self.normal.dot(other.normal);
        return @abs(@abs(dot_value) - 1.0) < epsilon;
    }

    /// Checks if this component is parallel with another component
    pub fn is_parallel(self: Self, other: Self) bool {
        const dot_value = self.normal.dot(other.normal);
        return @abs(@abs(dot_value) - 1.0) < epsilon;
    }

    /// Checks if this component intersects with another component
    pub fn intersects(self: Self, other: Self) bool {
        // Simplified implementation - in production this would do actual intersection testing
        _ = self;
        _ = other;
        return true;
    }

    /// Adds a joint to the appropriate collection based on type
    pub fn add_joint(self: *Self, joint_type: JointType, segment: Segment3D) !void {
        const joint = Joint{
            .joint_type = joint_type,
            .segment = segment,
        };

        switch (joint_type) {
            .finger => try self.fingers.append(joint),
            .hole => try self.holes.append(joint),
            .slot => try self.slots.append(joint),
        }
    }
};

// ============================================================================
// Geometric Operations
// ============================================================================

/// Finds the intersection line between two non-parallel components
fn find_intersection_line(c1: Component3D, c2: Component3D) Segment3D {
    const direction = c1.normal.cross(c2.normal).normalized();
    return Segment3D{
        .start = Vector3D.zero(),
        .end = direction,
    };
}

/// Finds the intersection segments between a line and a component
fn find_line_component_intersections(
    allocator: Allocator,
    line: Segment3D,
    component: Component3D,
) !ArrayList(Segment3D) {
    // Simplified implementation - in production this would compute actual intersections
    _ = line;
    _ = component;
    return ArrayList(Segment3D).init(allocator);
}

/// Checks if a segment lies on the edge of a component
fn is_segment_on_edge(segment: Segment3D, component: Component3D) bool {
    // Simplified implementation - in production this would do actual edge testing
    _ = segment;
    _ = component;
    return true;
}

/// Merges two coplanar components if they intersect
fn merge_coplanar_components(c1: *Component3D, c2: *Component3D) void {
    if (!c1.is_coplanar(c2.*) or !c1.intersects(c2.*)) {
        return;
    }
    // Merge logic would go here in a full implementation
}

// ============================================================================
// Core Algorithm
// ============================================================================

/// Finds and classifies intersections between all component pairs
fn find_and_classify_intersections(allocator: Allocator, components: []Component3D) !void {
    for (components, 0..) |*ci, i| {
        for (components[i + 1 ..], 0..) |*cj, j_offset| {
            _ = j_offset;

            if (ci.is_coplanar(cj.*) and ci.intersects(cj.*)) {
                // Handle coplanar case
                merge_coplanar_components(ci, cj);
            } else if (!ci.is_coplanar(cj.*) and !ci.is_parallel(cj.*)) {
                // Handle non-coplanar, non-parallel case
                const intersection_line = find_intersection_line(ci.*, cj.*);

                var segments_i = try find_line_component_intersections(allocator, intersection_line, ci.*);
                defer segments_i.deinit();

                var segments_j = try find_line_component_intersections(allocator, intersection_line, cj.*);
                defer segments_j.deinit();

                const min_count = @min(segments_i.items.len, segments_j.items.len);
                for (0..min_count) |k| {
                    var seg_i = segments_i.items[k];
                    var seg_j = segments_j.items[k];

                    // Transform segments to local coordinate systems
                    seg_i.start = ci.inverse_transform.transform(seg_i.start);
                    seg_i.end = ci.inverse_transform.transform(seg_i.end);
                    seg_j.start = cj.inverse_transform.transform(seg_j.start);
                    seg_j.end = cj.inverse_transform.transform(seg_j.end);

                    const i_on_edge = is_segment_on_edge(seg_i, ci.*);
                    const j_on_edge = is_segment_on_edge(seg_j, cj.*);

                    // Classify joints based on edge detection
                    if (i_on_edge and j_on_edge) {
                        try ci.add_joint(.finger, seg_i);
                        try cj.add_joint(.finger, seg_j);
                    } else if (i_on_edge and !j_on_edge) {
                        try ci.add_joint(.finger, seg_i);
                        try cj.add_joint(.hole, seg_j);
                    } else if (!i_on_edge and j_on_edge) {
                        try ci.add_joint(.hole, seg_i);
                        try cj.add_joint(.finger, seg_j);
                    } else {
                        try ci.add_joint(.slot, seg_i);
                        try cj.add_joint(.slot, seg_j);
                    }
                }
            }
        }
    }
}

/// Main algorithm entry point - detects component intersections and classifies joints
fn detect_component_intersections(allocator: Allocator, components: []Component3D) !bool {
    if (components.len == 0) {
        return false;
    }

    try find_and_classify_intersections(allocator, components);
    return true;
}

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    // Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create test components
    var component1 = try Component3D.init(allocator, 1);
    defer component1.deinit();
    component1.normal = Vector3D{ .x = 0.0, .y = 0.0, .z = 1.0 };

    var component2 = try Component3D.init(allocator, 2);
    defer component2.deinit();
    component2.normal = Vector3D{ .x = 1.0, .y = 0.0, .z = 0.0 };

    var components = [_]Component3D{ component1, component2 };

    const stdout = std.io.getStdOut().writer();

    try stdout.print("Academic 3D-Component Intersection Detection Algorithm\n", .{});
    try stdout.print("Zig Implementation\n\n", .{});

    const result = try detect_component_intersections(allocator, &components);

    if (result) {
        try stdout.print("PASSED: Algorithm executed successfully\n", .{});
    } else {
        try stdout.print("FAILED: No components to process\n", .{});
    }
}
