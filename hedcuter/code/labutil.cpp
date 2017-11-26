#include "labutil.h"
#include <cstdio>
// CONSTANTS
// USING A D65 illuminant
float inv255 = 1.0f/255.0;
float ref_x = 95.047f;
float ref_y = 100.0f;
float ref_z = 108.883f;
float bgl, bga, bgb;
float max_lab_distance;

float square(float x)
{
	return x * x;
}
float dist3(float x1, float y1, float z1,
            float x2, float y2, float z2)
{
	return sqrt(square(x1 - x2) +
	            square(y1 - y2) +
	            square(z1 - z2));
}

float linear_combine(float vr, float vg, float vb,
                     float wr, float wg, float wb){
	return (vr * wr) + (vg * wg) + (vb * wb);

}

void rgb_xyz(uchar r, uchar g, uchar b,
             float& x, float& y, float& z)
{
	float vr = r * inv255;
	float vg = g * inv255;
	float vb = b * inv255;
	if(vr > 0.04045){
		vr = pow((vr + 0.055)/1.055,2.4);
	} else {
		vr = vr / 12.92;
	}
	vr = vr * 100;
	if(vg > 0.04045){
		vg = pow((vg + 0.055)/1.055,2.4);
	} else {
		vg = vg / 12.92;
	}
	vg = vg * 100;
	if(vb > 0.04045){
		vb = pow((vb + 0.055)/1.055,2.4);
	} else {
		vb = vb / 12.92;
	}
	vb = vb * 100;
	x = linear_combine(vr, vg, vb,
	                   0.4124, 0.3576, 0.1805);
	y = linear_combine(vr, vg, vb,
	                   0.2126, 0.7152, 0.0722);
	z = linear_combine(vr, vg, vb,
	                   0.0193, 0.1192, 0.9505);
}

void xyz_lab(float x, float y, float z,
             float& l, float& a, float& b)
{
	float vx = x/ref_x;
	float vy = y/ref_y;
	float vz = z/ref_z;
	if(vx > 0.008856){
		vx = pow(vx, 0.333333f);
	} else {
		vx = (16.0 / 116) + (vx * 7.787);
	}
	if(vy > 0.008856){
		vy = pow(vy, 0.333333f);
	} else {
		vy = (16.0 / 116) + (vy * 7.787);
	}
	if(vz > 0.008856){
		vz = pow(vz, 0.333333f);
	} else {
		vz = (16.0 / 116) + (vz * 7.787);
	}
	l = (116 * vy) - 16;
	a = (500 * (vx - vy));
	b = (200 * (vy - vz));
}

void rgb_lab(uchar red, uchar green, uchar blue,
             float& l, float& a, float& b)
{
	float x, y, z;
	rgb_xyz(red, green, blue, x, y, z);
	xyz_lab(x, y, z, l, a, b);
}

float get_max_dist()
{
	float max = 0;
	for(int r = 0; r < 256; r++){
		for(int g = 0; g < 256; g++){
			for(int b = 0; b < 256; b++){
				float l2,a2,b2;
				rgb_lab(r,g,b,l2,a2,b2);
				float d = dist3(bgl,bga,bgb,l2,a2,b2);
				if(d > max){
					max = d;
				}
			}
		}
	}
	return max;
}

void init_lab_with_bg(uchar red, uchar green, uchar blue)
{
	rgb_lab(red, green, blue, bgl, bga, bgb);
	printf("%f\n%f\n%f\n",bgl,bga,bgb);
	max_lab_distance = get_max_dist();

}
