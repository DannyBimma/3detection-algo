# 3D Detection Algorithm - C TUI Demo

Interactive terminal-based visualization of the 3D Component Intersection Detection and Joint Classification Algorithm using ncurses.

## Features

- **Terminal-based UI**: Full-screen interactive interface with multiple panels
- **Real-time Visualization**: ASCII art representation of 3D components
- **Live Algorithm Log**: Step-by-step execution with colored output
- **Interactive Controls**: Keyboard controls for all features
- **Status Panel**: Real-time statistics and joint counts
- **Configurable Display**: Toggle grid, normals, and adjust animation speed

## Prerequisites

You need the ncurses development library installed:

### Ubuntu/Debian
```bash
sudo apt-get install libncurses5-dev libncurses-dev
```

### Fedora/RHEL/CentOS
```bash
sudo dnf install ncurses-devel
# or
sudo yum install ncurses-devel
```

### Arch Linux
```bash
sudo pacman -S ncurses
```

### macOS
```bash
brew install ncurses
```

Or use the Makefile helper:
```bash
make install-deps
```

## Building

```bash
# Compile the demo
make

# Or manually
gcc -Wall -Wextra -O2 -std=c99 -o demo demo.c -lncurses -lm
```

## Running

```bash
# Run directly
./demo

# Or using make
make run
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

- **Language**: C (C99 standard)
- **UI Library**: ncurses
- **Animation**: Configurable delay (100ms - 2000ms)
- **Components**: Displays up to 10 components
- **Log Buffer**: Stores up to 100 log entries

## Troubleshooting

### Terminal too small
Make sure your terminal is at least 80x24 characters. Resize or maximize your terminal window.

### Colors not working
Ensure your terminal supports color. Most modern terminals do, but if you're using a basic terminal emulator, colors may not display correctly.

### Compilation errors
Make sure you have the ncurses development headers installed. See the Prerequisites section above.

## Algorithm Overview

The algorithm detects intersections between 3D planar components and classifies joints into three types:

1. **Finger Joints** (Green): Both intersection segments lie on component edges
2. **Hole Joints** (Yellow): One segment is on an edge, the other is not
3. **Slot Joints** (Red): Neither segment lies on an edge

## Building for Release

```bash
# Optimized build
gcc -Wall -Wextra -O3 -march=native -std=c99 -o demo demo.c -lncurses -lm

# Static linking (for portability)
gcc -Wall -Wextra -O2 -std=c99 -o demo demo.c -lncurses -lm -static
```

## Cleaning

```bash
make clean
```

## License

GNU General Public License v3.0
