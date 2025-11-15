--[[
 3D Component Intersection Detection and Joint Classification Algorithm
 Lua Implementation

 This algorithm detects intersections between 3D components and classifies
 them into the appropriate joints (finger, hole, slot) for CAD/CAM
 applications.

 Converted from ANSI-C to modern Lua following idiomatic best practices.
 Requires Lua 5.4 or later.
--]]

-- Constants
local EPSILON = 1e-9

-- ============================================================================
-- Vector3D - 3D vector with x, y, z components
-- ============================================================================

local Vector3D = {}
Vector3D.__index = Vector3D

--- Creates a new Vector3D
function Vector3D.new(x, y, z)
    local self = setmetatable({}, Vector3D)
    self.x = x or 0.0
    self.y = y or 0.0
    self.z = z or 0.0
    return self
end

--- Creates a zero vector
function Vector3D.zero()
    return Vector3D.new(0.0, 0.0, 0.0)
end

--- Computes the dot product with another vector
function Vector3D:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

--- Computes the cross product with another vector
function Vector3D:cross(other)
    return Vector3D.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

--- Computes the magnitude (length) of the vector
function Vector3D:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

--- Returns a normalized (unit length) version of this vector
function Vector3D:normalized()
    local mag = self:magnitude()
    if mag < EPSILON then
        return Vector3D.zero()
    end
    return Vector3D.new(self.x / mag, self.y / mag, self.z / mag)
end

--- Subtracts another vector from this vector
function Vector3D:sub(other)
    return Vector3D.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

--- Adds another vector to this vector
function Vector3D:add(other)
    return Vector3D.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

-- Metatable operations for operator overloading
Vector3D.__sub = Vector3D.sub
Vector3D.__add = Vector3D.add

-- ============================================================================
-- Matrix4x4 - 4x4 homogeneous transformation matrix
-- ============================================================================

local Matrix4x4 = {}
Matrix4x4.__index = Matrix4x4

--- Creates a new Matrix4x4
function Matrix4x4.new()
    local self = setmetatable({}, Matrix4x4)
    self.m = {}
    for i = 1, 4 do
        self.m[i] = {}
        for j = 1, 4 do
            self.m[i][j] = 0.0
        end
    end
    return self
end

--- Creates an identity matrix
function Matrix4x4.identity()
    local matrix = Matrix4x4.new()
    for i = 1, 4 do
        matrix.m[i][i] = 1.0
    end
    return matrix
end

--- Creates a zero matrix
function Matrix4x4.zero()
    return Matrix4x4.new()
end

--- Transforms a 3D point using this matrix
function Matrix4x4:transform(point)
    return Vector3D.new(
        self.m[1][1] * point.x + self.m[1][2] * point.y + self.m[1][3] * point.z + self.m[1][4],
        self.m[2][1] * point.x + self.m[2][2] * point.y + self.m[2][3] * point.z + self.m[2][4],
        self.m[3][1] * point.x + self.m[3][2] * point.y + self.m[3][3] * point.z + self.m[3][4]
    )
end

-- ============================================================================
-- Segment3D - Line segment in 3D space
-- ============================================================================

local Segment3D = {}
Segment3D.__index = Segment3D

--- Creates a new Segment3D
function Segment3D.new(start, ending)
    local self = setmetatable({}, Segment3D)
    self.start = start or Vector3D.zero()
    self.ending = ending or Vector3D.zero()
    return self
end

-- ============================================================================
-- JointType - Types of joints that can be classified
-- ============================================================================

local JointType = {
    FINGER = "finger",
    HOLE = "hole",
    SLOT = "slot"
}

-- ============================================================================
-- Joint - Represents a joint with its type and associated segment
-- ============================================================================

local Joint = {}
Joint.__index = Joint

--- Creates a new Joint
function Joint.new(joint_type, segment)
    local self = setmetatable({}, Joint)
    self.joint_type = joint_type
    self.segment = segment
    return self
end

-- ============================================================================
-- Component3D - Represents a 3D component
-- ============================================================================

local Component3D = {}
Component3D.__index = Component3D

--- Creates a new Component3D
function Component3D.new(id)
    local self = setmetatable({}, Component3D)
    self.id = id
    self.vertices = {}
    self.transform_3d = Matrix4x4.zero()
    self.inverse_transform = Matrix4x4.zero()
    self.normal = Vector3D.new(0.0, 0.0, 1.0)
    self.fingers = {}
    self.holes = {}
    self.slots = {}
    return self
end

--- Checks if this component is coplanar with another component
function Component3D:is_coplanar(other)
    local dot_value = self.normal:dot(other.normal)
    return math.abs(math.abs(dot_value) - 1.0) < EPSILON
end

--- Checks if this component is parallel with another component
function Component3D:is_parallel(other)
    local dot_value = self.normal:dot(other.normal)
    return math.abs(math.abs(dot_value) - 1.0) < EPSILON
end

--- Checks if this component intersects with another component
function Component3D:intersects(other)
    -- Simplified implementation - in production this would do actual intersection testing
    return true
end

--- Adds a joint to the appropriate collection based on type
function Component3D:add_joint(joint_type, segment)
    local joint = Joint.new(joint_type, segment)

    if joint_type == JointType.FINGER then
        table.insert(self.fingers, joint)
    elseif joint_type == JointType.HOLE then
        table.insert(self.holes, joint)
    elseif joint_type == JointType.SLOT then
        table.insert(self.slots, joint)
    end
end

-- ============================================================================
-- Geometric Operations
-- ============================================================================

--- Finds the intersection line between two non-parallel components
local function find_intersection_line(c1, c2)
    local direction = c1.normal:cross(c2.normal):normalized()
    return Segment3D.new(Vector3D.zero(), direction)
end

--- Finds the intersection segments between a line and a component
local function find_line_component_intersections(line, component)
    -- Simplified implementation - in production this would compute actual intersections
    return {}
end

--- Checks if a segment lies on the edge of a component
local function is_segment_on_edge(segment, component)
    -- Simplified implementation - in production this would do actual edge testing
    return true
end

--- Merges two coplanar components if they intersect
local function merge_coplanar_components(c1, c2)
    if not c1:is_coplanar(c2) or not c1:intersects(c2) then
        return
    end
    -- Merge logic would go here in a full implementation
end

-- ============================================================================
-- Core Algorithm
-- ============================================================================

--- Finds and classifies intersections between all component pairs
local function find_and_classify_intersections(components)
    for i = 1, #components do
        local ci = components[i]

        for j = i + 1, #components do
            local cj = components[j]

            if ci:is_coplanar(cj) and ci:intersects(cj) then
                -- Handle coplanar case
                merge_coplanar_components(ci, cj)
            elseif not ci:is_coplanar(cj) and not ci:is_parallel(cj) then
                -- Handle non-coplanar, non-parallel case
                local intersection_line = find_intersection_line(ci, cj)

                local segments_i = find_line_component_intersections(intersection_line, ci)
                local segments_j = find_line_component_intersections(intersection_line, cj)

                local min_count = math.min(#segments_i, #segments_j)
                for k = 1, min_count do
                    local seg_i = segments_i[k]
                    local seg_j = segments_j[k]

                    -- Transform segments to local coordinate systems
                    seg_i.start = ci.inverse_transform:transform(seg_i.start)
                    seg_i.ending = ci.inverse_transform:transform(seg_i.ending)
                    seg_j.start = cj.inverse_transform:transform(seg_j.start)
                    seg_j.ending = cj.inverse_transform:transform(seg_j.ending)

                    local i_on_edge = is_segment_on_edge(seg_i, ci)
                    local j_on_edge = is_segment_on_edge(seg_j, cj)

                    -- Classify joints based on edge detection
                    if i_on_edge and j_on_edge then
                        ci:add_joint(JointType.FINGER, seg_i)
                        cj:add_joint(JointType.FINGER, seg_j)
                    elseif i_on_edge and not j_on_edge then
                        ci:add_joint(JointType.FINGER, seg_i)
                        cj:add_joint(JointType.HOLE, seg_j)
                    elseif not i_on_edge and j_on_edge then
                        ci:add_joint(JointType.HOLE, seg_i)
                        cj:add_joint(JointType.FINGER, seg_j)
                    else
                        ci:add_joint(JointType.SLOT, seg_i)
                        cj:add_joint(JointType.SLOT, seg_j)
                    end
                end
            end
        end
    end
end

--- Main algorithm entry point - detects component intersections and classifies joints
local function detect_component_intersections(components)
    if #components == 0 then
        return false
    end

    find_and_classify_intersections(components)
    return true
end

-- ============================================================================
-- Main Entry Point
-- ============================================================================

local function main()
    -- Create test components
    local component1 = Component3D.new(1)
    component1.normal = Vector3D.new(0.0, 0.0, 1.0)

    local component2 = Component3D.new(2)
    component2.normal = Vector3D.new(1.0, 0.0, 0.0)

    local components = {component1, component2}

    print("Academic 3D-Component Intersection Detection Algorithm")
    print("Lua Implementation")
    print()

    local result = detect_component_intersections(components)

    if result then
        print("PASSED: Algorithm executed successfully")
    else
        print("FAILED: No components to process")
    end
end

-- Run the main function
main()
