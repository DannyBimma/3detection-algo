# 3D Detection Algorithm - Zig TUI Demo

Interactive terminal-based visualization of the 3D Component Intersection Detection and Joint Classification Algorithm using Zig with ncurses bindings.

## Features

- **Pure Zig Implementation**: Written in Zig with C interop for ncurses
- **Terminal-based UI**: Full-screen interactive interface with multiple panels
- **Real-time Visualization**: ASCII art representation of 3D components
- **Live Algorithm Log**: Step-by-step execution with colored output
- **Interactive Controls**: Keyboard controls for all features
- **Status Panel**: Real-time statistics and joint counts
- **Memory Safe**: Leverages Zig's compile-time safety guarantees

## Prerequisites

### Zig Compiler

Install Zig 0.11.0 or later:

**Download from official site:**
```bash
# Visit https://ziglang.org/download/
```

**Using a package manager:**

Ubuntu/Debian:
```bash
sudo snap install zig --classic --beta
```

macOS:
```bash
brew install zig
```

Arch Linux:
```bash
sudo pacman -S zig
```

### ncurses Library

The ncurses development library must be installed:

**Ubuntu/Debian:**
```bash
sudo apt-get install libncurses5-dev libncurses-dev
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install ncurses-devel
# or
sudo yum install ncurses-devel
```

**Arch Linux:**
```bash
sudo pacman -S ncurses
```

**macOS:**
```bash
brew install ncurses
```

## Building

### Using Zig Build System (Recommended)

```bash
# Build the demo
zig build

# Build and run
zig build run

# Build with release optimizations
zig build -Doptimize=ReleaseFast

# Build with smaller binary size
zig build -Doptimize=ReleaseSmall
```

### Manual Build

```bash
# Build directly
zig build-exe demo.zig -lc -lncurses

# Build with optimizations
zig build-exe demo.zig -lc -lncurses -O ReleaseFast
```

## Running

```bash
# After building
./zig-out/bin/demo

# Or use zig build run
zig build run
```

## Controls

| Key | Action |
|-----|--------|
| `SPACE` | Start/Pause algorithm execution |
| `R` | Reset to initial state |
| `+/=` | Increase animation speed (decrease delay) |
| `-/_` | Decrease animation speed (increase delay) |
| `G` | Toggle grid display |
| `N` | Toggle normal vectors display |
| `Q` | Quit application |

## UI Layout

```
┌─────────────────────────────┬─────────────────────────────┐
│   3D VISUALIZATION          │   ALGORITHM LOG             │
│                             │                             │
│   [C1]  [C2]  [C3]         │   > Comparing C1 <-> C2     │
│    +--+  +--+  +--+        │   > Intersection found      │
│    |  |  |  |  |  |        │   > Classified as FINGER    │
│    +--+  +--+  +--+        │   > Comparing C1 <-> C3     │
│                             │   ...                       │
└─────────────────────────────┴─────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│   STATUS                                                   │
│   Components: 5  Status: RUNNING                          │
│   Finger: 2  Hole: 1  Slot: 3                            │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│   CONTROLS                                                 │
│   [SPACE] Start/Pause  [R] Reset  [Q] Quit               │
└────────────────────────────────────────────────────────────┘
```

## Color Coding

- **Cyan**: Titles and headers
- **Blue**: Borders and grid
- **White**: General information
- **Green**: Success messages and Finger joints
- **Yellow**: Warnings and Hole joints
- **Red**: Errors and Slot joints

## Technical Details

- **Language**: Zig (0.11.0+)
- **UI Library**: ncurses (via C interop)
- **Memory Management**: Zig's allocator system with GeneralPurposeAllocator
- **Animation**: Configurable delay (100ms - 2000ms)
- **Components**: Displays up to 10 components
- **Log Buffer**: Stores up to 100 log entries

## Zig-Specific Features

- **Compile-time Safety**: Zig's comptime features ensure memory safety
- **No Hidden Allocations**: All allocations are explicit and tracked
- **C Interop**: Direct integration with ncurses C library using `@cImport`
- **Error Handling**: Explicit error handling with Zig's error union types
- **Memory Efficiency**: Zero-cost abstractions with compile-time guarantees

## Algorithm Overview

The algorithm detects intersections between 3D planar components and classifies joints into three types:

1. **Finger Joints** (Green): Both intersection segments lie on component edges
2. **Hole Joints** (Yellow): One segment is on an edge, the other is not
3. **Slot Joints** (Red): Neither segment lies on an edge

## Troubleshooting

### Zig version mismatch
Make sure you're using Zig 0.11.0 or later. Check with:
```bash
zig version
```

### ncurses linking errors
Ensure ncurses development headers are installed:
```bash
# Ubuntu/Debian
sudo apt-get install libncurses5-dev

# macOS (if using Homebrew ncurses)
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH
export CPATH=/opt/homebrew/include:$CPATH
```

### Terminal too small
Make sure your terminal is at least 80x24 characters. Resize or maximize your terminal window.

### Build cache issues
Clear the Zig build cache:
```bash
rm -rf zig-cache zig-out
zig build
```

## Building for Different Platforms

### Cross-compilation

Zig makes cross-compilation easy:

```bash
# For Linux x86_64
zig build -Dtarget=x86_64-linux

# For macOS ARM64
zig build -Dtarget=aarch64-macos

# For Windows (note: ncurses not available on Windows without WSL)
# Use WSL or pdcurses alternative
```

### Static Linking

```bash
# Build with static linking
zig build -Doptimize=ReleaseSmall -Dtarget=native-linux-musl
```

## Development

### Testing
```bash
zig build test
```

### Debug Build
```bash
zig build -Doptimize=Debug
```

### Format Code
```bash
zig fmt demo.zig
```

## Cleaning

```bash
# Clean build artifacts
rm -rf zig-cache zig-out
```

## License

GNU General Public License v3.0
