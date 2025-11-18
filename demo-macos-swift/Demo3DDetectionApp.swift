// 3D Component Intersection Detection - macOS SwiftUI App
// Native macOS visualization with modern Swift UI

import SwiftUI

@main
struct Demo3DDetectionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// MARK: - Data Models

struct Vector3D: Equatable {
    var x: Double
    var y: Double
    var z: Double

    func dot(_ other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }

    func cross(_ other: Vector3D) -> Vector3D {
        return Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    func magnitude() -> Double {
        return sqrt(x * x + y * y + z * z)
    }

    func normalized() -> Vector3D {
        let mag = magnitude()
        return Vector3D(x: x / mag, y: y / mag, z: z / mag)
    }

    static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        return Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
}

struct Segment3D {
    var start: Vector3D
    var end: Vector3D
}

enum JointType: String, CaseIterable {
    case finger = "Finger"
    case hole = "Hole"
    case slot = "Slot"

    var color: Color {
        switch self {
        case .finger: return .green
        case .hole: return .orange
        case .slot: return .red
        }
    }
}

struct Joint: Identifiable {
    let id = UUID()
    var type: JointType
    var segment: Segment3D
}

class Component3D: ObservableObject, Identifiable {
    let id: Int
    @Published var vertices: [Vector3D]
    @Published var normal: Vector3D
    @Published var fingers: [Joint] = []
    @Published var holes: [Joint] = []
    @Published var slots: [Joint] = []

    init(id: Int, vertices: [Vector3D], normal: Vector3D) {
        self.id = id
        self.vertices = vertices
        self.normal = normal
    }

    func areCoplanar(with other: Component3D) -> Bool {
        guard !vertices.isEmpty && !other.vertices.isEmpty else { return false }
        let diff = other.vertices[0] - vertices[0]
        let dist = abs(diff.dot(normal))
        return dist < 1e-9
    }

    func areParallel(with other: Component3D) -> Bool {
        let dotVal = abs(normal.dot(other.normal))
        return abs(dotVal - 1.0) < 1e-9
    }

    func intersects(with other: Component3D) -> Bool {
        // Stub implementation for demo
        return (id + other.id) % 3 != 0
    }

    func reset() {
        fingers.removeAll()
        holes.removeAll()
        slots.removeAll()
    }

    var totalJoints: Int {
        return fingers.count + holes.count + slots.count
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
    let type: LogType

    enum LogType {
        case info, success, warning, error

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}

// MARK: - Algorithm State

class AlgorithmState: ObservableObject {
    @Published var components: [Component3D] = []
    @Published var logs: [LogEntry] = []
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentStep = 0
    @Published var totalSteps = 0
    @Published var animationSpeed: Double = 0.5 // seconds
    @Published var showGrid = true
    @Published var showNormals = true

    init() {
        initializeTestComponents()
    }

    func initializeTestComponents() {
        components = (1...5).map { i in
            let offset = Double(i - 1) * 2.0
            let vertices = [
                Vector3D(x: 0.0 + offset, y: 0.0, z: 0.0),
                Vector3D(x: 2.0 + offset, y: 0.0, z: 0.0),
                Vector3D(x: 2.0 + offset, y: 2.0, z: 0.0),
                Vector3D(x: 0.0 + offset, y: 2.0, z: 0.0)
            ]
            return Component3D(id: i, vertices: vertices, normal: Vector3D(x: 0, y: 0, z: 1))
        }
    }

    func addLog(_ message: String, type: LogEntry.LogType = .info) {
        let entry = LogEntry(message: message, timestamp: Date(), type: type)
        DispatchQueue.main.async {
            self.logs.append(entry)
            if self.logs.count > 100 {
                self.logs.removeFirst()
            }
        }
    }

    func reset() {
        for component in components {
            component.reset()
        }
        logs.removeAll()
        currentStep = 0
        isRunning = false
        isPaused = false
        addLog("Reset complete", type: .info)
    }

    func runAlgorithm() {
        guard !isRunning else { return }

        isRunning = true
        isPaused = false
        currentStep = 0
        totalSteps = (components.count * (components.count - 1)) / 2

        addLog("Algorithm started", type: .success)

        Task {
            var step = 0
            for i in 0..<components.count - 1 {
                for j in (i + 1)..<components.count {
                    let c1 = components[i]
                    let c2 = components[j]

                    await MainActor.run {
                        addLog("Comparing C\(c1.id) <-> C\(c2.id)", type: .info)
                        step += 1
                        currentStep = step
                    }

                    try? await Task.sleep(nanoseconds: UInt64(animationSpeed * 1_000_000_000))

                    // Check if paused
                    while isPaused && isRunning {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    }

                    if !isRunning { return }

                    // Check coplanar
                    if c1.areCoplanar(with: c2) && c1.areParallel(with: c2) {
                        await MainActor.run {
                            addLog("C\(c1.id) and C\(c2.id) are coplanar - skipping", type: .warning)
                        }
                        continue
                    }

                    // Check intersection
                    if c1.intersects(with: c2) {
                        await MainActor.run {
                            addLog("Intersection found: C\(c1.id) <-> C\(c2.id)", type: .success)
                        }

                        // Classify joint
                        let typeChoice = (c1.id + c2.id) % 3
                        let dummySegment = Segment3D(
                            start: Vector3D(x: 0, y: 0, z: 0),
                            end: Vector3D(x: 1, y: 1, z: 1)
                        )

                        await MainActor.run {
                            if typeChoice == 0 {
                                c1.fingers.append(Joint(type: .finger, segment: dummySegment))
                                c2.fingers.append(Joint(type: .finger, segment: dummySegment))
                                addLog("Classified as FINGER joint", type: .success)
                            } else if typeChoice == 1 {
                                c1.holes.append(Joint(type: .hole, segment: dummySegment))
                                c2.holes.append(Joint(type: .hole, segment: dummySegment))
                                addLog("Classified as HOLE joint", type: .success)
                            } else {
                                c1.slots.append(Joint(type: .slot, segment: dummySegment))
                                c2.slots.append(Joint(type: .slot, segment: dummySegment))
                                addLog("Classified as SLOT joint", type: .success)
                            }
                        }
                    }
                }
            }

            await MainActor.run {
                addLog("Algorithm completed!", type: .success)
                isRunning = false
            }
        }
    }

    func togglePause() {
        isPaused.toggle()
    }

    func stopAlgorithm() {
        isRunning = false
        isPaused = false
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var state = AlgorithmState()

    var body: some View {
        HSplitView {
            // Left side: Visualization
            VStack(spacing: 0) {
                VisualizationView(state: state)
                ProgressBarView(state: state)
            }
            .frame(minWidth: 400)

            // Right side: Log and Controls
            VStack(spacing: 0) {
                LogView(state: state)
                Divider()
                StatusView(state: state)
                Divider()
                ControlsView(state: state)
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

struct VisualizationView: View {
    @ObservedObject var state: AlgorithmState

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.15, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                Text("3D Visualization")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                Spacer()

                // Grid
                if state.showGrid {
                    GridPatternView()
                        .opacity(0.3)
                }

                // Components
                HStack(spacing: 20) {
                    ForEach(state.components) { component in
                        ComponentView(component: component, showNormals: state.showNormals)
                    }
                }
                .padding()

                Spacer()
            }
        }
    }
}

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30

            // Draw vertical lines
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }

            // Draw horizontal lines
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }
        }
    }
}

struct ComponentView: View {
    @ObservedObject var component: Component3D
    let showNormals: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Component ID
            Text("C\(component.id)")
                .font(.headline)
                .foregroundColor(.cyan)
                .fontWeight(.bold)

            // Normal vector
            if showNormals {
                Text("↑")
                    .font(.title)
                    .foregroundColor(.green)
            }

            // 3D Box representation
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)

                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cyan, lineWidth: 2)
                    .frame(width: 80, height: 80)

                // Inner square to give 3D effect
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    .frame(width: 60, height: 60)
                    .offset(x: -5, y: -5)
            }

            // Joint counts
            VStack(alignment: .leading, spacing: 4) {
                if component.fingers.count > 0 {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("F: \(component.fingers.count)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if component.holes.count > 0 {
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("H: \(component.holes.count)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                if component.slots.count > 0 {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("S: \(component.slots.count)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(height: 50, alignment: .top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

struct ProgressBarView: View {
    @ObservedObject var state: AlgorithmState

    var progress: Double {
        guard state.totalSteps > 0 else { return 0 }
        return Double(state.currentStep) / Double(state.totalSteps)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(state.currentStep) / \(state.totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.cyan)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct LogView: View {
    @ObservedObject var state: AlgorithmState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Algorithm Log")
                .font(.headline)
                .padding()

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(state.logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(log.type.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.message)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Text(log.timestamp, style: .time)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id(log.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: state.logs.count) { _ in
                    if let lastLog = state.logs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct StatusView: View {
    @ObservedObject var state: AlgorithmState

    var totalFingers: Int {
        state.components.reduce(0) { $0 + $1.fingers.count }
    }

    var totalHoles: Int {
        state.components.reduce(0) { $0 + $1.holes.count }
    }

    var totalSlots: Int {
        state.components.reduce(0) { $0 + $1.slots.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)

            HStack {
                Label("Components: \(state.components.count)", systemImage: "cube.box")
                Spacer()
                Label(state.isRunning ? (state.isPaused ? "PAUSED" : "RUNNING") : "STOPPED",
                      systemImage: state.isRunning ? "play.circle.fill" : "stop.circle")
                    .foregroundColor(state.isRunning ? .green : .secondary)
            }

            HStack(spacing: 20) {
                Label("\(totalFingers)", systemImage: "circle.fill")
                    .foregroundColor(.green)

                Label("\(totalHoles)", systemImage: "circle.fill")
                    .foregroundColor(.orange)

                Label("\(totalSlots)", systemImage: "circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ControlsView: View {
    @ObservedObject var state: AlgorithmState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.headline)

            // Start/Pause/Stop buttons
            HStack(spacing: 12) {
                Button(action: {
                    if state.isRunning {
                        state.togglePause()
                    } else {
                        state.runAlgorithm()
                    }
                }) {
                    Label(state.isRunning ? (state.isPaused ? "Resume" : "Pause") : "Start",
                          systemImage: state.isRunning ? (state.isPaused ? "play.fill" : "pause.fill") : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isRunning && !state.isPaused && state.currentStep == 0)

                Button(action: { state.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // Speed control
            VStack(alignment: .leading, spacing: 4) {
                Text("Animation Speed: \(String(format: "%.1f", state.animationSpeed))s")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(value: $state.animationSpeed, in: 0.1...2.0, step: 0.1)
            }

            // Display toggles
            HStack(spacing: 20) {
                Toggle("Show Grid", isOn: $state.showGrid)
                Toggle("Show Normals", isOn: $state.showNormals)
            }

            Divider()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("3D Component Intersection Detection")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("Joint Classification Algorithm v1.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
