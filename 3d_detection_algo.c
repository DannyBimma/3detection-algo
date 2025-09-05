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
