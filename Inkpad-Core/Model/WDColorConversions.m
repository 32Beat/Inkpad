////////////////////////////////////////////////////////////////////////////////
/*
	WDColorConversions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////


#import "WDColorConversions.h"

////////////////////////////////////////////////////////////////////////////////

typedef struct _RGB
{
	CGFloat R;
	CGFloat G;
	CGFloat B;
}
_RGB;

typedef struct _HSB
{
	CGFloat H;
	CGFloat S;
	CGFloat B;
}
_HSB;

///////////////////////////////////////////////////////////////////////////////

typedef struct _XYZ
{
	CGFloat X;
	CGFloat Y;
	CGFloat Z;
}
_XYZ;

typedef struct _Lab
{
	CGFloat L;
	CGFloat a;
	CGFloat b;
}
_Lab;

typedef struct _LCH
{
	CGFloat L;
	CGFloat C;
	CGFloat H;
}
_LCH;

////////////////////////////////////////////////////////////////////////////////

static inline void _RGB_HSB_1 (double r, double g, double b, _HSB *hsb);
static inline void _HSB_RGB_1 (double H, double S, double B, _RGB *rgb);
static inline void _sRGB_XYZ_1 (double R, double G, double B, _XYZ *xyz);
static inline void _XYZ_sRGB_1 (double X, double Y, double Z, _RGB *rgb);
static inline void _XYZ_Lab_1 (double X, double Y, double Z, _Lab *lab);
static inline void _Lab_XYZ_1 (double L, double a, double b, _XYZ *xyz);
static inline void _Lab_LCH_1 (double L, double a, double b, _LCH *lch);
static inline void _LCH_Lab_1 (double L, double C, double H, _Lab *lab);

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

void RGBtoHSV(CGFloat r, CGFloat g, CGFloat b, CGFloat *hsb)
{ _RGB_HSB_1(r, g, b, (_HSB *)hsb); }

void HSVtoRGB(CGFloat h, CGFloat s, CGFloat b, CGFloat *rgb)
{ _HSB_RGB_1(h, s, b, (_RGB *)rgb); }

void SRGBtoXYZ(CGFloat r, CGFloat g, CGFloat b, CGFloat *xyz)
{ _sRGB_XYZ_1(r, g, b, (_XYZ *)xyz); }

void XYZtoSRGB(CGFloat x, CGFloat y, CGFloat z, CGFloat *rgb)
{ _XYZ_sRGB_1(x, y, z, (_RGB *)rgb); }

void XYZtoLAB(CGFloat X, CGFloat Y, CGFloat Z, CGFloat *lab)
{ _XYZ_Lab_1(X, Y, Z, (_Lab *)lab); }

void LABtoXYZ(CGFloat L, CGFloat a, CGFloat b, CGFloat *xyz)
{ _Lab_XYZ_1(L, a, b, (_XYZ *)xyz); }

void LABtoLCH(CGFloat L, CGFloat a, CGFloat b, CGFloat *lch)
{ _Lab_LCH_1(L, a, b, (_LCH *)lch); }

void LCHtoLAB(CGFloat L, CGFloat C, CGFloat H, CGFloat *lab)
{ _LCH_Lab_1(L, C, H, (_Lab *)lab); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

void _RGB_HSB_1 (double r, double g, double b, _HSB *hsb)
{
	double H, S, B;
	
	// Test for none - gray ((r!=g)||(g!=b))
	if ((r!=g)||(g!=b)) 
	{
		// Now max - min will always be larger than 0
		double max, max_min, mid_min;

		if ((g-b) >= 0) 	
		{				
			if ((r-g) >= 0)
				// Red to yellow, (max, mid, min) = (r, g, b), Hue = 0° - 60°
				{ max = r; max_min = r-b; mid_min = g-b; H = mid_min/max_min; }
			else
			if ((r-b) >= 0) 	
				// Green to yellow, (max, mid, min) = (g, r, b), Hue = 120° - 60°
				{ max = g; max_min = g-b; mid_min = r-b; H = 2 - mid_min/max_min; }
			else 					
				// Green to cyan, (max, mid, min) = (g, b, r), Hue = 120° - 180°
				{ max = g; max_min = g-r; mid_min = b-r; H = 2 + mid_min/max_min; }
		}
		else
		{
			if ((r-g) <= 0) 	
				// Blue to cyan, (max, mid, min) = (b, g, r), Hue = 240° - 180°
				{ max = b; max_min = b-r; mid_min = g-r; H = 4 - mid_min/max_min; }
			else
			if ((r-b) <= 0) 	
				// Blue to magenta, (max, mid, min) = (b, r, g), Hue = 240° - 300°
				{ max = b; max_min = b-g; mid_min = r-g; H = 4 + mid_min/max_min; }
			else 					
				// Red to magenta, (max, mid, min) = (r, b, g), Hue = 360° - 300°
				{ max = r; max_min = r-g; mid_min = b-g; H = 6 - mid_min/max_min; }
		}
		
		H /= 6.0;
		S = max_min/max;
		B = max;
		if (max_min > max) B = max_min;
	}
	else	
	{ H = 0; S = 0; B = r; }
			
	hsb->H = H;
	hsb->S = S;
	hsb->B = B;
}

///////////////////////////////////////////////////////////////////////////////

void _HSB_RGB_1 (double H, double S, double B, _RGB *rgb)
{
	// Test if pixel has color
	if ((B > 0.0) && (S > 0.0))
	{ 
		double max = B;
		double max_min = max*S;
		double min = max - max_min;
		double r, g, b;

		H *= 360.0;
		if ((H -= 60.0) <= 0)
		{ r = max; b = min; g = max + H*max_min/60.0; }
		else
		if ((H -= 60.0) <= 0)
		{ g = max; b = min; r = min - H*max_min/60.0; }
		else
		if ((H -= 60.0) <= 0)
		{ g = max; r = min; b = max + H*max_min/60.0; }
		else
		if ((H -= 60.0) <= 0)
		{ b = max; r = min; g = min - H*max_min/60.0; }
		else
		if ((H -= 60.0) <= 0)
		{ b = max; g = min; r = max + H*max_min/60.0; }
		else
		// Note: H -= 60.0 skipped, hence "max - ..."
		{ r = max; g = min; b = max - H*max_min/60.0; }
		
		// Store r,g,b pixel
		rgb->R = (r);
		rgb->G = (g);
		rgb->B = (b);
	}
	else
	// Pixel is achromatic
	{ 
		rgb->R = \
		rgb->G = \
		rgb->B = B; 
	}
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////

static inline double srgb_to_linear(double v)
{ return v <= 0.03928 ? v/12.92 : pow((v+0.055)/1.055, 2.4); }

void _sRGB_XYZ_1 (double R, double G, double B, _XYZ *xyz)
{
	R = srgb_to_linear(R);
	G = srgb_to_linear(G);
	B = srgb_to_linear(B);

	xyz->X = 0.4124*R + 0.3576*G + 0.1805*B;
	xyz->Y = 0.2126*R + 0.7152*G + 0.0722*B;
	xyz->Z = 0.0193*R + 0.1192*G + 0.9505*B;

	xyz->X /= 0.9505;
	xyz->Z /= 1.0890;
}

////////////////////////////////////////////////////////////////////////////////

static inline double linear_to_srgb(double v)
{ return v <= 0.00304 ? 12.92*v : 1.055*pow(v, (1.0/2.4))-0.055; }

void _XYZ_sRGB_1 (double X, double Y, double Z, _RGB *rgb)
{
	X *= 0.9505;
	Z *= 1.0890;

	double r = +3.2410*X - 1.5374*Y - 0.4986*Z;
	double g = -0.9692*X + 1.8760*Y + 0.0416*Z;
	double b = +0.0556*X - 0.2040*Y + 1.0570*Z;

	rgb->R = linear_to_srgb(r);
	rgb->G = linear_to_srgb(g);
	rgb->B = linear_to_srgb(b);

	// Rudimentary hue-preserving clipping test
	double max = rgb->R;
	if (max < rgb->G) max = rgb->G;
	if (max < rgb->B) max = rgb->B;
	if (max > 1.0)
	{

		rgb->R /= max;
		rgb->G /= max;
		rgb->B /= max;
	}
/*
	double min = rgb->R;
	if (min > rgb->G) min = rgb->G;
	if (min > rgb->B) min = rgb->B;*/

	if (rgb->R < 0.0) rgb->R = 0.0;
	if (rgb->G < 0.0) rgb->G = 0.0;
	if (rgb->B < 0.0) rgb->B = 0.0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
#define LAB_k 		(24389.0/27.0)
#define LAB_e 		(216.0/24389.0)
#define LAB_i		(6.0/29.0)

#define mXYZ_LAB_POW3(n) \
( ((n)>LAB_e) ? pow((n), (1.0/3.0)) : (LAB_k*(n)+16.0)/116.0 )
#define mLAB_XYZ_POW3(n) \
( ((n)>LAB_i) ? pow((n), 3.0) : (116.0*(n)-16.0)/LAB_k )
////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

void _XYZ_Lab_1 (double X, double Y, double Z, _Lab *lab)
{
	double L, a, b;
			
	X = mXYZ_LAB_POW3(X);
	Y = mXYZ_LAB_POW3(Y);
	Z = mXYZ_LAB_POW3(Z);
	
	L = 116.0 * Y - 16.0;	
	a = 500.0 * (X - Y);
	b = 200.0 * (Y - Z);
	
	lab->L = L;
	lab->a = a;
	lab->b = b;	
}

////////////////////////////////////////////////////////////////////////////////

void _Lab_XYZ_1 (double L, double a, double b, _XYZ *xyz)
{
	double X, Y, Z;

	Y = (L + 16.0) / 116.0;
	X = a/500.0 + Y;
	Z = Y - b/200.0;
	
	X = mLAB_XYZ_POW3(X);
	Y = mLAB_XYZ_POW3(Y);
	Z = mLAB_XYZ_POW3(Z);

	xyz->X = X;
	xyz->Y = Y;
	xyz->Z = Z;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

void _Lab_LCH_1 (double L, double a, double b, _LCH *lch)
{
	double C = sqrt(a*a+b*b);
	double H = 180.0*atan2(b, a)/M_PI;
	if (H < 0) H += 360.0;

	lch->L = L;
	lch->C = C;
	lch->H = H;
}

///////////////////////////////////////////////////////////////////////////////

void _LCH_Lab_1 (double L, double C, double H, _Lab *lab)
{
	H = M_PI * H / 180.0;
	
	lab->L = L;
	lab->a = C*cos(H);
	lab->b = C*sin(H);
}

///////////////////////////////////////////////////////////////////////////////









