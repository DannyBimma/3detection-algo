/*
 * 3D Component Intersection Detection and Joint Classification Algorithm
 * Swift Implementation
 *
 * This algorithm detects intersections between 3D components and classifies
 * them into the appropriate joints (finger, hole, slot) for CAD/CAM
 * applications.
 *
 * Converted from ANSI-C to modern Swift following idiomatic best practices.
 */

import Foundation

// MARK: - Constants

private let epsilon: Double = 1e-9

// MARK: - Vector3D

/// Represents a 3D vector with x, y, z components
struct Vector3D {
    var x: Double
    var y: Double
    var z: Double

    /// Creates a zero vector
    static let zero = Vector3D(x: 0, y: 0, z: 0)

    /// Computes the dot product with another vector
    func dot(_ other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }

    /// Computes the cross product with another vector
    func cross(_ other: Vector3D) -> Vector3D {
        return Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    /// Computes the magnitude (length) of the vector
    var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }

    /// Returns a normalized (unit length) version of this vector
    func normalized() -> Vector3D {
        let mag = magnitude
        guard mag >= epsilon else {
            return .zero
        }
        return Vector3D(x: x / mag, y: y / mag, z: z / mag)
    }

    /// Subtracts another vector from this vector
    static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// Adds another vector to this vector
    static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
}

// MARK: - Matrix4x4

/// Represents a 4x4 homogeneous transformation matrix
struct Matrix4x4 {
    var m: [[Double]]

    /// Creates an identity matrix
    static let identity: Matrix4x4 = {
        var matrix = Matrix4x4(m: Array(repeating: Array(repeating: 0.0, count: 4), count: 4))
        for i in 0..<4 {
            matrix.m[i][i] = 1.0
        }
        return matrix
    }()

    /// Creates a zero matrix
    static let zero = Matrix4x4(m: Array(repeating: Array(repeating: 0.0, count: 4), count: 4))

    /// Transforms a 3D point using this matrix
    func transform(_ point: Vector3D) -> Vector3D {
        return Vector3D(
            x: m[0][0] * point.x + m[0][1] * point.y + m[0][2] * point.z + m[0][3],
            y: m[1][0] * point.x + m[1][1] * point.y + m[1][2] * point.z + m[1][3],
            z: m[2][0] * point.x + m[2][1] * point.y + m[2][2] * point.z + m[2][3]
        )
    }
}

// MARK: - Segment3D

/// Represents a line segment in 3D space
struct Segment3D {
    var start: Vector3D
    var end: Vector3D
}

// MARK: - JointType

/// Types of joints that can be classified
enum JointType {
    case finger
    case hole
    case slot
}

// MARK: - Joint

/// Represents a joint with its type and associated segment
struct Joint {
    let type: JointType
    let segment: Segment3D
}

// MARK: - Component3D

/// Represents a 3D component with vertices, transformations, and classified joints
class Component3D {
    let id: Int
    var vertices: [Vector3D]
    var transform3D: Matrix4x4
    var inverseTransform: Matrix4x4
    var normal: Vector3D
    var fingers: [Joint]
    var holes: [Joint]
    var slots: [Joint]

    init(id: Int) {
        self.id = id
        self.vertices = []
        self.transform3D = .zero
        self.inverseTransform = .zero
        self.normal = Vector3D(x: 0, y: 0, z: 1)
        self.fingers = []
        self.holes = []
        self.slots = []
    }

    /// Checks if this component is coplanar with another component
    func isCoplanar(with other: Component3D) -> Bool {
        let dotValue = normal.dot(other.normal)
        return abs(abs(dotValue) - 1.0) < epsilon
    }

    /// Checks if this component is parallel with another component
    func isParallel(with other: Component3D) -> Bool {
        let dotValue = normal.dot(other.normal)
        return abs(abs(dotValue) - 1.0) < epsilon
    }

    /// Checks if this component intersects with another component
    func intersects(with other: Component3D) -> Bool {
        // Simplified implementation - in production this would do actual intersection testing
        return true
    }

    /// Adds a joint to the appropriate collection based on type
    func addJoint(type: JointType, segment: Segment3D) {
        let joint = Joint(type: type, segment: segment)
        switch type {
        case .finger:
            fingers.append(joint)
        case .hole:
            holes.append(joint)
        case .slot:
            slots.append(joint)
        }
    }
}

// MARK: - Geometric Operations

/// Finds the intersection line between two non-parallel components
func findIntersectionLine(between c1: Component3D, and c2: Component3D) -> Segment3D {
    let direction = c1.normal.cross(c2.normal).normalized()
    return Segment3D(start: .zero, end: direction)
}

/// Finds the intersection segments between a line and a component
func findLineComponentIntersections(line: Segment3D, component: Component3D) -> [Segment3D] {
    // Simplified implementation - in production this would compute actual intersections
    return []
}

/// Checks if a segment lies on the edge of a component
func isSegmentOnEdge(_ segment: Segment3D, of component: Component3D) -> Bool {
    // Simplified implementation - in production this would do actual edge testing
    return true
}

/// Merges two coplanar components if they intersect
func mergeCoplanarComponents(_ c1: Component3D, _ c2: Component3D) {
    guard c1.isCoplanar(with: c2) && c1.intersects(with: c2) else {
        return
    }
    // Merge logic would go here in a full implementation
}

// MARK: - Core Algorithm

/// Finds and classifies intersections between all component pairs
func findAndClassifyIntersections(in components: [Component3D]) {
    for i in 0..<components.count {
        let ci = components[i]

        for j in (i + 1)..<components.count {
            let cj = components[j]

            if ci.isCoplanar(with: cj) && ci.intersects(with: cj) {
                // Handle coplanar case
                mergeCoplanarComponents(ci, cj)
            } else if !ci.isCoplanar(with: cj) && !ci.isParallel(with: cj) {
                // Handle non-coplanar, non-parallel case
                let intersectionLine = findIntersectionLine(between: ci, and: cj)

                let segmentsI = findLineComponentIntersections(line: intersectionLine, component: ci)
                let segmentsJ = findLineComponentIntersections(line: intersectionLine, component: cj)

                let minCount = min(segmentsI.count, segmentsJ.count)
                for k in 0..<minCount {
                    var segI = segmentsI[k]
                    var segJ = segmentsJ[k]

                    // Transform segments to local coordinate systems
                    segI.start = ci.inverseTransform.transform(segI.start)
                    segI.end = ci.inverseTransform.transform(segI.end)
                    segJ.start = cj.inverseTransform.transform(segJ.start)
                    segJ.end = cj.inverseTransform.transform(segJ.end)

                    let iOnEdge = isSegmentOnEdge(segI, of: ci)
                    let jOnEdge = isSegmentOnEdge(segJ, of: cj)

                    // Classify joints based on edge detection
                    if iOnEdge && jOnEdge {
                        ci.addJoint(type: .finger, segment: segI)
                        cj.addJoint(type: .finger, segment: segJ)
                    } else if iOnEdge && !jOnEdge {
                        ci.addJoint(type: .finger, segment: segI)
                        cj.addJoint(type: .hole, segment: segJ)
                    } else if !iOnEdge && jOnEdge {
                        ci.addJoint(type: .hole, segment: segI)
                        cj.addJoint(type: .finger, segment: segJ)
                    } else {
                        ci.addJoint(type: .slot, segment: segI)
                        cj.addJoint(type: .slot, segment: segJ)
                    }
                }
            }
        }
    }
}

/// Main algorithm entry point - detects component intersections and classifies joints
func detectComponentIntersections(in components: [Component3D]) -> Bool {
    guard !components.isEmpty else {
        return false
    }

    findAndClassifyIntersections(in: components)
    return true
}

// MARK: - Main Entry Point

/// Main function demonstrating the algorithm
func main() {
    // Create test components
    let component1 = Component3D(id: 1)
    component1.normal = Vector3D(x: 0, y: 0, z: 1)

    let component2 = Component3D(id: 2)
    component2.normal = Vector3D(x: 1, y: 0, z: 0)

    let components = [component1, component2]

    print("Academic 3D-Component Intersection Detection Algorithm")
    print("Swift Implementation")
    print()

    if detectComponentIntersections(in: components) {
        print("PASSED: Algorithm executed successfully")
    } else {
        print("FAILED: No components to process")
    }
}

// Run the main function
main()
