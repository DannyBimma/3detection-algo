/*
 * 3D Component Intersection Detection - Interactive TUI Demo
 * Using ncurses for terminal-based visualization
 */

#include <curses.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define EPSILON 1e-9
#define MAX_COMPONENTS 10
#define MAX_SEGMENTS 100
#define MAX_JOINTS 500
#define MAX_LOG_LINES 100

/* 3D Vector */
typedef struct {
  double x, y, z;
} Vector3D;

/* 3D Transformation Matrix (4x4 homogeneous) */
typedef struct {
  double m[4][4];
} Matrix4x4;

/* Line segment in 3D space */
typedef struct {
  Vector3D start;
  Vector3D end;
} Segment3D;

/* Dynamic array for segments */
typedef struct {
  Segment3D *data;
  int count;
  int capacity;
} SegmentArray;

/* Types of joint */
typedef enum { FINGER_JOINT, HOLE_JOINT, SLOT_JOINT } JointType;

/* Joints */
typedef struct {
  JointType type;
  Segment3D segment;
} Joint;

/* Dynamic array for joints */
typedef struct {
  Joint *data;
  int count;
  int capacity;
} JointArray;

/* 3D Component */
typedef struct {
  int id;
  Vector3D *vertices;
  int vertex_count;
  Matrix4x4 transform_3d;
  Matrix4x4 inverse_transform;
  Vector3D normal;
  JointArray fingers;
  JointArray holes;
  JointArray slots;
} Component3D;

/* Component collection */
typedef struct {
  Component3D *components;
  int count;
  int capacity;
} ComponentArray;

/* Log entry */
typedef struct {
  char message[256];
  int color_pair;
  time_t timestamp;
} LogEntry;

/* UI State */
typedef struct {
  WINDOW *main_win;
  WINDOW *canvas_win;
  WINDOW *log_win;
  WINDOW *status_win;
  WINDOW *controls_win;
  LogEntry logs[MAX_LOG_LINES];
  int log_count;
  int is_running;
  int paused;
  int delay_ms;
  int show_grid;
  int show_normals;
  int current_step;
  int total_steps;
} UIState;

/* Color pairs */
#define COLOR_TITLE 1
#define COLOR_BORDER 2
#define COLOR_INFO 3
#define COLOR_SUCCESS 4
#define COLOR_WARNING 5
#define COLOR_ERROR 6
#define COLOR_FINGER 7
#define COLOR_HOLE 8
#define COLOR_SLOT 9

/* Function prototypes */
static void init_ui(UIState *ui);
static void cleanup_ui(UIState *ui);
static void draw_borders(UIState *ui);
static void draw_canvas(UIState *ui, ComponentArray *components);
static void draw_log(UIState *ui);
static void draw_status(UIState *ui, ComponentArray *components);
static void draw_controls(UIState *ui);
static void add_log(UIState *ui, const char *message, int color);
static void init_test_components(ComponentArray *components);

/* Vector operations */
static inline double dot_product(const Vector3D *a, const Vector3D *b) {
  return a->x * b->x + a->y * b->y + a->z * b->z;
}

static inline Vector3D cross_product(const Vector3D *a, const Vector3D *b) {
  Vector3D result;
  result.x = a->y * b->z - a->z * b->y;
  result.y = a->z * b->x - a->x * b->z;
  result.z = a->x * b->y - a->y * b->x;
  return result;
}

static inline double vector_magnitude(const Vector3D *v) {
  return sqrt(v->x * v->x + v->y * v->y + v->z * v->z);
}

static inline Vector3D normalise_vector(const Vector3D *v) {
  double mag = vector_magnitude(v);
  Vector3D result = {v->x / mag, v->y / mag, v->z / mag};
  return result;
}

static inline Vector3D subtract_vectors(const Vector3D *a, const Vector3D *b) {
  Vector3D result = {a->x - b->x, a->y - b->y, a->z - b->z};
  return result;
}

/* Check if components are coplanar */
static int are_coplanar(const Component3D *c1, const Component3D *c2) {
  if (c1->vertex_count == 0 || c2->vertex_count == 0)
    return 0;
  Vector3D diff = subtract_vectors(&c2->vertices[0], &c1->vertices[0]);
  double dist = fabs(dot_product(&diff, &c1->normal));
  return dist < EPSILON;
}

/* Check if components are parallel */
static int are_parallel(const Component3D *c1, const Component3D *c2) {
  double dot = fabs(dot_product(&c1->normal, &c2->normal));
  return fabs(dot - 1.0) < EPSILON;
}

/* Stub: Check if components intersect */
static int components_intersect(const Component3D *c1, const Component3D *c2) {
  /* Simplified stub - returns true for demo purposes */
  return (c1->id + c2->id) % 3 != 0;
}

/* Stub: Find intersection segments */
static SegmentArray *find_line_component_intersections(const Segment3D *line,
                                                       const Component3D *comp) {
  SegmentArray *arr = malloc(sizeof(SegmentArray));
  arr->capacity = 10;
  arr->count = 0;
  arr->data = malloc(sizeof(Segment3D) * arr->capacity);

  /* Stub implementation - create a demo segment */
  if ((comp->id % 2) == 0) {
    arr->count = 1;
    arr->data[0] = *line;
  }

  return arr;
}

/* Stub: Check if segment is on edge */
static int is_segment_on_edge(const Segment3D *segment,
                              const Component3D *comp) {
  /* Simplified stub for demo */
  return (comp->id % 3) == 0;
}

/* Initialize test components */
static void init_test_components(ComponentArray *components) {
  components->capacity = MAX_COMPONENTS;
  components->count = 5;
  components->components = malloc(sizeof(Component3D) * components->capacity);

  for (int i = 0; i < components->count; i++) {
    Component3D *c = &components->components[i];
    c->id = i + 1;
    c->vertex_count = 4;
    c->vertices = malloc(sizeof(Vector3D) * 4);

    /* Create rectangular components at different positions */
    double offset = i * 2.0;
    c->vertices[0] = (Vector3D){0.0 + offset, 0.0, 0.0};
    c->vertices[1] = (Vector3D){2.0 + offset, 0.0, 0.0};
    c->vertices[2] = (Vector3D){2.0 + offset, 2.0, 0.0};
    c->vertices[3] = (Vector3D){0.0 + offset, 2.0, 0.0};

    c->normal = (Vector3D){0.0, 0.0, 1.0};

    /* Initialize joint arrays */
    c->fingers.capacity = MAX_JOINTS;
    c->fingers.count = 0;
    c->fingers.data = malloc(sizeof(Joint) * MAX_JOINTS);

    c->holes.capacity = MAX_JOINTS;
    c->holes.count = 0;
    c->holes.data = malloc(sizeof(Joint) * MAX_JOINTS);

    c->slots.capacity = MAX_JOINTS;
    c->slots.count = 0;
    c->slots.data = malloc(sizeof(Joint) * MAX_JOINTS);
  }
}

/* Initialize UI */
static void init_ui(UIState *ui) {
  initscr();
  start_color();
  cbreak();
  noecho();
  curs_set(0);
  nodelay(stdscr, TRUE);
  keypad(stdscr, TRUE);

  /* Initialize color pairs */
  init_pair(COLOR_TITLE, COLOR_CYAN, COLOR_BLACK);
  init_pair(COLOR_BORDER, COLOR_BLUE, COLOR_BLACK);
  init_pair(COLOR_INFO, COLOR_WHITE, COLOR_BLACK);
  init_pair(COLOR_SUCCESS, COLOR_GREEN, COLOR_BLACK);
  init_pair(COLOR_WARNING, COLOR_YELLOW, COLOR_BLACK);
  init_pair(COLOR_ERROR, COLOR_RED, COLOR_BLACK);
  init_pair(COLOR_FINGER, COLOR_GREEN, COLOR_BLACK);
  init_pair(COLOR_HOLE, COLOR_YELLOW, COLOR_BLACK);
  init_pair(COLOR_SLOT, COLOR_RED, COLOR_BLACK);

  /* Create windows */
  int max_y, max_x;
  getmaxyx(stdscr, max_y, max_x);

  ui->canvas_win = newwin(max_y - 12, max_x / 2, 0, 0);
  ui->log_win = newwin(max_y - 12, max_x / 2, 0, max_x / 2);
  ui->status_win = newwin(6, max_x, max_y - 12, 0);
  ui->controls_win = newwin(6, max_x, max_y - 6, 0);

  ui->log_count = 0;
  ui->is_running = 0;
  ui->paused = 0;
  ui->delay_ms = 500;
  ui->show_grid = 1;
  ui->show_normals = 1;
  ui->current_step = 0;
  ui->total_steps = 0;

  draw_borders(ui);
  refresh();
}

/* Cleanup UI */
static void cleanup_ui(UIState *ui) {
  delwin(ui->canvas_win);
  delwin(ui->log_win);
  delwin(ui->status_win);
  delwin(ui->controls_win);
  endwin();
}

/* Draw borders and titles */
static void draw_borders(UIState *ui) {
  /* Canvas border */
  wattron(ui->canvas_win, COLOR_PAIR(COLOR_BORDER));
  box(ui->canvas_win, 0, 0);
  wattroff(ui->canvas_win, COLOR_PAIR(COLOR_BORDER));

  wattron(ui->canvas_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);
  mvwprintw(ui->canvas_win, 0, 2, " 3D VISUALIZATION ");
  wattroff(ui->canvas_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);

  /* Log border */
  wattron(ui->log_win, COLOR_PAIR(COLOR_BORDER));
  box(ui->log_win, 0, 0);
  wattroff(ui->log_win, COLOR_PAIR(COLOR_BORDER));

  wattron(ui->log_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);
  mvwprintw(ui->log_win, 0, 2, " ALGORITHM LOG ");
  wattroff(ui->log_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);

  /* Status border */
  wattron(ui->status_win, COLOR_PAIR(COLOR_BORDER));
  box(ui->status_win, 0, 0);
  wattroff(ui->status_win, COLOR_PAIR(COLOR_BORDER));

  wattron(ui->status_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);
  mvwprintw(ui->status_win, 0, 2, " STATUS ");
  wattroff(ui->status_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);

  /* Controls border */
  wattron(ui->controls_win, COLOR_PAIR(COLOR_BORDER));
  box(ui->controls_win, 0, 0);
  wattroff(ui->controls_win, COLOR_PAIR(COLOR_BORDER));

  wattron(ui->controls_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);
  mvwprintw(ui->controls_win, 0, 2, " CONTROLS ");
  wattroff(ui->controls_win, COLOR_PAIR(COLOR_TITLE) | A_BOLD);
}

/* Draw canvas with components */
static void draw_canvas(UIState *ui, ComponentArray *components) {
  int max_y, max_x;
  getmaxyx(ui->canvas_win, max_y, max_x);

  /* Clear content area */
  for (int y = 1; y < max_y - 1; y++) {
    for (int x = 1; x < max_x - 1; x++) {
      mvwaddch(ui->canvas_win, y, x, ' ');
    }
  }

  /* Draw grid if enabled */
  if (ui->show_grid) {
    wattron(ui->canvas_win, COLOR_PAIR(COLOR_BORDER));
    for (int y = 3; y < max_y - 1; y += 2) {
      for (int x = 3; x < max_x - 1; x += 4) {
        mvwaddch(ui->canvas_win, y, x, '.');
      }
    }
    wattroff(ui->canvas_win, COLOR_PAIR(COLOR_BORDER));
  }

  /* Draw components */
  int start_y = 5;
  int start_x = 5;
  int spacing = (max_x - 10) / (components->count + 1);

  for (int i = 0; i < components->count; i++) {
    Component3D *c = &components->components[i];
    int x = start_x + i * spacing;
    int y = start_y + (i % 3) * 3;

    /* Draw component representation */
    wattron(ui->canvas_win, COLOR_PAIR(COLOR_INFO) | A_BOLD);
    mvwprintw(ui->canvas_win, y, x, "[C%d]", c->id);
    wattroff(ui->canvas_win, COLOR_PAIR(COLOR_INFO) | A_BOLD);

    /* Draw simplified 3D box */
    mvwprintw(ui->canvas_win, y + 1, x, " +--+");
    mvwprintw(ui->canvas_win, y + 2, x, " |  |");
    mvwprintw(ui->canvas_win, y + 3, x, " +--+");

    /* Draw normal vector if enabled */
    if (ui->show_normals) {
      wattron(ui->canvas_win, COLOR_PAIR(COLOR_SUCCESS));
      mvwprintw(ui->canvas_win, y - 1, x + 2, "^");
      wattroff(ui->canvas_win, COLOR_PAIR(COLOR_SUCCESS));
    }

    /* Draw joint indicators */
    int joint_y = y + 4;
    if (c->fingers.count > 0) {
      wattron(ui->canvas_win, COLOR_PAIR(COLOR_FINGER));
      mvwprintw(ui->canvas_win, joint_y++, x, "F:%d", c->fingers.count);
      wattroff(ui->canvas_win, COLOR_PAIR(COLOR_FINGER));
    }
    if (c->holes.count > 0) {
      wattron(ui->canvas_win, COLOR_PAIR(COLOR_HOLE));
      mvwprintw(ui->canvas_win, joint_y++, x, "H:%d", c->holes.count);
      wattroff(ui->canvas_win, COLOR_PAIR(COLOR_HOLE));
    }
    if (c->slots.count > 0) {
      wattron(ui->canvas_win, COLOR_PAIR(COLOR_SLOT));
      mvwprintw(ui->canvas_win, joint_y++, x, "S:%d", c->slots.count);
      wattroff(ui->canvas_win, COLOR_PAIR(COLOR_SLOT));
    }
  }

  /* Draw algorithm progress */
  if (ui->is_running && ui->current_step > 0) {
    int progress_y = max_y - 3;
    int progress_width = max_x - 10;
    int filled = (ui->current_step * progress_width) / ui->total_steps;

    mvwprintw(ui->canvas_win, progress_y, 5, "Progress: [");
    wattron(ui->canvas_win, COLOR_PAIR(COLOR_SUCCESS));
    for (int i = 0; i < filled; i++) {
      waddch(ui->canvas_win, '=');
    }
    wattroff(ui->canvas_win, COLOR_PAIR(COLOR_SUCCESS));
    for (int i = filled; i < progress_width; i++) {
      waddch(ui->canvas_win, ' ');
    }
    wprintw(ui->canvas_win, "]");
  }

  wrefresh(ui->canvas_win);
}

/* Add log entry */
static void add_log(UIState *ui, const char *message, int color) {
  if (ui->log_count >= MAX_LOG_LINES) {
    /* Shift logs up */
    memmove(&ui->logs[0], &ui->logs[1],
            sizeof(LogEntry) * (MAX_LOG_LINES - 1));
    ui->log_count = MAX_LOG_LINES - 1;
  }

  LogEntry *entry = &ui->logs[ui->log_count++];
  strncpy(entry->message, message, sizeof(entry->message) - 1);
  entry->message[sizeof(entry->message) - 1] = '\0';
  entry->color_pair = color;
  entry->timestamp = time(NULL);
}

/* Draw log window */
static void draw_log(UIState *ui) {
  int max_y, max_x;
  getmaxyx(ui->log_win, max_y, max_x);

  /* Clear content area */
  for (int y = 1; y < max_y - 1; y++) {
    for (int x = 1; x < max_x - 1; x++) {
      mvwaddch(ui->log_win, y, x, ' ');
    }
  }

  /* Display recent logs */
  int start_idx = ui->log_count > (max_y - 2) ? ui->log_count - (max_y - 2) : 0;
  int y = 1;

  for (int i = start_idx; i < ui->log_count && y < max_y - 1; i++, y++) {
    LogEntry *entry = &ui->logs[i];
    wattron(ui->log_win, COLOR_PAIR(entry->color_pair));
    mvwprintw(ui->log_win, y, 2, "%.50s", entry->message);
    wattroff(ui->log_win, COLOR_PAIR(entry->color_pair));
  }

  wrefresh(ui->log_win);
}

/* Draw status window */
static void draw_status(UIState *ui, ComponentArray *components) {
  int max_y, max_x;
  getmaxyx(ui->status_win, max_y, max_x);

  /* Clear content area */
  for (int y = 1; y < max_y - 1; y++) {
    for (int x = 1; x < max_x - 1; x++) {
      mvwaddch(ui->status_win, y, x, ' ');
    }
  }

  /* Count total joints */
  int total_fingers = 0, total_holes = 0, total_slots = 0;
  for (int i = 0; i < components->count; i++) {
    total_fingers += components->components[i].fingers.count;
    total_holes += components->components[i].holes.count;
    total_slots += components->components[i].slots.count;
  }

  /* Display status */
  mvwprintw(ui->status_win, 1, 2, "Components: %d", components->count);
  mvwprintw(ui->status_win, 2, 2, "Status: %s",
            ui->is_running ? (ui->paused ? "PAUSED" : "RUNNING") : "STOPPED");

  wattron(ui->status_win, COLOR_PAIR(COLOR_FINGER));
  mvwprintw(ui->status_win, 3, 2, "Finger Joints: %d", total_fingers);
  wattroff(ui->status_win, COLOR_PAIR(COLOR_FINGER));

  wattron(ui->status_win, COLOR_PAIR(COLOR_HOLE));
  mvwprintw(ui->status_win, 3, 25, "Hole Joints: %d", total_holes);
  wattroff(ui->status_win, COLOR_PAIR(COLOR_HOLE));

  wattron(ui->status_win, COLOR_PAIR(COLOR_SLOT));
  mvwprintw(ui->status_win, 3, 45, "Slot Joints: %d", total_slots);
  wattroff(ui->status_win, COLOR_PAIR(COLOR_SLOT));

  mvwprintw(ui->status_win, 4, 2, "Speed: %dms | Grid: %s | Normals: %s",
            ui->delay_ms, ui->show_grid ? "ON" : "OFF",
            ui->show_normals ? "ON" : "OFF");

  wrefresh(ui->status_win);
}

/* Draw controls window */
static void draw_controls(UIState *ui) {
  int max_y, max_x;
  getmaxyx(ui->controls_win, max_y, max_x);

  /* Clear content area */
  for (int y = 1; y < max_y - 1; y++) {
    for (int x = 1; x < max_x - 1; x++) {
      mvwaddch(ui->controls_win, y, x, ' ');
    }
  }

  wattron(ui->controls_win, COLOR_PAIR(COLOR_INFO));
  mvwprintw(ui->controls_win, 1, 2,
            "[SPACE] Start/Pause  [R] Reset  [Q] Quit");
  mvwprintw(ui->controls_win, 2, 2,
            "[+/-] Speed  [G] Toggle Grid  [N] Toggle Normals");
  mvwprintw(ui->controls_win, 3, 2,
            "3D Component Intersection Detection & Joint Classification v1.0");
  wattroff(ui->controls_win, COLOR_PAIR(COLOR_INFO));

  wrefresh(ui->controls_win);
}

/* Run algorithm with visualization */
static void run_algorithm(UIState *ui, ComponentArray *components) {
  ui->is_running = 1;
  ui->current_step = 0;
  ui->total_steps = (components->count * (components->count - 1)) / 2;

  add_log(ui, "Algorithm started", COLOR_SUCCESS);

  int step = 0;
  for (int i = 0; i < components->count - 1; i++) {
    for (int j = i + 1; j < components->count; j++) {
      Component3D *c1 = &components->components[i];
      Component3D *c2 = &components->components[j];

      char log_msg[256];
      snprintf(log_msg, sizeof(log_msg), "Comparing C%d <-> C%d", c1->id,
               c2->id);
      add_log(ui, log_msg, COLOR_INFO);

      ui->current_step = ++step;
      draw_canvas(ui, components);
      draw_log(ui);
      draw_status(ui, components);
      refresh();

      /* Handle pause and input during execution */
      int elapsed = 0;
      while (elapsed < ui->delay_ms) {
        int ch = getch();
        if (ch == ' ') {
          ui->paused = !ui->paused;
          draw_status(ui, components);
        } else if (ch == 'q' || ch == 'Q') {
          ui->is_running = 0;
          return;
        }

        if (ui->paused) {
          usleep(50000);
          continue;
        }

        usleep(50000);
        elapsed += 50;
      }

      if (ui->paused) {
        j--;
        continue;
      }

      /* Check coplanar */
      if (are_coplanar(c1, c2)) {
        if (are_parallel(c1, c2)) {
          snprintf(log_msg, sizeof(log_msg),
                   "C%d and C%d are coplanar - skipping", c1->id, c2->id);
          add_log(ui, log_msg, COLOR_WARNING);
          draw_log(ui);
          continue;
        }
      }

      /* Check intersection */
      if (components_intersect(c1, c2)) {
        snprintf(log_msg, sizeof(log_msg), "Intersection found: C%d <-> C%d",
                 c1->id, c2->id);
        add_log(ui, log_msg, COLOR_SUCCESS);

        /* Classify joint (stub logic) */
        JointType joint_type;
        int type_choice = (c1->id + c2->id) % 3;
        if (type_choice == 0) {
          joint_type = FINGER_JOINT;
          c1->fingers.data[c1->fingers.count++] = (Joint){joint_type, {}};
          c2->fingers.data[c2->fingers.count++] = (Joint){joint_type, {}};
          snprintf(log_msg, sizeof(log_msg), "Classified as FINGER joint");
          add_log(ui, log_msg, COLOR_FINGER);
        } else if (type_choice == 1) {
          joint_type = HOLE_JOINT;
          c1->holes.data[c1->holes.count++] = (Joint){joint_type, {}};
          c2->holes.data[c2->holes.count++] = (Joint){joint_type, {}};
          snprintf(log_msg, sizeof(log_msg), "Classified as HOLE joint");
          add_log(ui, log_msg, COLOR_HOLE);
        } else {
          joint_type = SLOT_JOINT;
          c1->slots.data[c1->slots.count++] = (Joint){joint_type, {}};
          c2->slots.data[c2->slots.count++] = (Joint){joint_type, {}};
          snprintf(log_msg, sizeof(log_msg), "Classified as SLOT joint");
          add_log(ui, log_msg, COLOR_SLOT);
        }

        draw_canvas(ui, components);
        draw_log(ui);
        draw_status(ui, components);
      }
    }
  }

  add_log(ui, "Algorithm completed!", COLOR_SUCCESS);
  draw_log(ui);
  ui->is_running = 0;
}

/* Reset components */
static void reset_components(ComponentArray *components) {
  for (int i = 0; i < components->count; i++) {
    Component3D *c = &components->components[i];
    c->fingers.count = 0;
    c->holes.count = 0;
    c->slots.count = 0;
  }
}

/* Main */
int main(void) {
  UIState ui = {0};
  ComponentArray components = {0};

  init_ui(&ui);
  init_test_components(&components);

  draw_borders(&ui);
  draw_controls(&ui);
  draw_canvas(&ui, &components);
  draw_log(&ui);
  draw_status(&ui, &components);
  refresh();

  add_log(&ui, "Welcome to 3D Detection Algorithm TUI Demo", COLOR_INFO);
  add_log(&ui, "Press SPACE to start the algorithm", COLOR_INFO);
  draw_log(&ui);

  /* Main loop */
  int running = 1;
  while (running) {
    int ch = getch();

    switch (ch) {
    case ' ':
      if (!ui.is_running) {
        run_algorithm(&ui, &components);
      }
      break;

    case 'r':
    case 'R':
      reset_components(&components);
      ui.log_count = 0;
      ui.current_step = 0;
      add_log(&ui, "Reset complete", COLOR_INFO);
      draw_canvas(&ui, &components);
      draw_log(&ui);
      draw_status(&ui, &components);
      break;

    case '+':
    case '=':
      if (ui.delay_ms > 100) {
        ui.delay_ms -= 100;
        draw_status(&ui, &components);
      }
      break;

    case '-':
    case '_':
      if (ui.delay_ms < 2000) {
        ui.delay_ms += 100;
        draw_status(&ui, &components);
      }
      break;

    case 'g':
    case 'G':
      ui.show_grid = !ui.show_grid;
      draw_canvas(&ui, &components);
      draw_status(&ui, &components);
      break;

    case 'n':
    case 'N':
      ui.show_normals = !ui.show_normals;
      draw_canvas(&ui, &components);
      draw_status(&ui, &components);
      break;

    case 'q':
    case 'Q':
      running = 0;
      break;
    }

    usleep(50000); /* 50ms sleep to reduce CPU usage */
  }

  cleanup_ui(&ui);

  /* Cleanup */
  for (int i = 0; i < components.count; i++) {
    Component3D *c = &components.components[i];
    free(c->vertices);
    free(c->fingers.data);
    free(c->holes.data);
    free(c->slots.data);
  }
  free(components.components);

  printf("Thank you for using 3D Detection Algorithm TUI Demo!\n");

  return 0;
}
