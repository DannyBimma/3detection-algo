# 3D Detection Algorithm - macOS Native App

Native macOS visualization app for the 3D Component Intersection Detection and Joint Classification Algorithm using SwiftUI.

## Features

- **Native macOS UI**: Built with SwiftUI for modern, responsive interface
- **Real-time 3D Visualization**: Graphical representation of components with animations
- **Live Algorithm Log**: Scrollable log with timestamps and color coding
- **Interactive Controls**: Play/Pause, Reset, speed control, and display toggles
- **Status Dashboard**: Real-time statistics and joint counts
- **Dark Mode Support**: Automatically adapts to system appearance
- **Smooth Animations**: Native macOS animations and transitions

## Requirements

- **macOS 12.0 (Monterey)** or later
- **Xcode 13.0+** or Swift command-line tools
- **Swift 5.5+** (for async/await support)

## Building and Running

### Option 1: Using Xcode (Recommended)

1. **Create a new Xcode project:**
   ```bash
   # Open Xcode and create new macOS App
   # Choose SwiftUI for Interface
   # Replace ContentView.swift with Demo3DDetectionApp.swift
   ```

2. **Or create a SwiftUI App from scratch:**
   - Open Xcode
   - File → New → Project
   - Choose "macOS" → "App"
   - Interface: SwiftUI
   - Life Cycle: SwiftUI App
   - Replace the default ContentView.swift with Demo3DDetectionApp.swift

3. **Run the app:**
   - Click the Run button (⌘R)
   - Or Product → Run

### Option 2: Using swift run

```bash
# Create a Swift package
mkdir -p Sources/Demo3DDetection
cp Demo3DDetectionApp.swift Sources/Demo3DDetection/

# Create Package.swift
cat > Package.swift << 'EOF'
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Demo3DDetection",
    platforms: [.macOS(.v12)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Demo3DDetection",
            dependencies: [])
    ]
)
EOF

# Build and run
swift run
```

### Option 3: Using swiftc (Command Line)

```bash
# Compile directly
swiftc -o Demo3DDetection \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    Demo3DDetectionApp.swift

# Run
./Demo3DDetection
```

### Option 4: Using the build script

```bash
./build.sh
./Demo3DDetection
```

## Creating an App Bundle (Optional)

To create a proper macOS app bundle:

1. **Create the bundle structure:**
```bash
mkdir -p Demo3DDetection.app/Contents/MacOS
mkdir -p Demo3DDetection.app/Contents/Resources

# Compile the executable
swiftc -o Demo3DDetection.app/Contents/MacOS/Demo3DDetection \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    Demo3DDetectionApp.swift
```

2. **Create Info.plist:**
```xml
cat > Demo3DDetection.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Demo3DDetection</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.demo3ddetection</string>
    <key>CFBundleName</key>
    <string>3D Detection Demo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
```

3. **Run the app bundle:**
```bash
open Demo3DDetection.app
```

## Features Overview

### Visualization Panel
- **3D Component Display**: Visual representation of each component with ID labels
- **Normal Vectors**: Toggle-able display of component normal vectors
- **Grid Background**: Optional grid for spatial reference
- **Joint Indicators**: Color-coded counters for each joint type
- **Progress Bar**: Real-time algorithm execution progress

### Log Panel
- **Auto-scrolling Log**: Automatically scrolls to latest entry
- **Timestamps**: Each log entry includes precise timestamp
- **Color Coding**: Different colors for info, success, warning, and error messages
- **Searchable**: Full log history (up to 100 entries)

### Status Panel
- **Component Count**: Total number of components
- **Execution Status**: Running, Paused, or Stopped
- **Joint Statistics**: Real-time counts for each joint type:
  - 🟢 Finger Joints (Green)
  - 🟠 Hole Joints (Orange)
  - 🔴 Slot Joints (Red)

### Controls Panel
- **Start/Pause Button**: Begin or pause algorithm execution
- **Reset Button**: Clear all joints and logs, return to initial state
- **Speed Slider**: Adjust animation speed (0.1s - 2.0s per step)
- **Display Toggles**: Show/hide grid and normal vectors

## User Interface

```
┌─────────────────────────────────────────────────────────────────────┐
│                        3D Visualization                             │
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐           │
│  │  C1   │  │  C2   │  │  C3   │  │  C4   │  │  C5   │           │
│  │   ↑   │  │   ↑   │  │   ↑   │  │   ↑   │  │   ↑   │           │
│  │ ┌───┐ │  │ ┌───┐ │  │ ┌───┐ │  │ ┌───┐ │  │ ┌───┐ │           │
│  │ │   │ │  │ │   │ │  │ │   │ │  │ │   │ │  │ │   │ │           │
│  │ └───┘ │  │ └───┘ │  │ └───┘ │  │ └───┘ │  │ └───┘ │           │
│  │ F: 2  │  │ H: 1  │  │ S: 1  │  │ F: 1  │  │       │           │
│  └───────┘  └───────┘  └───────┘  └───────┘  └───────┘           │
│                                                                     │
│  Progress: ████████████████░░░░░░░░░░░░░  10/15                  │
├─────────────────────────────────────────────────────────────────────┤
│  Algorithm Log                          │  Status                   │
│  🔵 Algorithm started (12:34:56)       │  Components: 5            │
│  🔵 Comparing C1 <-> C2 (12:34:57)     │  Status: RUNNING          │
│  🟢 Intersection found (12:34:57)      │  🟢 2  🟠 1  🔴 3         │
│  🟢 Classified as FINGER (12:34:57)    │                           │
│  ...                                    │  Controls                 │
│                                         │  [Pause] [Reset]          │
│                                         │  Speed: ═══●═══ 0.5s     │
│                                         │  ☑ Grid  ☑ Normals       │
└─────────────────────────────────────────────────────────────────────┘
```

## Keyboard Shortcuts

- `⌘R` - Start/Resume algorithm
- `⌘P` - Pause algorithm
- `⌘⇧R` - Reset
- `⌘Q` - Quit application
- `⌘+` - Increase speed
- `⌘-` - Decrease speed

## Algorithm Overview

The algorithm detects intersections between 3D planar components and classifies joints into three types:

1. **Finger Joints** (🟢 Green): Both intersection segments lie on component edges
2. **Hole Joints** (🟠 Orange): One segment is on an edge, the other is not
3. **Slot Joints** (🔴 Red): Neither segment lies on an edge

## SwiftUI Architecture

### Data Flow
- **@StateObject**: Main algorithm state management
- **@ObservedObject**: Component-level state observation
- **@Published**: Automatic UI updates on data changes
- **async/await**: Modern Swift concurrency for algorithm execution

### Views Structure
```
ContentView
├── VisualizationView
│   ├── GridPatternView
│   └── ComponentView (foreach)
├── ProgressBarView
├── LogView
├── StatusView
└── ControlsView
```

## Troubleshooting

### SwiftUI Preview not working
SwiftUI previews require Xcode. If using command-line tools, run the compiled app directly.

### App crashes on launch
Ensure you're running macOS 12.0 or later. Check system requirements.

### Build errors
Make sure you have the latest Xcode command-line tools:
```bash
xcode-select --install
```

### Performance issues
Try reducing the number of components or increasing the animation speed.

### Cannot create app bundle
Ensure you have proper file permissions:
```bash
chmod +x build.sh
```

## Distribution

To distribute your app:

1. **Sign the app:**
   ```bash
   codesign --force --deep --sign - Demo3DDetection.app
   ```

2. **Create a DMG:**
   ```bash
   hdiutil create -volname "3D Detection Demo" -srcfolder Demo3DDetection.app -ov -format UDZO Demo3DDetection.dmg
   ```

3. **Notarize for distribution** (requires Apple Developer account)

## Development

### Adding new features
1. Extend the `AlgorithmState` class for new state
2. Create new SwiftUI views in the file
3. Update the `ContentView` to include new views

### Debugging
Enable debug mode in Xcode:
- Product → Scheme → Edit Scheme
- Run → Arguments → Environment Variables
- Add `OS_ACTIVITY_MODE` = `disable` to reduce noise

## System Requirements

- macOS 12.0 (Monterey) or later
- Swift 5.5 or later
- ~100 MB disk space
- 4 GB RAM recommended

## License

GNU General Public License v3.0
