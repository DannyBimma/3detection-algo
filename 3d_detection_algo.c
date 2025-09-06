/*
 * 3D Component Intersection Detection and Joint Classification Algorithm
 * My ANSI-C Implementation
 *
 * This algorithm detects intersections between 3D components and classifies
 * them into the appropriate joints (finger, hole, slot) for CAD/CAM
 * applications... I suppose
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EPSILON 1e-9
#define MAX_COMPONENTS 1000
#define MAX_SEGMENTS 100
#define MAX_JOINTS 500

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

/* Types of joint... !marijuana */
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

/* Vector operation function definitions */
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
  Vector3D result;
  double mag = vector_magnitude(v);

  if (mag < EPSILON) {
    result.x = result.y = result.z = 0.0;

    return result;
  }
  result.x = v->x / mag;
  result.y = v->y / mag;
  result.z = v->z / mag;

  return result;
}

static inline Vector3D subtract_vectors(const Vector3D *a, const Vector3D *b) {
  Vector3D result;

  result.x = a->x - b->x;
  result.y = a->y - b->y;
  result.z = a->z - b->z;

  return result;
}

static inline Vector3D add_vectors(const Vector3D *a, const Vector3D *b) {
  Vector3D result;

  result.x = a->x + b->x;
  result.y = a->y + b->y;
  result.z = a->z + b->z;

  return result;
}

static inline Vector3D transform_point(const Matrix4x4 *matrix,
                                       const Vector3D *point) {
  Vector3D result;

  result.x = matrix->m[0][0] * point->x + matrix->m[0][1] * point->y +
             matrix->m[0][2] * point->z + matrix->m[0][3];
  result.y = matrix->m[1][0] * point->x + matrix->m[1][1] * point->y +
             matrix->m[1][2] * point->z + matrix->m[1][3];
  result.z = matrix->m[2][0] * point->x + matrix->m[2][1] * point->y +
             matrix->m[2][2] * point->z + matrix->m[2][3];

  return result;
}

/* Functions for geometric predicates */
static int are_coplanar(const Component3D *c1, const Component3D *c2) {
  double dot = dot_product(&c1->normal, &c2->normal);

  return fabs(fabs(dot) - 1.0) < EPSILON;
}

static int are_parallel(const Component3D *c1, const Component3D *c2) {
  double dot = dot_product(&c1->normal, &c2->normal);

  return fabs(fabs(dot) - 1.0) < EPSILON;
}

static int components_intersect(const Component3D *c1, const Component3D *c2) {
  return 1;
}

static Segment3D find_intersection_line(const Component3D *c1,
                                        const Component3D *c2) {
  Segment3D line;

  Vector3D direction = cross_product(&c1->normal, &c2->normal);
  direction = normalise_vector(&direction);

  line.start.x = line.start.y = line.start.z = 0.0;
  line.end = direction;

  return line;
}

static SegmentArray find_line_component_intersections(const Segment3D *line,
                                                      const Component3D *comp) {
  SegmentArray result = {0};

  result.data = NULL;
  result.count = 0;
  result.capacity = 0;

  return result;
}

static int is_segment_on_edge(const Segment3D *segment,
                              const Component3D *comp) {
  return 1;
}

/* Dynamic array allocations */
static SegmentArray *create_segment_array(int initial_capacity) {
  SegmentArray *arr = malloc(sizeof(SegmentArray));

  if (!arr)
    return NULL;

  arr->data = malloc(sizeof(Segment3D) * initial_capacity);
  if (!arr->data) {
    free(arr);

    return NULL;
  }

  arr->count = 0;
  arr->capacity = initial_capacity;

  return arr;
}

static void destroy_segment_array(SegmentArray *arr) {
  if (arr) {
    free(arr->data);
    free(arr);
  }
}

static void add_segment(SegmentArray *arr, const Segment3D *segment) {
  if (arr->count >= arr->capacity) {
    int new_capacity = arr->capacity * 2;
    Segment3D *new_data = realloc(arr->data, sizeof(Segment3D) * new_capacity);

    if (!new_data)
      return;

    arr->data = new_data;
    arr->capacity = new_capacity;
  }

  arr->data[arr->count++] = *segment;
}

static JointArray *create_joint_array(int initial_capacity) {
  JointArray *arr = malloc(sizeof(JointArray));

  if (!arr)
    return NULL;

  arr->data = malloc(sizeof(Joint) * initial_capacity);

  if (!arr->data) {
    free(arr);

    return NULL;
  }

  arr->count = 0;
  arr->capacity = initial_capacity;

  return arr;
}

static void destroy_joint_array(JointArray *arr) {
  if (arr) {
    free(arr->data);
    free(arr);
  }
}

static void add_joint(JointArray *arr, JointType type,
                      const Segment3D *segment) {
  if (arr->count >= arr->capacity) {
    int new_capacity = arr->capacity * 2;
    Joint *new_data = realloc(arr->data, sizeof(Joint) * new_capacity);

    if (!new_data)
      return;

    arr->data = new_data;
    arr->capacity = new_capacity;
  }

  arr->data[arr->count].type = type;
  arr->data[arr->count].segment = *segment;
  arr->count++;
}

/* Manage components */
static ComponentArray *create_component_array(int initial_capacity) {
  ComponentArray *arr = malloc(sizeof(ComponentArray));

  if (!arr)
    return NULL;

  arr->components = malloc(sizeof(Component3D) * initial_capacity);

  if (!arr->components) {
    free(arr);

    return NULL;
  }

  arr->count = 0;
  arr->capacity = initial_capacity;

  return arr;
}

static void destroy_component_array(ComponentArray *arr) {
  if (arr) {
    int i;

    for (i = 0; i < arr->count; i++)
      cleanup_component(&arr->components[i]);

    free(arr->components);
    free(arr);
  }
}

static void init_component(Component3D *comp, int id) {
  comp->id = id;
  comp->vertices = NULL;
  comp->vertex_count = 0;

  memset(&comp->transform_3d, 0, sizeof(Matrix4x4));
  memset(&comp->inverse_transform, 0, sizeof(Matrix4x4));

  comp->normal.x = comp->normal.y = 0.0;
  comp->normal.z = 1.0;

  comp->fingers.data = malloc(sizeof(Joint) * 10);
  comp->fingers.count = 0;
  comp->fingers.capacity = 10;

  comp->holes.data = malloc(sizeof(Joint) * 10);
  comp->holes.count = 0;
  comp->holes.capacity = 10;

  comp->slots.data = malloc(sizeof(Joint) * 10);
  comp->slots.count = 0;
  comp->slots.capacity = 10;
}

static void cleanup_component(Component3D *comp) {
  free(comp->vertices);
  free(comp->fingers.data);
  free(comp->holes.data);
  free(comp->slots.data);
}

/* Core algorithm functions */
static void merge_coplanar_components(Component3D *c1, Component3D *c2) {
  if (!are_coplanar(c1, c2) || !components_intersect(c1, c2))
    return;
}

static void find_and_classify_intersections(ComponentArray *components) {
  int i, j, k;

  for (i = 0; i < components->count; i++) {
    Component3D *ci = &components->components[i];

    for (j = i + 1; j < components->count; j++) {
      Component3D *cj = &components->components[j];

      if (are_coplanar(ci, cj) && components_intersect(ci, cj)) {
        merge_coplanar_components(ci, cj);
      } else if (!are_coplanar(ci, cj) && !are_parallel(ci, cj)) {
        Segment3D intersection_line = find_intersection_line(ci, cj);

        SegmentArray segments_i =
            find_line_component_intersections(&intersection_line, ci);
        SegmentArray segments_j =
            find_line_component_intersections(&intersection_line, cj);

        for (k = 0; k < segments_i.count && k < segments_j.count; k++) {
          Segment3D seg_i = segments_i.data[k];
          Segment3D seg_j = segments_j.data[k];

          seg_i.start = transform_point(&ci->inverse_transform, &seg_i.start);
          seg_i.end = transform_point(&ci->inverse_transform, &seg_i.end);
          seg_j.start = transform_point(&cj->inverse_transform, &seg_j.start);
          seg_j.end = transform_point(&cj->inverse_transform, &seg_j.end);

          int i_on_edge = is_segment_on_edge(&seg_i, ci);
          int j_on_edge = is_segment_on_edge(&seg_j, cj);

          if (i_on_edge && j_on_edge) {
            add_joint(&ci->fingers, FINGER_JOINT, &seg_i);
            add_joint(&cj->fingers, FINGER_JOINT, &seg_j);
          } else if (i_on_edge && !j_on_edge) {
            add_joint(&ci->fingers, FINGER_JOINT, &seg_i);
            add_joint(&cj->holes, HOLE_JOINT, &seg_j);
          } else if (!i_on_edge && j_on_edge) {
            add_joint(&ci->holes, HOLE_JOINT, &seg_i);
            add_joint(&cj->fingers, FINGER_JOINT, &seg_j);
          } else {
            add_joint(&ci->slots, SLOT_JOINT, &seg_i);
            add_joint(&cj->slots, SLOT_JOINT, &seg_j);
          }
        }

        free(segments_i.data);
        free(segments_j.data);
      }
    }
  }
}

// Algo starting point
int detect_component_intersections(ComponentArray *components) {
  if (!components || components->count == 0)
    return -1;

  find_and_classify_intersections(components);

  return 0;
}
