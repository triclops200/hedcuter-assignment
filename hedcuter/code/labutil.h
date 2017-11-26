#ifndef _LAB_UTIL_H_
#define _LAB_UTIL_H_
#endif
#define MAX_LAB_DISTANCE (291.48184f)
#include <math.h>

typedef unsigned char uchar; 

float dist3(float, float, float, float, float, float);
void rgb_lab(uchar red, uchar green, uchar blue, float& l, float& a, float& b);
void lab_rgb(float l, float a, float b, uchar& red, uchar& green, uchar& blue);
void rgb_xyz(uchar red, uchar green, uchar blue, float& x, float& y, float& z);
void xyz_rgb(float x, float y, float z, uchar& red, uchar& green, uchar& blue);
void xyz_lab(float x, float y, float z, float& l, float& a, float& b);
void lab_xyz(float l, float a, float b, float& x, float& y, float& z);
