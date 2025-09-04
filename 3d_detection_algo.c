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
