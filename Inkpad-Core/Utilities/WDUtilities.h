//
//  WDUtilities.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "WDPickResult.h"

@class WDStrokeStyle;

//
// Color Conversion
//

void HSVtoRGB(CGFloat h, CGFloat s, CGFloat v, CGFloat *r, CGFloat *g, CGFloat *b);
void RGBtoHSV(CGFloat r, CGFloat g, CGFloat b, CGFloat *h, CGFloat *s, CGFloat *v);

//
// Drawing Functions
//

void WDDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size);
void WDDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest);
void WDContextDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef);

//
// Mathy Stuff
//

#define WDRadiansFromDegrees(degrees) ((degrees)*M_PI/180.0)
#define WDDegreesFromRadians(radians) ((radians)*180.0/M_PI)



// random value in the range [0.0, 1.0]
CGFloat WDRandomFloat(void);

// remap [0.0, 1.0] to a sine curve
CGFloat WDSineCurve(CGFloat phase);

NSData * WDSHA1DigestForData(NSData *data);

//
// Geometry
//
#pragma mark -
#pragma mark Geometry

static inline CGVector
CGVectorApplyAffineTransform(CGVector v, CGAffineTransform t)
{
	return (CGVector){
	(CGFloat)((double)t.a * v.dx + (double)t.c * v.dy),
	(CGFloat)((double)t.b * v.dx + (double)t.d * v.dy) };
}


CGFloat WDGetRotationFromTransform(CGAffineTransform T);
CGVector WDGetScaleFromTransform(CGAffineTransform T);

CGSize WDSizeOfRectWithAngle(CGRect rect, float angle, CGPoint *upperLeft, CGPoint *upperRight);

// return point with unit length from the origin
CGPoint WDNormalizePoint(CGPoint vector);

// expand the passed rectangle to include the passed point
CGRect WDGrowRectToPoint(CGRect rect, CGPoint pt);

CGPoint WDSharpPointInContext(CGPoint pt, CGContextRef ctx);

// keep point at 90 degree angles
CGPoint WDConstrainPoint(CGPoint pt);

CGRect WDRectWithRadius(CGPoint c, CGFloat radius);
CGRect WDRectFromPoint(CGPoint a, float width, float height);

CGFloat WDCollinearity(CGPoint a, CGPoint b, CGPoint c);
BOOL WDCollinear(CGPoint a, CGPoint b, CGPoint c);

BOOL WDLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *r, float *s);
BOOL WDLineSegmentsIntersect(CGPoint A, CGPoint B, CGPoint C, CGPoint D);

CGRect WDShrinkRect(CGRect rect, float percentage);

//
// Paths
//

CGPathRef WDCreateCubicPathFromQuadraticPath(CGPathRef pathRef);

void WDPathApplyAccumulateElement(void *info, const CGPathElement *element);
CGRect WDStrokeBoundsForPath(CGPathRef pathRef, WDStrokeStyle *strokeStyle);


#import "WDStrokeOptions.h"
CGRect WDStrokeOptionsStyleBoundsForPath
(WDStrokeOptions *strokeOptions, CGPathRef pathRef);


CGPathRef WDCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform);


//
// Misc
//

#define NSNumberFromCGFloat(v) \
(sizeof(CGFloat)>32)?[NSNumber numberWithDouble:v]:[NSNumber numberWithFloat:v]

#define NSStringFromCGFloat(v) \
[NSNumberFromCGFloat(v) stringValue]

#define CGFloatFromString(str) \
((sizeof(CGFloat)>32)?[str doubleValue]:[str floatValue])




NSString * WDSVGStringForCGAffineTransform(CGAffineTransform transform);

WDPickResult * WDSnapToRectangle(CGRect rect, CGAffineTransform *transform, CGPoint pt, float viewScale, int snapFlags);

//
// WDQuad
//
// This stuff is used for placing text on a path
#pragma mark -

typedef struct
{
	CGPoint P[4];
}
WDQuad;

// For our purposes null quad can be literal
static const WDQuad WDQuadNull = {0,0, 0,0, 0,0, 0,0};

WDQuad WDQuadMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d);
WDQuad WDQuadWithRect(CGRect rect, CGAffineTransform transform);
WDQuad WDQuadApplyTransform(WDQuad quad, CGAffineTransform T);

//CGFloat WDQuadGetRotation(WDQuad quad);
//CGSize WDQuadGetSize(WDQuad quad);

BOOL WDQuadIsNull(WDQuad Q);
BOOL WDQuadEqualToQuad(WDQuad a, WDQuad b);
BOOL WDQuadIntersectsQuad(WDQuad a, WDQuad b);
BOOL WDQuadIntersectsRect(WDQuad quad, CGRect R);
BOOL WDQuadContainsPoint(WDQuad quad, CGPoint P);
CGPoint WDQuadGetCenter(WDQuad Q);
CGPathRef WDQuadCreateCGPath(WDQuad q);
NSString * NSStringFromWDQuad(WDQuad quad);

#pragma mark -

//
// Static Inline Functions (Geometry)
//

static inline float WDIntDistance(int x1, int y1, int x2, int y2) {
	int xd = (x1-x2), yd = (y1-y2);
	return sqrt(xd * xd + yd * yd);
}

static inline CGPoint WDAddPoints(CGPoint a, CGPoint b)
{ return (CGPoint){ a.x + b.x, a.y + b.y }; }

static inline CGPoint WDSubtractPoints(CGPoint a, CGPoint b)
{ return (CGPoint){ a.x - b.x, a.y - b.y }; }

static inline CGPoint WDMultiplyPoints(CGPoint a, CGPoint b)
{ return (CGPoint){ a.x*b.x,a.y*b.y }; }

static inline CGPoint WDInterpolatePoints(CGPoint a, CGPoint b, CGFloat r)
{ return (CGPoint){ a.x+r*(b.x-a.x),a.y+r*(b.y-a.y) }; }


static inline float WDDistance(CGPoint a, CGPoint b) {
	float xd = (a.x - b.x);
	float yd = (a.y - b.y);
	
	return sqrt(xd * xd + yd * yd);
}

static inline float WDClamp(float min, float max, float value) {
	return (value < min) ? min : (value > max) ? max : value;
}

static inline CGPoint WDCenterOfLine(CGPoint a, CGPoint b)
{ return (CGPoint){ 0.5*(a.x+b.x), 0.5*(a.y+b.y) }; }

static inline CGPoint WDCenterOfRect(CGRect rect) {
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline CGRect WDMultiplyRectScalar(CGRect r, float s) {
	return CGRectMake(r.origin.x * s, r.origin.y * s, r.size.width * s, r.size.height * s);
}

static inline CGSize WDMultiplySizeScalar(CGSize size, float s) {
	return CGSizeMake(size.width * s, size.height * s);
}

static inline CGSize WDScaleSize(CGSize size, CGFloat sx, CGFloat sy)
{ return (CGSize){ size.width * sx, size.height * sy }; }

static inline CGPoint WDMultiplyPointScalar(CGPoint p, float s) {
	return CGPointMake(p.x * s, p.y * s);
}

static inline CGRect WDRectWithPoints(CGPoint a, CGPoint b) {
	float minx = MIN(a.x, b.x);
	float maxx = MAX(a.x, b.x);
	float miny = MIN(a.y, b.y);
	float maxy = MAX(a.y, b.y);
	
	return CGRectMake(minx, miny, maxx - minx, maxy - miny);
}

static inline CGRect WDRectWithPointsConstrained(CGPoint a, CGPoint b, BOOL constrained) {
	float minx = MIN(a.x, b.x);
	float maxx = MAX(a.x, b.x);
	float miny = MIN(a.y, b.y);
	float maxy = MAX(a.y, b.y);
	float dimx = maxx - minx;
	float dimy = maxy - miny;
	
	if (constrained) {
		dimx = dimy = MAX(dimx, dimy);
	}
	
	return CGRectMake(minx, miny, dimx, dimy);
}

static inline CGRect WDFlipRectWithinRect(CGRect src, CGRect dst)
{
	src.origin.y = CGRectGetMaxY(dst) - CGRectGetMaxY(src);
	return src;
}

static inline CGRect WDRectFromSize(CGSize size)
{
	CGRect rect = CGRectZero;
	rect.size = size;
	return rect;
}

static inline CGPoint WDFloorPoint(CGPoint pt)
{
	return CGPointMake(floor(pt.x), floor(pt.y));
}

static inline CGPoint WDRoundPoint(CGPoint pt)
{
	return CGPointMake(round(pt.x), round(pt.y));
}

static inline CGPoint WDAveragePoints(CGPoint a, CGPoint b)
{
	return WDMultiplyPointScalar(WDAddPoints(a, b), 0.5f);    
}

static inline CGSize WDRoundSize(CGSize size)
{
	return CGSizeMake(round(size.width), round(size.height));
}

static inline float WDMagnitude(CGPoint point)
{
	return WDDistance(point, CGPointZero);
}

static inline CGPoint WDScaleVector(CGPoint v, float toLength)
{
	float fromLength = WDMagnitude(v);
	float scale = 1.0;
	
	if (fromLength != 0.0) {
		scale = toLength / fromLength;
	}
	
	return CGPointMake(v.x * scale, v.y * scale);
}

