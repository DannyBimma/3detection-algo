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
