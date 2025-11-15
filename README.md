# 3D Component Intersection Detection Algorithm

Multi-language implementations of the 3D Component Intersection Detection and Joint Classification Algorithm, converted from academic pseudocode for real-world CAD/CAM applications.

**Available Implementations:**
- **[ANSI-C](#c-implementation)** - High-performance native implementation
- **[Node.js](#nodejs-implementation)** - Server-side JavaScript for backend services
- **[Browser](#browser-implementation)** - Client-side JavaScript with interactive visualization

![Original Algorithm](3d_algo_img.JPG)

## Quick Start

Choose the implementation that best fits your needs:

| I want to... | Use this implementation |
|--------------|-------------------------|
| Process large datasets quickly | [C Implementation](#c-implementation) |
| Integrate into a Node.js backend | [Node.js Implementation](#nodejs-implementation) |
| Create an interactive web demo | [Browser Implementation](#browser-implementation) |
| Learn how the algorithm works | [Interactive Demo](#interactive-visualization-demo) |

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

## Implementations

### C Implementation

**File:** `3d_detection_algo.c`

The ANSI-C implementation provides maximum performance for production environments and large-scale batch processing.

#### Features
- High-performance inline vector operations
- Manual memory management for optimal control
- Zero dependencies (only standard C library and math.h)
- Compiled to native machine code
- Cache-friendly data structures

#### Pros
- ✅ **Fastest execution** - 5-10x faster than JavaScript implementations
- ✅ **Lowest memory footprint** - Direct memory control with no GC overhead
- ✅ **Production-ready** - ANSI-C compatible with all major compilers
- ✅ **Portable** - Runs on any platform with a C compiler
- ✅ **No runtime dependencies** - Self-contained executable

#### Cons
- ❌ **Manual memory management** - Requires careful handling of allocations
- ❌ **Steeper learning curve** - C knowledge required for modifications
- ❌ **No built-in visualization** - Output is text-based
- ❌ **Compilation required** - Changes require recompilation

#### When to Use
- Processing thousands of components in batch mode
- Embedded systems or resource-constrained environments
- Maximum performance is critical
- Integration with existing C/C++ codebases
- Real-time manufacturing systems

#### Installation & Running

**Prerequisites:**
- GCC or any ANSI-C compatible compiler
- Make (optional)

**Compile:**
```bash
gcc -o 3d_detection_algo 3d_detection_algo.c -lm -O3
```

**Run:**
```bash
./3d_detection_algo
```

**Integration Example:**
```c
#include "3d_detection_algo.c"

int main() {
    ComponentArray *components = create_component_array(10);

    // Create component 1
    components->components = realloc(components->components, sizeof(Component3D) * 2);
    components->count = 2;
    init_component(&components->components[0], 1);
    components->components[0].normal = (Vector3D){0.0, 0.0, 1.0};

    // Create component 2
    init_component(&components->components[1], 2);
    components->components[1].normal = (Vector3D){1.0, 0.0, 0.0};

    // Run detection
    detect_component_intersections(components);

    // Access results
    printf("Component 1 has %d finger joints\n",
           components->components[0].fingers.count);

    destroy_component_array(components);
    return 0;
}
```

---

### Node.js Implementation

**File:** `3d_detection_algo_node.js`

The Node.js implementation provides a balance of performance and developer experience for server-side applications.

#### Features
- ES6+ classes and modern JavaScript features
- Float64Arrays for efficient matrix operations
- Dual module support (CommonJS + ESM)
- Clean object-oriented API
- V8 engine optimizations

#### Pros
- ✅ **Easy to use** - Intuitive JavaScript API
- ✅ **Fast development** - No compilation step
- ✅ **Good performance** - V8 JIT compilation
- ✅ **NPM ecosystem** - Easy to integrate with Node.js tools
- ✅ **Cross-platform** - Works anywhere Node.js runs
- ✅ **Automatic memory management** - No manual cleanup needed

#### Cons
- ❌ **Slower than C** - ~2-5x slower for large datasets
- ❌ **Memory overhead** - JavaScript object overhead
- ❌ **Requires Node.js** - Runtime dependency
- ❌ **No visualization** - Text output only

#### When to Use
- Building REST APIs or microservices
- Processing moderate datasets (hundreds of components)
- Integration with Node.js backend systems
- Rapid prototyping and development
- When team expertise is in JavaScript

#### Installation & Running

**Prerequisites:**
- Node.js 14+ installed

**Run directly:**
```bash
node 3d_detection_algo_node.js
```

**Usage Example:**

```javascript
const { IntersectionDetector, Component3D } = require('./3d_detection_algo_node.js');

// Create detector instance
const detector = new IntersectionDetector();

// Create components with normal vectors
const component1 = new Component3D(1);
component1.setNormal(0, 0, 1);  // XY plane

const component2 = new Component3D(2);
component2.setNormal(1, 0, 0);  // YZ plane

const component3 = new Component3D(3);
component3.setNormal(0, 1, 0);  // XZ plane

// Add components to detector
detector.addComponent(component1);
detector.addComponent(component2);
detector.addComponent(component3);

// Run intersection detection
detector.detectIntersections();

// Retrieve and process results
const results = detector.getResults();

results.forEach(component => {
    console.log(`Component ${component.id}:`);
    console.log(`  Finger joints: ${component.fingerJoints}`);
    console.log(`  Hole joints: ${component.holeJoints}`);
    console.log(`  Slot joints: ${component.slotJoints}`);
});
```

**Expected Output:**
```
Academic 3D-Component Intersection Detection Algorithm
Node.js Implementation

✓ Algorithm executed successfully

Component 1:
  Finger joints: 0
  Hole joints: 0
  Slot joints: 0
Component 2:
  Finger joints: 0
  Hole joints: 0
  Slot joints: 0
```

---

### Browser Implementation

**File:** `3d_detection_algo_browser.js`

The browser implementation adds event-driven architecture and animation support for interactive web applications.

#### Features
- ES6 modules for modern browsers
- Event-driven architecture with custom callbacks
- Step-by-step animation support
- Lightweight and framework-agnostic
- No build tools required

#### Pros
- ✅ **Interactive visualization** - Real-time algorithm animation
- ✅ **Event system** - Hook into every step of the algorithm
- ✅ **Educational** - Perfect for learning and demonstrations
- ✅ **No build required** - Works directly in browsers
- ✅ **Framework agnostic** - Use with React, Vue, vanilla JS, etc.
- ✅ **User-friendly** - Easy to understand and modify

#### Cons
- ❌ **Browser only** - Cannot run server-side
- ❌ **Lower performance** - Browser runtime overhead
- ❌ **Limited dataset size** - Best for <100 components
- ❌ **No multi-threading** - Single-threaded JavaScript

#### When to Use
- Creating interactive educational demos
- Building web-based CAD/CAM tools
- Prototyping and visualization
- Teaching computational geometry
- Client-side joint classification

#### Installation & Running

**Prerequisites:**
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Local web server (for ES6 modules)

**Option 1: Python HTTP Server**
```bash
python3 -m http.server 8000
# Open http://localhost:8000/demo.html
```

**Option 2: Node.js serve**
```bash
npx serve
# Open http://localhost:3000/demo.html
```

**Option 3: VS Code Live Server**
- Install "Live Server" extension
- Right-click `demo.html` → "Open with Live Server"

#### Usage Example

```html
<!DOCTYPE html>
<html>
<head>
    <title>3D Intersection Detection</title>
</head>
<body>
    <div id="output"></div>

    <script type="module">
        import {
            IntersectionDetector,
            Component3D,
            createDemoScene
        } from './3d_detection_algo_browser.js';

        // Method 1: Use the pre-configured demo scene
        const detector = createDemoScene();

        // Listen to algorithm events
        detector.on('algorithm:start', (data) => {
            console.log(`Starting detection with ${data.componentCount} components`);
        });

        detector.on('step:start', (data) => {
            console.log(`Step ${data.step}/${data.totalSteps}: C${data.component1} ↔ C${data.component2}`);
        });

        detector.on('joint:classified', (data) => {
            console.log(`Joint found: C${data.component1.id} (${data.component1.jointType}) - C${data.component2.id} (${data.component2.jointType})`);
        });

        detector.on('algorithm:complete', (data) => {
            console.log('Algorithm complete!');
            displayResults(data.components);
        });

        // Run detection with animation
        await detector.detectIntersections();

        function displayResults(components) {
            const output = document.getElementById('output');
            components.forEach(comp => {
                output.innerHTML += `
                    <div style="margin: 10px; padding: 10px; border: 2px solid ${comp.color}">
                        <h3>Component ${comp.id}</h3>
                        <p>Finger Joints: ${comp.fingerCount}</p>
                        <p>Hole Joints: ${comp.holeCount}</p>
                        <p>Slot Joints: ${comp.slotCount}</p>
                    </div>
                `;
            });
        }
    </script>
</body>
</html>
```

**Custom Configuration:**
```javascript
import { IntersectionDetector, Component3D } from './3d_detection_algo_browser.js';

// Create detector with custom options
const detector = new IntersectionDetector({
    animate: true,           // Enable step-by-step animation
    animationDelay: 1000    // 1 second between steps
});

// Create custom components
const comp1 = new Component3D(1, '#ff6b6b');  // Red component
comp1.setNormal(0, 0, 1);

const comp2 = new Component3D(2, '#4ecdc4');  // Teal component
comp2.setNormal(1, 0, 0);

detector.addComponent(comp1);
detector.addComponent(comp2);

await detector.detectIntersections();
```

---

### Interactive Visualization Demo

**Files:** `demo.html`, `demo.css`, `demo.js`

A complete interactive web application for visualizing the algorithm in real-time.

#### Demo Features

**Visualization:**
- 3D components rendered on HTML5 Canvas
- Normal vector visualization
- Customizable grid background
- Color-coded components

**Controls:**
- ▶️ Start/Stop algorithm execution
- 🔄 Reset to initial state
- 🎚️ Animation speed control (100ms - 2000ms)
- 👁️ Toggle normal vectors on/off
- 📏 Toggle grid display
- 🔄 Auto-rotate mode

**Real-time Feedback:**
- Live algorithm log with timestamps
- Step-by-step progress indicator
- Event-based status updates
- Color-coded log messages (info, success, warning, error)

**Results Display:**
- Component-by-component breakdown
- Joint type counts per component
- Color-coded joint types:
  - 🟢 Finger joints (green)
  - 🟠 Hole joints (orange)
  - 🔴 Slot joints (red)
- Total joint calculations

#### Running the Demo

**Step 1: Start a local server**

Choose one option:

```bash
# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000

# Node.js (npx)
npx serve -p 8000

# Node.js (http-server)
npm install -g http-server
http-server -p 8000
```

**Step 2: Open in browser**

Navigate to: `http://localhost:8000/demo.html`

**Step 3: Interact with the demo**

1. Click "Start Detection" to begin
2. Adjust animation speed with the slider
3. Toggle visual options to customize the view
4. Watch the algorithm log for real-time updates
5. View results after completion
6. Click "Reset" to run again

#### Demo Screenshots

The demo provides:
- Clean, modern UI with gradient headers
- Responsive design (works on mobile/tablet)
- Dark-themed canvas for better contrast
- Professional color scheme
- Smooth animations and transitions

## Algorithm Performance

- **Time Complexity**: O(n²) for n components, with early termination for non-intersecting pairs
- **Space Complexity**: O(n + m) where m is the total number of intersection segments
- **Numerical Stability**: IEEE 754 double precision with configurable epsilon tolerance

## Implementation Comparison

### Feature Matrix

| Feature | C | Node.js | Browser |
|---------|:---:|:-------:|:-------:|
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Memory Efficiency** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Development Speed** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Visualization** | ❌ | ❌ | ✅ |
| **Event System** | ❌ | ❌ | ✅ |
| **Animation Support** | ❌ | ❌ | ✅ |
| **Module System** | Manual | CommonJS/ESM | ES6 Modules |
| **Compilation Required** | ✅ | ❌ | ❌ |
| **Runtime Dependencies** | None | Node.js 14+ | Modern Browser |
| **Platform Support** | All | Cross-platform | Browser only |
| **Ideal Dataset Size** | 10,000+ | 100-1,000 | 10-100 |
| **Memory Usage** | Very Low | Low | Moderate |
| **Startup Time** | Instant | Fast | Fast |
| **Multi-threading** | Possible* | Possible* | Limited** |

\* Requires additional implementation
\** Web Workers available but not implemented

### Performance Benchmarks (Approximate)

Processing 100 components with 500 intersection checks:

| Implementation | Execution Time | Memory Usage |
|----------------|---------------:|-------------:|
| C (gcc -O3) | ~5ms | ~100KB |
| Node.js | ~15ms | ~500KB |
| Browser | ~25ms | ~800KB |

*Benchmarks are illustrative. Actual performance varies by hardware and dataset complexity.*

### Use Case Recommendations

| Scenario | Recommended Implementation | Reason |
|----------|---------------------------|---------|
| Production manufacturing system | **C** | Maximum performance and reliability |
| REST API backend | **Node.js** | Easy integration with modern web stack |
| Educational demo | **Browser** | Interactive visualization aids learning |
| Embedded system | **C** | Minimal footprint and no runtime |
| CAD web application | **Browser** | In-browser processing, no server needed |
| Batch processing pipeline | **C** | Handles large datasets efficiently |
| Prototype/MVP development | **Node.js** | Fast development iteration |
| Mobile web app | **Browser** | Works on any device with a browser |
| Real-time collaboration tool | **Browser** | Event system enables live updates |
| Data analysis workflow | **Node.js** | Easy integration with npm ecosystem |

---

## Quick Reference Guide

### Running Each Implementation

**C Implementation:**
```bash
# Compile
gcc -o 3d_detection_algo 3d_detection_algo.c -lm -O3

# Run
./3d_detection_algo
```

**Node.js Implementation:**
```bash
# Run directly
node 3d_detection_algo_node.js

# Or use in your code
const { IntersectionDetector, Component3D } = require('./3d_detection_algo_node.js');
```

**Browser Implementation:**
```bash
# Start a server (choose one)
python3 -m http.server 8000    # Python
npx serve                       # Node.js

# Open browser
# Navigate to http://localhost:8000/demo.html
```

### File Structure

```
3detection-algo/
├── 3d_detection_algo.c           # C implementation
├── 3d_detection_algo_node.js     # Node.js implementation
├── 3d_detection_algo_browser.js  # Browser implementation
├── demo.html                      # Interactive demo page
├── demo.css                       # Demo stylesheet
├── demo.js                        # Demo visualization logic
├── 3d_algo_img.JPG               # Original algorithm pseudocode
└── README.md                      # This file
```

### Common API Across Implementations

All three implementations share a similar API structure:

```javascript
// Create detector
const detector = new IntersectionDetector();

// Create and configure components
const component = new Component3D(id);
component.setNormal(x, y, z);

// Add to detector
detector.addComponent(component);

// Run detection
detector.detectIntersections();

// Get results
const results = detector.getResults();
```

---

## Future Enhancements

- ✅ ~~Real-time visualisation integration~~ (completed - see demo.html)
- GPU acceleration for large component sets (WebGL/WebGPU)
- Spatial indexing (octree, BSP) for O(n log n) performance
- Multi-threaded processing for independent component pairs (Web Workers)
- WebAssembly port for near-native browser performance
- 3D rendering with Three.js or Babylon.js
- Export functionality (STL, OBJ, STEP formats)
- Python bindings via ctypes or cffi
- Rust implementation for memory safety
- Don't do any of the above and find a real job instead 🥲

---

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## Questions or Issues?

If you encounter any problems or have questions about using any of the implementations, please open an issue on the repository.
