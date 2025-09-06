# 3D Component Intersection Detection Algorithm

A high-performance ANSI-C implementation of the 3D Component Intersection Detection and Joint Classification Algorithm, converted from academic pseudocode for real-world CAD/CAM applications.

![Original Algorithm](3d_algo_img.JPG)

## Overview

This algorithm detects intersections between 3D components and classifies them into the appropriate joint types (finger, hole, slot) for manufacturing and assembly applications. The implementation follows Algorithm 2 from the referenced academic paper, with significant optimisations for production use.

## Algorithm Conversion Process

### 1. Academic Pseudocode Analysis

The original algorithm; which I randomly found on social media (shown right here: `3d_algo_img.JPG`), provided me with a high-level but still very detailed mathematical description with two main phases:

- **Phase 1 (Lines 2-7)**: Merge coplanar faces and convert to global coordinate system
- **Phase 2 (Lines 8-28)**: Find the intersection segments and classify the joints based on their geometric relationships

### 2. Data Structure Design

The pseudocode used abstract mathematical concepts that required concrete C implementations:

```c
// Abstract "{C}" in the pseudocode became structured component arrays
typedef struct {
    Component3D *components;
    int count;
    int capacity;
} ComponentArray;

// Mathematical vectors became explicit 3D structures
typedef struct {
    double x, y, z;
} Vector3D;

// Transform matrices became 4x4 homogeneous matrices
typedef struct {
    double m[4][4];
} Matrix4x4;
```

### 3. Algorithm Translation Challenges

#### Geometric Predicates

- **Coplanarity Test**: `coplanar(Ci, Cj)` → `are_coplanar()` using dot product of normals
- **Parallelism Test**: `¬parallel(Ci, Cj)` → `are_parallel()` with epsilon tolerance
- **Intersection Detection**: Abstract intersection → concrete geometric calculations

#### Coordinate Transformations

- **Global Conversion**: `Ci.V^2D ← Ci.T^3D^-1 · Vi∪j` → `transform_point()` with 4x4 matrices
- **Local to Global**: Implemented through matrix multiplication operations

#### Joint Classification Logic

The original conditional logic (lines 17-28) was translated into well organised control flow, or structured decision trees if you wanna be fancy:

```c
if (i_on_edge && j_on_edge) {
    add_joint(&ci->fingers, FINGER_JOINT, &seg_i);
    add_joint(&cj->fingers, FINGER_JOINT, &seg_j);
} else if (i_on_edge && !j_on_edge) {
    // ... additional cases
}
```

### 4. Memory Management

The pseudocode assumed infinite memory, which my machine does not have; so my C implementation adds some code of reason:

- Dynamic array resizing with `realloc()`
- Proper cleanup with `destroy_*()` functions
- Error handling for allocation failures

## Code Optimisations

### Performance Optimisations

1. **Inline Functions**: Vector operations (`dot_product`, `cross_product`, `vector_magnitude`) are marked `static inline` for compiler optimisation
2. **Memory Layout**: Structures are cache efficiency friendly since related data get grouped together
3. **Early Returns**: Geometric predicates return immediately on failure conditions
4. **Epsilon Comparisons**: Floating-point comparisons use `EPSILON 1e-9` for some numerical stability

### Algorithmic Improvements

1. **Nested Loop Optimisation**: Component pairs are processed with `j = i + 1` to avoid redundant comparisons
2. **Conditional Branching**: Coplanar and non-coplanar cases handled separately to reduce unnecessary computations
3. **Memory Reallocation**: Dynamic arrays double in size to discount allocation costs

## Practical Applications

### CAD/CAM Manufacturing

- **Automated Assembly Planning**: Identifies how components fit together in complex assemblies
- **Tool Path Generation**: Determines machining sequences for multi-part fabrication
- **Quality Control**: Validates design intent against manufacturing constraints

### Robotics and Automation

- **Grasping Planning**: Determines optimal finger/gripper positions for object manipulation
- **Path Planning**: Identifies collision-free assembly sequences
- **Fixture Design**: Automatically generates holding and positioning systems

### Architectural and Structural Engineering

- **Timber Framing**: Calculates traditional wood joinery (mortise and tenon, dovetails)
- **Steel Connections**: Determines bolt patterns and welding requirements
- **Modular Construction**: Plans prefabricated component interfaces

### 3D Printing and Additive Manufacturing

- **Support Structure Generation**: Identifies overhangs requiring support material
- **Multi-Part Printing**: Optimises part orientation and assembly sequences
- **Interlocking Designs**: Creates puzzle-like assemblies for complex geometries

## Usage

### Compilation

```bash
gcc -o 3d_detection_algo 3d_detection_algo.c -lm
```

### Execution

```bash
./3d_detection_algo
```

### Integration

The algorithm is designed as a library with a clean API:

```c
ComponentArray *components = create_component_array(initial_size);
// ... populate components with your 3D data ...
int result = detect_component_intersections(components);
destroy_component_array(components);
```

## Algorithm Performance

- **Time Complexity**: O(n²) for n components, with early termination for non-intersecting pairs
- **Space Complexity**: O(n + m) where m is the total number of intersection segments
- **Numerical Stability**: IEEE 754 double precision with configurable epsilon tolerance

## Future Enhancements

- GPU acceleration for large component sets
- Spatial indexing (octree, BSP) for O(n log n) performance
- Real-time visualisation integration
- Multi-threaded processing for independent component pairs
- Don't do any of the above and find a real job instead 🥲
