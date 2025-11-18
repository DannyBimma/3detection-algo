// 3D Component Intersection Detection - Interactive TUI Demo
// Using Zig with ncurses C bindings

const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
    @cInclude("time.h");
    @cInclude("unistd.h");
});

const EPSILON = 1e-9;
const MAX_COMPONENTS = 10;
const MAX_JOINTS = 500;
const MAX_LOG_LINES = 100;

// Color pairs
const COLOR_TITLE = 1;
const COLOR_BORDER = 2;
const COLOR_INFO = 3;
const COLOR_SUCCESS = 4;
const COLOR_WARNING = 5;
const COLOR_ERROR = 6;
const COLOR_FINGER = 7;
const COLOR_HOLE = 8;
const COLOR_SLOT = 9;

const Vector3D = struct {
    x: f64,
    y: f64,
    z: f64,

    fn dot(self: Vector3D, other: Vector3D) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    fn cross(self: Vector3D, other: Vector3D) Vector3D {
        return Vector3D{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    fn magnitude(self: Vector3D) f64 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    fn normalize(self: Vector3D) Vector3D {
        const mag = self.magnitude();
        return Vector3D{ .x = self.x / mag, .y = self.y / mag, .z = self.z / mag };
    }

    fn subtract(self: Vector3D, other: Vector3D) Vector3D {
        return Vector3D{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }
};

const Segment3D = struct {
    start: Vector3D,
    end: Vector3D,
};

const JointType = enum {
    finger,
    hole,
    slot,
};

const Joint = struct {
    joint_type: JointType,
    segment: Segment3D,
};

const Component3D = struct {
    id: u32,
    vertices: std.ArrayList(Vector3D),
    normal: Vector3D,
    fingers: std.ArrayList(Joint),
    holes: std.ArrayList(Joint),
    slots: std.ArrayList(Joint),

    fn init(allocator: std.mem.Allocator, id: u32) !Component3D {
        return Component3D{
            .id = id,
            .vertices = std.ArrayList(Vector3D).init(allocator),
            .normal = Vector3D{ .x = 0, .y = 0, .z = 1 },
            .fingers = std.ArrayList(Joint).init(allocator),
            .holes = std.ArrayList(Joint).init(allocator),
            .slots = std.ArrayList(Joint).init(allocator),
        };
    }

    fn deinit(self: *Component3D) void {
        self.vertices.deinit();
        self.fingers.deinit();
        self.holes.deinit();
        self.slots.deinit();
    }

    fn areCoplanar(self: Component3D, other: Component3D) bool {
        if (self.vertices.items.len == 0 or other.vertices.items.len == 0) return false;
        const diff = other.vertices.items[0].subtract(self.vertices.items[0]);
        const dist = @abs(diff.dot(self.normal));
        return dist < EPSILON;
    }

    fn areParallel(self: Component3D, other: Component3D) bool {
        const dot_val = @abs(self.normal.dot(other.normal));
        return @abs(dot_val - 1.0) < EPSILON;
    }

    fn intersects(self: Component3D, other: Component3D) bool {
        // Stub implementation for demo
        return (self.id + other.id) % 3 != 0;
    }

    fn reset(self: *Component3D) void {
        self.fingers.clearRetainingCapacity();
        self.holes.clearRetainingCapacity();
        self.slots.clearRetainingCapacity();
    }
};

const LogEntry = struct {
    message: [256]u8,
    message_len: usize,
    color_pair: c_int,
    timestamp: c.time_t,

    fn init(message: []const u8, color_pair: c_int) LogEntry {
        var entry = LogEntry{
            .message = undefined,
            .message_len = 0,
            .color_pair = color_pair,
            .timestamp = c.time(null),
        };
        const len = @min(message.len, 255);
        @memcpy(entry.message[0..len], message[0..len]);
        entry.message[len] = 0;
        entry.message_len = len;
        return entry;
    }
};

const UIState = struct {
    canvas_win: ?*c.WINDOW,
    log_win: ?*c.WINDOW,
    status_win: ?*c.WINDOW,
    controls_win: ?*c.WINDOW,
    logs: std.ArrayList(LogEntry),
    is_running: bool,
    paused: bool,
    delay_ms: i32,
    show_grid: bool,
    show_normals: bool,
    current_step: u32,
    total_steps: u32,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !UIState {
        return UIState{
            .canvas_win = null,
            .log_win = null,
            .status_win = null,
            .controls_win = null,
            .logs = std.ArrayList(LogEntry).init(allocator),
            .is_running = false,
            .paused = false,
            .delay_ms = 500,
            .show_grid = true,
            .show_normals = true,
            .current_step = 0,
            .total_steps = 0,
            .allocator = allocator,
        };
    }

    fn deinit(self: *UIState) void {
        self.logs.deinit();
    }

    fn initWindows(self: *UIState) void {
        _ = c.initscr();
        _ = c.start_color();
        _ = c.cbreak();
        _ = c.noecho();
        _ = c.curs_set(0);
        _ = c.nodelay(c.stdscr, true);
        _ = c.keypad(c.stdscr, true);

        // Initialize color pairs
        _ = c.init_pair(COLOR_TITLE, c.COLOR_CYAN, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_BORDER, c.COLOR_BLUE, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_INFO, c.COLOR_WHITE, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_SUCCESS, c.COLOR_GREEN, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_WARNING, c.COLOR_YELLOW, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_ERROR, c.COLOR_RED, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_FINGER, c.COLOR_GREEN, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_HOLE, c.COLOR_YELLOW, c.COLOR_BLACK);
        _ = c.init_pair(COLOR_SLOT, c.COLOR_RED, c.COLOR_BLACK);

        var max_y: c_int = 0;
        var max_x: c_int = 0;
        c.getmaxyx(c.stdscr, &max_y, &max_x);

        self.canvas_win = c.newwin(max_y - 12, max_x / 2, 0, 0);
        self.log_win = c.newwin(max_y - 12, max_x / 2, 0, max_x / 2);
        self.status_win = c.newwin(6, max_x, max_y - 12, 0);
        self.controls_win = c.newwin(6, max_x, max_y - 6, 0);
    }

    fn cleanup(self: *UIState) void {
        if (self.canvas_win) |win| _ = c.delwin(win);
        if (self.log_win) |win| _ = c.delwin(win);
        if (self.status_win) |win| _ = c.delwin(win);
        if (self.controls_win) |win| _ = c.delwin(win);
        _ = c.endwin();
    }

    fn drawBorders(self: *UIState) void {
        // Canvas border
        _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.box(self.canvas_win, 0, 0);
        _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);
        _ = c.mvwprintw(self.canvas_win, 0, 2, " 3D VISUALIZATION ");
        _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);

        // Log border
        _ = c.wattron(self.log_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.box(self.log_win, 0, 0);
        _ = c.wattroff(self.log_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.wattron(self.log_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);
        _ = c.mvwprintw(self.log_win, 0, 2, " ALGORITHM LOG ");
        _ = c.wattroff(self.log_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);

        // Status border
        _ = c.wattron(self.status_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.box(self.status_win, 0, 0);
        _ = c.wattroff(self.status_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.wattron(self.status_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);
        _ = c.mvwprintw(self.status_win, 0, 2, " STATUS ");
        _ = c.wattroff(self.status_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);

        // Controls border
        _ = c.wattron(self.controls_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.box(self.controls_win, 0, 0);
        _ = c.wattroff(self.controls_win, c.COLOR_PAIR(COLOR_BORDER));
        _ = c.wattron(self.controls_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);
        _ = c.mvwprintw(self.controls_win, 0, 2, " CONTROLS ");
        _ = c.wattroff(self.controls_win, c.COLOR_PAIR(COLOR_TITLE) | c.A_BOLD);
    }

    fn addLog(self: *UIState, message: []const u8, color: c_int) !void {
        if (self.logs.items.len >= MAX_LOG_LINES) {
            _ = self.logs.orderedRemove(0);
        }
        try self.logs.append(LogEntry.init(message, color));
    }

    fn drawCanvas(self: *UIState, components: []Component3D) void {
        var max_y: c_int = 0;
        var max_x: c_int = 0;
        c.getmaxyx(self.canvas_win, &max_y, &max_x);

        // Clear content area
        for (1..@intCast(max_y - 1)) |y| {
            for (1..@intCast(max_x - 1)) |x| {
                _ = c.mvwaddch(self.canvas_win, @intCast(y), @intCast(x), ' ');
            }
        }

        // Draw grid if enabled
        if (self.show_grid) {
            _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_BORDER));
            var y: c_int = 3;
            while (y < max_y - 1) : (y += 2) {
                var x: c_int = 3;
                while (x < max_x - 1) : (x += 4) {
                    _ = c.mvwaddch(self.canvas_win, y, x, '.');
                }
            }
            _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_BORDER));
        }

        // Draw components
        const start_y: c_int = 5;
        const start_x: c_int = 5;
        const spacing: c_int = @divTrunc(max_x - 10, @as(c_int, @intCast(components.len)) + 1);

        for (components, 0..) |comp, i| {
            const x = start_x + @as(c_int, @intCast(i)) * spacing;
            const y = start_y + @as(c_int, @intCast(i % 3)) * 3;

            // Draw component
            _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_INFO) | c.A_BOLD);
            _ = c.mvwprintw(self.canvas_win, y, x, "[C%d]", comp.id);
            _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_INFO) | c.A_BOLD);

            // Draw simplified 3D box
            _ = c.mvwprintw(self.canvas_win, y + 1, x, " +--+");
            _ = c.mvwprintw(self.canvas_win, y + 2, x, " |  |");
            _ = c.mvwprintw(self.canvas_win, y + 3, x, " +--+");

            // Draw normal vector if enabled
            if (self.show_normals) {
                _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_SUCCESS));
                _ = c.mvwprintw(self.canvas_win, y - 1, x + 2, "^");
                _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_SUCCESS));
            }

            // Draw joint indicators
            var joint_y = y + 4;
            if (comp.fingers.items.len > 0) {
                _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_FINGER));
                _ = c.mvwprintw(self.canvas_win, joint_y, x, "F:%d", comp.fingers.items.len);
                _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_FINGER));
                joint_y += 1;
            }
            if (comp.holes.items.len > 0) {
                _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_HOLE));
                _ = c.mvwprintw(self.canvas_win, joint_y, x, "H:%d", comp.holes.items.len);
                _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_HOLE));
                joint_y += 1;
            }
            if (comp.slots.items.len > 0) {
                _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_SLOT));
                _ = c.mvwprintw(self.canvas_win, joint_y, x, "S:%d", comp.slots.items.len);
                _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_SLOT));
                joint_y += 1;
            }
        }

        // Draw progress bar
        if (self.is_running and self.current_step > 0) {
            const progress_y = max_y - 3;
            const progress_width = max_x - 10;
            const filled: c_int = @divTrunc(@as(c_int, @intCast(self.current_step)) * progress_width, @as(c_int, @intCast(self.total_steps)));

            _ = c.mvwprintw(self.canvas_win, progress_y, 5, "Progress: [");
            _ = c.wattron(self.canvas_win, c.COLOR_PAIR(COLOR_SUCCESS));
            for (0..@intCast(filled)) |_| {
                _ = c.waddch(self.canvas_win, '=');
            }
            _ = c.wattroff(self.canvas_win, c.COLOR_PAIR(COLOR_SUCCESS));
            for (@intCast(filled)..@intCast(progress_width)) |_| {
                _ = c.waddch(self.canvas_win, ' ');
            }
            _ = c.wprintw(self.canvas_win, "]");
        }

        _ = c.wrefresh(self.canvas_win);
    }

    fn drawLog(self: *UIState) void {
        var max_y: c_int = 0;
        var max_x: c_int = 0;
        c.getmaxyx(self.log_win, &max_y, &max_x);

        // Clear content area
        for (1..@intCast(max_y - 1)) |y| {
            for (1..@intCast(max_x - 1)) |x| {
                _ = c.mvwaddch(self.log_win, @intCast(y), @intCast(x), ' ');
            }
        }

        // Display recent logs
        const display_count: usize = @intCast(max_y - 2);
        const start_idx = if (self.logs.items.len > display_count) self.logs.items.len - display_count else 0;
        var y: c_int = 1;

        for (self.logs.items[start_idx..]) |entry| {
            if (y >= max_y - 1) break;
            _ = c.wattron(self.log_win, c.COLOR_PAIR(entry.color_pair));
            _ = c.mvwprintw(self.log_win, y, 2, "%.*s", @min(entry.message_len, 50), &entry.message);
            _ = c.wattroff(self.log_win, c.COLOR_PAIR(entry.color_pair));
            y += 1;
        }

        _ = c.wrefresh(self.log_win);
    }

    fn drawStatus(self: *UIState, components: []Component3D) void {
        var max_y: c_int = 0;
        var max_x: c_int = 0;
        c.getmaxyx(self.status_win, &max_y, &max_x);

        // Clear content area
        for (1..@intCast(max_y - 1)) |y| {
            for (1..@intCast(max_x - 1)) |x| {
                _ = c.mvwaddch(self.status_win, @intCast(y), @intCast(x), ' ');
            }
        }

        // Count total joints
        var total_fingers: usize = 0;
        var total_holes: usize = 0;
        var total_slots: usize = 0;
        for (components) |comp| {
            total_fingers += comp.fingers.items.len;
            total_holes += comp.holes.items.len;
            total_slots += comp.slots.items.len;
        }

        // Display status
        _ = c.mvwprintw(self.status_win, 1, 2, "Components: %d", components.len);
        const status_str = if (self.is_running) (if (self.paused) "PAUSED" else "RUNNING") else "STOPPED";
        _ = c.mvwprintw(self.status_win, 2, 2, "Status: %s", status_str.ptr);

        _ = c.wattron(self.status_win, c.COLOR_PAIR(COLOR_FINGER));
        _ = c.mvwprintw(self.status_win, 3, 2, "Finger Joints: %d", total_fingers);
        _ = c.wattroff(self.status_win, c.COLOR_PAIR(COLOR_FINGER));

        _ = c.wattron(self.status_win, c.COLOR_PAIR(COLOR_HOLE));
        _ = c.mvwprintw(self.status_win, 3, 25, "Hole Joints: %d", total_holes);
        _ = c.wattroff(self.status_win, c.COLOR_PAIR(COLOR_HOLE));

        _ = c.wattron(self.status_win, c.COLOR_PAIR(COLOR_SLOT));
        _ = c.mvwprintw(self.status_win, 3, 45, "Slot Joints: %d", total_slots);
        _ = c.wattroff(self.status_win, c.COLOR_PAIR(COLOR_SLOT));

        _ = c.mvwprintw(self.status_win, 4, 2, "Speed: %dms | Grid: %s | Normals: %s", self.delay_ms, if (self.show_grid) "ON" else "OFF", if (self.show_normals) "ON" else "OFF");

        _ = c.wrefresh(self.status_win);
    }

    fn drawControls(self: *UIState) void {
        var max_y: c_int = 0;
        var max_x: c_int = 0;
        c.getmaxyx(self.controls_win, &max_y, &max_x);

        // Clear content area
        for (1..@intCast(max_y - 1)) |y| {
            for (1..@intCast(max_x - 1)) |x| {
                _ = c.mvwaddch(self.controls_win, @intCast(y), @intCast(x), ' ');
            }
        }

        _ = c.wattron(self.controls_win, c.COLOR_PAIR(COLOR_INFO));
        _ = c.mvwprintw(self.controls_win, 1, 2, "[SPACE] Start/Pause  [R] Reset  [Q] Quit");
        _ = c.mvwprintw(self.controls_win, 2, 2, "[+/-] Speed  [G] Toggle Grid  [N] Toggle Normals");
        _ = c.mvwprintw(self.controls_win, 3, 2, "3D Component Intersection Detection & Joint Classification v1.0 (Zig)");
        _ = c.wattroff(self.controls_win, c.COLOR_PAIR(COLOR_INFO));

        _ = c.wrefresh(self.controls_win);
    }

    fn runAlgorithm(self: *UIState, components: []Component3D) !void {
        self.is_running = true;
        self.current_step = 0;
        self.total_steps = @divTrunc(@as(u32, @intCast(components.len)) * (@as(u32, @intCast(components.len)) - 1), 2);

        try self.addLog("Algorithm started", COLOR_SUCCESS);

        var step: u32 = 0;
        for (components, 0..) |*c1, i| {
            for (components[i + 1 ..], 0..) |*c2, j_offset| {
                const j = i + 1 + j_offset;

                var log_buf: [256]u8 = undefined;
                const log_msg = try std.fmt.bufPrint(&log_buf, "Comparing C{d} <-> C{d}", .{ c1.id, c2.id });
                try self.addLog(log_msg, COLOR_INFO);

                step += 1;
                self.current_step = step;
                self.drawCanvas(components);
                self.drawLog();
                self.drawStatus(components);
                _ = c.refresh();

                // Handle delay and input
                var elapsed: i32 = 0;
                while (elapsed < self.delay_ms) {
                    const ch = c.getch();
                    if (ch == ' ') {
                        self.paused = !self.paused;
                        self.drawStatus(components);
                    } else if (ch == 'q' or ch == 'Q') {
                        self.is_running = false;
                        return;
                    }

                    if (self.paused) {
                        _ = c.usleep(50000);
                        continue;
                    }

                    _ = c.usleep(50000);
                    elapsed += 50;
                }

                // Check coplanar
                if (c1.areCoplanar(c2.*)) {
                    if (c1.areParallel(c2.*)) {
                        const warn_msg = try std.fmt.bufPrint(&log_buf, "C{d} and C{d} are coplanar - skipping", .{ c1.id, c2.id });
                        try self.addLog(warn_msg, COLOR_WARNING);
                        self.drawLog();
                        continue;
                    }
                }

                // Check intersection
                if (c1.intersects(c2.*)) {
                    const success_msg = try std.fmt.bufPrint(&log_buf, "Intersection found: C{d} <-> C{d}", .{ c1.id, c2.id });
                    try self.addLog(success_msg, COLOR_SUCCESS);

                    // Classify joint (stub logic)
                    const type_choice = (c1.id + c2.id) % 3;
                    const dummy_segment = Segment3D{ .start = Vector3D{ .x = 0, .y = 0, .z = 0 }, .end = Vector3D{ .x = 1, .y = 1, .z = 1 } };

                    if (type_choice == 0) {
                        try c1.fingers.append(Joint{ .joint_type = .finger, .segment = dummy_segment });
                        try components[j].fingers.append(Joint{ .joint_type = .finger, .segment = dummy_segment });
                        try self.addLog("Classified as FINGER joint", COLOR_FINGER);
                    } else if (type_choice == 1) {
                        try c1.holes.append(Joint{ .joint_type = .hole, .segment = dummy_segment });
                        try components[j].holes.append(Joint{ .joint_type = .hole, .segment = dummy_segment });
                        try self.addLog("Classified as HOLE joint", COLOR_HOLE);
                    } else {
                        try c1.slots.append(Joint{ .joint_type = .slot, .segment = dummy_segment });
                        try components[j].slots.append(Joint{ .joint_type = .slot, .segment = dummy_segment });
                        try self.addLog("Classified as SLOT joint", COLOR_SLOT);
                    }

                    self.drawCanvas(components);
                    self.drawLog();
                    self.drawStatus(components);
                }
            }
        }

        try self.addLog("Algorithm completed!", COLOR_SUCCESS);
        self.drawLog();
        self.is_running = false;
    }
};

fn initTestComponents(allocator: std.mem.Allocator) ![]Component3D {
    var components = try allocator.alloc(Component3D, 5);

    for (components, 0..) |*comp, i| {
        comp.* = try Component3D.init(allocator, @intCast(i + 1));

        const offset: f64 = @as(f64, @floatFromInt(i)) * 2.0;
        try comp.vertices.append(Vector3D{ .x = 0.0 + offset, .y = 0.0, .z = 0.0 });
        try comp.vertices.append(Vector3D{ .x = 2.0 + offset, .y = 0.0, .z = 0.0 });
        try comp.vertices.append(Vector3D{ .x = 2.0 + offset, .y = 2.0, .z = 0.0 });
        try comp.vertices.append(Vector3D{ .x = 0.0 + offset, .y = 2.0, .z = 0.0 });
    }

    return components;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ui = try UIState.init(allocator);
    defer ui.deinit();

    ui.initWindows();
    defer ui.cleanup();

    var components = try initTestComponents(allocator);
    defer {
        for (components) |*comp| {
            comp.deinit();
        }
        allocator.free(components);
    }

    ui.drawBorders();
    ui.drawControls();
    ui.drawCanvas(components);
    ui.drawLog();
    ui.drawStatus(components);
    _ = c.refresh();

    try ui.addLog("Welcome to 3D Detection Algorithm TUI Demo (Zig)", COLOR_INFO);
    try ui.addLog("Press SPACE to start the algorithm", COLOR_INFO);
    ui.drawLog();

    // Main loop
    var running = true;
    while (running) {
        const ch = c.getch();

        switch (ch) {
            ' ' => {
                if (!ui.is_running) {
                    try ui.runAlgorithm(components);
                }
            },
            'r', 'R' => {
                for (components) |*comp| {
                    comp.reset();
                }
                ui.logs.clearRetainingCapacity();
                ui.current_step = 0;
                try ui.addLog("Reset complete", COLOR_INFO);
                ui.drawCanvas(components);
                ui.drawLog();
                ui.drawStatus(components);
            },
            '+', '=' => {
                if (ui.delay_ms > 100) {
                    ui.delay_ms -= 100;
                    ui.drawStatus(components);
                }
            },
            '-', '_' => {
                if (ui.delay_ms < 2000) {
                    ui.delay_ms += 100;
                    ui.drawStatus(components);
                }
            },
            'g', 'G' => {
                ui.show_grid = !ui.show_grid;
                ui.drawCanvas(components);
                ui.drawStatus(components);
            },
            'n', 'N' => {
                ui.show_normals = !ui.show_normals;
                ui.drawCanvas(components);
                ui.drawStatus(components);
            },
            'q', 'Q' => {
                running = false;
            },
            else => {},
        }

        _ = c.usleep(50000); // 50ms sleep to reduce CPU usage
    }

    std.debug.print("Thank you for using 3D Detection Algorithm TUI Demo!\n", .{});
}
