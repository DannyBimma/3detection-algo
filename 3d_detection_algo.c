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
