////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegment.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDBezierSegment.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
// Utility function
static inline CGPoint CGPointInterpolate(CGPoint P1, CGPoint P2, CGFloat r)
{ return (CGPoint){ P1.x + r * (P2.x - P1.x), P1.y + r * (P2.y - P1.y) }; }
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Initializers
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentMakeWithQuadPoints
	---------------------------------
	Initialize Cubic Bezier segment using Quadratic points
*/

WDBezierSegment
WDBezierSegmentMakeWithQuadPoints(CGPoint a, CGPoint c, CGPoint b)
{
	// Convert to cubic http://fontforge.sourceforge.net/bezier.html
	return (WDBezierSegment) { a,
	CGPointInterpolate(a, c, 2.0/3.0),
	CGPointInterpolate(b, c, 2.0/3.0), b };
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentMakeWithNodes
	----------------------------
	Initialize Cubic Bezier segment using WDBezierNodes objects
	
	Using higher language constructs in lower language files is odd, 
	probably needs to be moved elsewhere.

	TODO: remove from this file
*/

#import "WDBezierNode.h"

WDBezierSegment
WDBezierSegmentMakeWithNodes(WDBezierNode *a, WDBezierNode *b)
{ return (WDBezierSegment){a.anchorPoint,a.outPoint,b.inPoint,b.anchorPoint}; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Operations
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentPointAtT
	-----------------------
	Computation for bezier values can be rewritten as a polynomial:

		// Compute polynomial co-efficients
		double d = P0;
		double c = 3*(P1-P0);
		double b = 3*(P2-P1) - c;
		double a = (P3-P0) - b - c;

		// Compute polynomial result for t
		return ((a * t + b) * t + c) * t + d;
	
	However, on modern architecture, this is only fractionally 
	faster than the code below.
	
	CGPointInterpolate is inlined, so doesn't need expanding out 
	for performance. Note also, if a function appears in the same code file, 
	the compiler will generally inline during optimization if allowed.
*/

CGPoint WDBezierSegmentPointAtT(WDBezierSegment S, CGFloat t)
{
	const CGPoint *P = &S.a_;
	CGPoint A = CGPointInterpolate(P[0], P[1], t);
	CGPoint B = CGPointInterpolate(P[1], P[2], t);
	CGPoint C = CGPointInterpolate(P[2], P[3], t);

	CGPoint D = CGPointInterpolate(A, B, t);
	CGPoint E = CGPointInterpolate(B, C, t);

	return CGPointInterpolate(D, E, t);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentTangetAtT
	------------------------
	Computation for first derivative at t
*/

CGPoint WDBezierSegmentTangentAtT(WDBezierSegment S, CGFloat t)
{
	const CGPoint *P = &S.a_;
	CGPoint A = CGPointInterpolate(P[0], P[1], t);
	CGPoint B = CGPointInterpolate(P[1], P[2], t);
	CGPoint C = CGPointInterpolate(P[2], P[3], t);

	CGPoint D = CGPointInterpolate(A, B, t);
	CGPoint E = CGPointInterpolate(B, C, t);

	return (CGPoint){ E.x-D.x, E.y-D.y };
}

////////////////////////////////////////////////////////////////////////////////

CGPoint WDBezierSegmentSplitAtT
(WDBezierSegment S, WDBezierSegment *L, WDBezierSegment *R, CGFloat t)
{
	/*
		No need to check for straightness first,
		Splitting is likely never called if straight,
		so the conditional merely slows down processor.
		
		CGPointInterpolate is inlined, so doesn't need expanding out 
		for performance. Note also, if in the same code file, 
		the compiler will generally inline functions during optimization.
	*/
	const CGPoint *P = &S.a_;
	CGPoint A = CGPointInterpolate(P[0], P[1], t);
	CGPoint B = CGPointInterpolate(P[1], P[2], t);
	CGPoint C = CGPointInterpolate(P[2], P[3], t);

	CGPoint D = CGPointInterpolate(A, B, t);
	CGPoint E = CGPointInterpolate(B, C, t);

	CGPoint F = CGPointInterpolate(D, E, t);

	if (L != nil)
	{ *L = WDBezierSegmentMake(S.a_, A, D, F); }

	if (R != nil)
	{ *R = WDBezierSegmentMake(F, E, C, S.b_); }

	return F;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIsFlat
	---------------------
	Check whether segment can be approximated by a line between endpoints.
	
	Suppose we have a horizontal line with tangential controlpoints 
	at both ends with length r, then the curve deviates at most
	(3.0/4.0) * r from a straight line. Thus, a 1 pixel tolerance means
	that the vectors should be within r <= (4.0/3.0) * tolerance

	For simplicity and speed it would be nice if we could only check 
	the euclidian vector coordinates against tolerance. This introduces 
	an additional error for the worst case scenario (a diagonal line
	at 45degr angle). To compensate for this additional error,
	tolerance should be divided by sqrt(2). 
	
	Conveniently: tolerance * (4.0/3.0) / sqrt(2) = ~tolerance

*/

const float kDefaultFlatness = 1.5; // 1.5 pixels both ways = 3


BOOL WDBezierSegmentIsFlat(WDBezierSegment S, CGFloat deviceTolerance)
{
	const CGPoint *P = &S.a_;
	if (fabs(P[1].x - P[0].x) > deviceTolerance) return NO;
	if (fabs(P[1].y - P[0].y) > deviceTolerance) return NO;
	if (fabs(P[2].x - P[3].x) > deviceTolerance) return NO;
	if (fabs(P[2].y - P[3].y) > deviceTolerance) return NO;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Compute Bounds
////////////////////////////////////////////////////////////////////////////////
/*
	_BezierRange
	------------
	Compute the result range for cubic bezier co-efficients
	
	source range is t = [0, ..., 1]
	result range is B(t) = ((a*t+b)*t+c)*t+d
	
	Computing the min and max values for B(t) allows easy
	construction of the bounding box of B(t)

	Steps:
	1. Set min,max to endpoints
	2. Compute cubic polynomial
	3. Compute derivative roots
	4. Adjust min,max using results at roots
	
	For cubic polynomials with co-efficients a, b, c, d
	derivative co-efficients are:
	A = 3*a
	B = 2*b
	C = c

	discriminant is:
	D = B*B - 4*A*C
	
	roots are at:
	t = (-B - sqrt(D))/(2*A)
	t = (-B + sqrt(D))/(2*A)

	For quadratic polynomials with co-efficients a=0, b, c, d
	derivative co-efficients are:
	A = 3*a = 0
	B = 2*b
	C = c
	
	root is at:
	t = -C / B

	See also:
	http://en.wikipedia.org/wiki/Loss_of_significance
*/

static inline CGPoint _BezierRange(double P0, double P1, double P2, double P3)
{
	// Initial range
	double min = MIN(P0, P3);
	double max = MAX(P0, P3);

	// Compute cubic polynomial co-efficients
	double d = P0;
	double c = 3*(P1-P0);
	double b = 3*(P2-P1) - c;
	double a = (P3-P0) - b - c;

	// Compute polynomial co-efficients for derivative
	double A = a+a+a;
	double B = b+b;
	double C = c;

	// Test for Cubic polynomial
	if (A != 0.0)
	{
		// Compute discriminant
		double D = B*B - 4*A*C;
		// Derivative must switch sign
		if (D > 0)
		{
			double t, v;

			// Compute root 1
			t = B < 0.0 ? (-B+sqrt(D))/(2*A) : (-B-sqrt(D))/(2*A);
			if ((0.0<t)&&(t<1.0))
			{
				v = ((a*t + b)*t + c)*t + d;
				// Update min & max
				if (min > v) min = v;
				if (max < v) max = v;
			}

			// Compute root 2
			t = C / (A*t);
			if ((0.0<t)&&(t<1.0))
			{
				v = ((a*t + b)*t + c)*t + d;
				// Update min & max
				if (min > v) min = v;
				if (max < v) max = v;
			}
		}
	}
	else
	// Test for Quadratic polynomial
	if (B != 0.0)
	{
		// Compute root
		double t = -C / B;
		if ((0.0<t)&&(t<1.0))
		{
			double v = (b*t + c)*t + d;
			// Update min & max
			if (min > v) min = v;
			if (max < v) max = v;
		}
	}

	return (CGPoint){ min, max-min };
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentGetCurveBounds
	-----------------------------
	Compute smallest rectangle encompassing curve described by segment.
	
	Note that we're abusing CGPoint for range description where:
	P.x = start of range
	P.y = length of range
*/

CGRect WDBezierSegmentGetCurveBounds(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	CGPoint rangeX = _BezierRange(P[0].x, P[1].x, P[2].x, P[3].x);
	CGPoint rangeY = _BezierRange(P[0].y, P[1].y, P[2].y, P[3].y);

	return (CGRect){rangeX.x, rangeY.x, rangeX.y, rangeY.y};
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentGetControlBounds
	-------------------------------
	Compute smallest rectangle encompassing all 4 points in segment.
	
	This rectangle is guaranteed to also encompass the curve, 
	but is generally larger than CurveBounds.
*/

CGRect WDBezierSegmentGetControlBounds(WDBezierSegment seg)
{
	const CGPoint *P = &seg.a_;

	CGFloat minX1 = MIN(P[0].x, P[1].x);
	CGFloat minX2 = MIN(P[2].x, P[3].x);
	CGFloat minX = MIN(minX1, minX2);

	CGFloat minY1 = MIN(P[0].y, P[1].y);
	CGFloat minY2 = MIN(P[2].y, P[3].y);
	CGFloat minY = MIN(minY1, minY2);

	CGFloat maxX1 = MAX(P[0].x, P[1].x);
	CGFloat maxX2 = MAX(P[2].x, P[3].x);
	CGFloat maxX = MAX(maxX1, maxX2);

	CGFloat maxY1 = MAX(P[0].y, P[1].y);
	CGFloat maxY2 = MAX(P[2].y, P[3].y);
	CGFloat maxY = MAX(maxY1, maxY2);

	return (CGRect){ minX, minY, maxX-minX, maxY-minY };
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Intersections
////////////////////////////////////////////////////////////////////////////////
/*
	CGRectIncludesPoint
	-------------------
	Determines if point is within or on rectangle bounds
	
	Note that this is not equivalent to CGRectContainsPoint 
	which excludes the far edges.
*/

static inline BOOL CGRectIncludesPoint(CGRect R, CGPoint P)
{
	if (P.x < CGRectGetMinX(R)) return NO;
	if (P.y < CGRectGetMinY(R)) return NO;
	if (P.x > CGRectGetMaxX(R)) return NO;
	if (P.y > CGRectGetMaxY(R)) return NO;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIntersectsRect
	-----------------------------
	Determine whether any part of the curve described by segment
	is included by rectangle bounds
	
	Generally when drawing, we draw with finitely small pen around 
	an infinitely small point, therefore we'll assume edge to mean inclusive.
*/

BOOL WDBezierSegmentIntersectsRect(WDBezierSegment S, CGRect R)
{
	// Test end points
	if (CGRectIncludesPoint(R, S.a_)||
		CGRectIncludesPoint(R, S.b_))
		return YES;

	if (CGRectIntersectsRect(R, WDBezierSegmentGetControlBounds(S)))
	{
		WDBezierSegment Sn;
		WDBezierSegmentSplitAtT(S, &S, &Sn, 0.5);

		return
		WDBezierSegmentIntersectsRect(Sn, R)||
		WDBezierSegmentIntersectsRect(S, R);
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

CGRect WDLineGetBounds(CGPoint p1, CGPoint p2)
{
	CGFloat x,y,w,h;

	if (p1.x <= p2.x)
	{ w = p2.x - (x = p1.x); }
	else
	{ w = p1.x - (x = p2.x); }

	if (p1.y <= p2.y)
	{ h = p2.y - (y = p1.y); }
	else
	{ h = p1.y - (y = p2.y); }

	return (CGRect){ x, y, w, h };
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDLineIntersectsRect(CGPoint a, CGPoint b, CGRect R)
{
	// Test end points
	if (CGRectIncludesPoint(R, a)||
		CGRectIncludesPoint(R, b))
		return YES;

	if (CGRectIntersectsRect(R, WDLineGetBounds(a, b)))
	{
		// Split half way
		CGPoint m = CGPointInterpolate(a, b, 0.5);

		return
		WDLineIntersectsRect(a, m, R)||
		WDLineIntersectsRect(m, b, R);
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

// TODO: cleaned upto here




////////////////////////////////////////////////////////////////////////////////

static inline CGRect CGRectExpandToPoint(CGRect R, CGPoint P)
{
	if (R.origin.x > P.x)
		R.origin.x = P.x;
	else
	if (R.size.width < (P.x - R.origin.x))
		R.size.width = (P.x - R.origin.x);

	if (R.origin.y > P.y)
		R.origin.y = P.y;
	else
	if (R.size.height < (P.y - R.origin.y))
		R.size.height = (P.y - R.origin.y);

	return R;
}


static inline BOOL CGRectExcludesPoint(CGRect R, CGPoint P)
{
	return
	P.x < CGRectGetMinX(R)||
	P.x > CGRectGetMaxX(R)||
	P.y < CGRectGetMinY(R)||
	P.y > CGRectGetMaxY(R);
}


CGRect WDBezierSegmentAdjustBounds(WDBezierSegment S, CGRect B)
{
	const CGPoint *P = &S.a_;
	B = CGRectExpandToPoint(B, P[0]);
	B = CGRectExpandToPoint(B, P[3]);

	if (CGRectExcludesPoint(B, P[1])||
		CGRectExcludesPoint(B, P[2]))
	{
		WDBezierSegment L, R;
		WDBezierSegmentSplitAtT(S, &L, &R, 0.5);

		B = WDBezierSegmentAdjustBounds(L, B);
		B = WDBezierSegmentAdjustBounds(R, B);
	}

	return B;
}
////////////////////////////////////////////////////////////////////////////////




inline BOOL WDBezierSegmentIsStraight(WDBezierSegment segment)
{
return WDCollinear(segment.a_, segment.out_, segment.b_) &&
	   WDCollinear(segment.a_, segment.in_,  segment.b_);
}


static CGPoint      *vertices = NULL;
static NSUInteger   size = 128;

float firstDerivative(float A, float B, float C, float D, float t);
float secondDerivative(float A, float B, float C, float D, float t);
float base3(double t, double p1, double p2, double p3, double p4);
float cubicF(double t, WDBezierSegment seg);



inline float firstDerivative(float A, float B, float C, float D, float t)
{
return -3*A*(1-t)*(1-t) + 3*B*(1-t)*(1-t) - 6*B*(1-t)*t + 6*C*(1-t)*t - 3*C*t*t + 3*D*t*t;
}

inline  float secondDerivative(float A, float B, float C, float D, float t)
{
return 6*A*(1-t) - 12*B*(1-t) + 6*C*(1-t) + 6*B*t - 12*C*t + 6*D*t;
}

inline float WDBezierSegmentCurvatureAtT(WDBezierSegment seg, float t)
{
if (WDBezierSegmentIsStraight(seg)) {
	return 0.0f;
}

float xPrime = firstDerivative(seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x, t);
float yPrime = firstDerivative(seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y, t);

float xPrime2 = secondDerivative(seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x, t);
float yPrime2 = secondDerivative(seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y, t);

float num = xPrime * yPrime2 - yPrime * xPrime2;
float denom =  pow(xPrime * xPrime + yPrime * yPrime, 3.0f / 2);

return -num/denom;
}

/*
* WDBezierSegmentFindPointOnSegment_R()
*
* Performs a binary search on the path, subdividing it until a
* sufficiently small section is found that contains the test point.
*/
BOOL WDBezierSegmentFindPointOnSegment_R(
WDBezierSegment seg,
CGPoint testPoint,
float tolerance,
CGPoint *nearestPoint,
float *split,
double depth)
{
CGRect  bbox = CGRectInset(WDBezierSegmentGetControlBounds(seg), -tolerance / 2, -tolerance / 2);

if (!CGRectContainsPoint(bbox, testPoint)) {
	return NO;
} else if (WDBezierSegmentIsStraight(seg)) {
	CGPoint s = WDSubtractPoints(seg.b_, seg.a_);
	CGPoint v = WDSubtractPoints(testPoint, seg.a_);
	float   n = v.x * s.x + v.y * s.y;
	float   d = s.x * s.x + s.y * s.y;
	float   t = n/d;
	BOOL    onSegment = NO;
	
	if (0.0f <= t && t <= 1.0f) {
		CGPoint delta = WDSubtractPoints(seg.b_, seg.a_);
		CGPoint p = WDAddPoints(seg.a_, WDMultiplyPointScalar(delta, t));
		
		if (WDDistance(p, testPoint) < tolerance) {
			if (nearestPoint) {
				*nearestPoint = p;
			}
			if (split) {
				*split += (t * depth);
			}
			onSegment = YES;
		}
	}
	
	return onSegment;
} else if((CGRectGetWidth(bbox) < tolerance * 1.1) || (CGRectGetHeight(bbox) < tolerance * 1.1)) {
	// Close enough! This should be more or less a straight line now...
	CGPoint s = WDSubtractPoints(seg.b_, seg.a_);
	CGPoint v = WDSubtractPoints(testPoint, seg.a_);
	float n = v.x * s.x + v.y * s.y;
	float d = s.x * s.x + s.y * s.y;
	float t = WDClamp(0.0f, 1.0f, n/d);

	if (nearestPoint) {
		// make sure the found point is on the path and not just near it
		*nearestPoint = WDBezierSegmentSplitAtT(seg, NULL, NULL, t);
	}
	if (split) {
		*split += (t * depth);
	}
	
	return YES;
}

// We know the point is inside our bounding box, but our bounding box is not yet
// small enough to consider it a hit. So, subdivide the path and recurse...

WDBezierSegment L, R;
BOOL            foundLeft = NO, foundRight = NO;
CGPoint         nearestLeftPoint, nearestRightPoint;
float           leftSplit = 0.0f, rightSplit = 0.0f;

WDBezierSegmentSplitAtT(seg, &L, &R, 0.5);

// look both ways before crossing
if (WDBezierSegmentFindPointOnSegment_R(L, testPoint, tolerance, &nearestLeftPoint, &leftSplit, depth / 2.0f)) {
	foundLeft = YES;
}
if (WDBezierSegmentFindPointOnSegment_R(R, testPoint, tolerance, &nearestRightPoint, &rightSplit, depth / 2.0f)) {
	foundRight = YES;
}

if (foundLeft && foundRight) {
	// since both halves found the point, choose the one that's actually closest
	float leftDistance = WDDistance(nearestLeftPoint, testPoint);
	float rightDistance = WDDistance(nearestRightPoint, testPoint);
	
	foundLeft = (leftDistance <= rightDistance) ? YES : NO;
	foundRight = !foundLeft;
}

if (foundLeft) {
	if (nearestPoint) {
		*nearestPoint = nearestLeftPoint;
	}
	if (split) {
		*split += leftSplit;
	}
} else if (foundRight) {
	if (nearestPoint) {
		*nearestPoint = nearestRightPoint;
	}
	if (split) {
		*split += 0.5 * depth + rightSplit;
	}
}

return (foundLeft || foundRight);
}

BOOL WDBezierSegmentFindPointOnSegment(WDBezierSegment seg, CGPoint testPoint, float tolerance, CGPoint *nearestPoint, float *split)
{
if (split) {
	*split = 0.0f;
}

return WDBezierSegmentFindPointOnSegment_R(seg, testPoint, tolerance, nearestPoint, split, 1.0);
}

CGPoint WDBezierSegmentPointAndTangentAtDistance(WDBezierSegment seg, float distance, CGPoint *tangent, float *curvature)
{
if (WDBezierSegmentIsStraight(seg)) {
	float t = distance / WDDistance(seg.a_, seg.b_);
	CGPoint point = WDMultiplyPointScalar(WDSubtractPoints(seg.b_, seg.a_), t);
	point = WDAddPoints(seg.a_, point);
	
	if (tangent) {
		*tangent = WDBezierSegmentTangentAtT(seg, t);
	}
	
	if (curvature) {
		*curvature = 0.0;
	}
	return WDBezierSegmentSplitAtT(seg, NULL, NULL, t);
}

CGPoint     current, last = seg.a_;
float       delta = 1.0f / 200.0f;
float       step, progress = 0;

for (float t = 0; t < (1.0f + delta); t += delta) {
	current = WDBezierSegmentPointAtT(seg, t);
	step = WDDistance(last, current);
	
	if (progress + step >= distance) {
		// it's between the current and last set of points          
		float factor = (distance - progress) / step;
		t = (t - delta) + factor * delta;
		
		if (tangent) {
			*tangent = WDBezierSegmentTangentAtT(seg, t);
		}
		
		if (curvature) {
			*curvature = WDBezierSegmentCurvatureAtT(seg, t);
		}
		
		return WDBezierSegmentSplitAtT(seg, NULL, NULL, t);
	}
	
	progress += step;
	last = current;
}

return CGPointZero;
}

void WDBezierSegmentFlatten(WDBezierSegment seg, CGPoint **vertices, NSUInteger *size, NSUInteger *index)
{
if (*size < *index + 4) {
	*size *= 2;
	*vertices = realloc(*vertices, sizeof(CGPoint) * *size);
}

if (WDBezierSegmentIsFlat(seg, kDefaultFlatness)) {
	if (*index == 0) {
		(*vertices)[*index] = seg.a_;
		*index += 1;
	}
	
	(*vertices)[*index] = seg.b_;
	*index += 1;
} else {
	WDBezierSegment L, R;
	WDBezierSegmentSplitAtT(seg, &L, &R, 0.5);
	
	WDBezierSegmentFlatten(L, vertices, size, index);
	WDBezierSegmentFlatten(R, vertices, size, index);
}
}

CGRect WDBezierSegmentBounds(WDBezierSegment seg)
{
NSUInteger  index = 0;

if (!vertices) {
	vertices = calloc(sizeof(CGPoint), size);
}

WDBezierSegmentFlatten(seg, &vertices, &size, &index);

float   minX, maxX, minY, maxY;

minX = maxX = vertices[0].x;
minY = maxY = vertices[0].y;

for (int i = 1; i < index; i++) {
	minX = MIN(minX, vertices[i].x);
	maxX = MAX(maxX, vertices[i].x);
	minY = MIN(minY, vertices[i].y);
	maxY = MAX(maxY, vertices[i].y);
}

return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

float base3(double t, double p1, double p2, double p3, double p4)
{
float t1 = -3*p1 + 9*p2 - 9*p3 + 3*p4;
float t2 = t*t1 + 6*p1 - 12*p2 + 6*p3;
return t*t2 - 3*p1 + 3*p2;
}

float cubicF(double t, WDBezierSegment seg)
{
float xbase = base3(t, seg.a_.x, seg.out_.x, seg.in_.x, seg.b_.x);
float ybase = base3(t, seg.a_.y, seg.out_.y, seg.in_.y, seg.b_.y);
float combined = xbase*xbase + ybase*ybase;
return sqrt(combined);
}

/**
* Gauss quadrature for cubic Bezier curves
* http://processingjs.nihongoresources.com/bezierinfo/
*
*/
float WDBezierSegmentLength(WDBezierSegment seg)
{
if (WDBezierSegmentIsStraight(seg)) {
	return WDDistance(seg.a_, seg.b_);
}

float  z = 1.0f;
float  z2 = z / 2.0f;
float  sum = 0.0f;

// Legendre-Gauss abscissae (xi values, defined at i=n as the roots of the nth order Legendre polynomial Pn(x))
static float Tvalues[] = {
	-0.06405689286260562997910028570913709, 0.06405689286260562997910028570913709,
	-0.19111886747361631067043674647720763, 0.19111886747361631067043674647720763,
	-0.31504267969616339684080230654217302, 0.31504267969616339684080230654217302,
	-0.43379350762604512725673089335032273, 0.43379350762604512725673089335032273,
	-0.54542147138883956269950203932239674, 0.54542147138883956269950203932239674,
	-0.64809365193697554552443307329667732, 0.64809365193697554552443307329667732,
	-0.74012419157855435791759646235732361, 0.74012419157855435791759646235732361,
	-0.82000198597390294708020519465208053, 0.82000198597390294708020519465208053,
	-0.88641552700440107148693869021371938, 0.88641552700440107148693869021371938,
	-0.93827455200273279789513480864115990, 0.93827455200273279789513480864115990,
	-0.97472855597130947380435372906504198, 0.97472855597130947380435372906504198,
	-0.99518721999702131064680088456952944, 0.99518721999702131064680088456952944
};

// Legendre-Gauss weights (wi values, defined by a function linked to in the Bezier primer article)
static float Cvalues[] = {
	0.12793819534675215932040259758650790, 0.12793819534675215932040259758650790,
	0.12583745634682830250028473528800532, 0.12583745634682830250028473528800532,
	0.12167047292780339140527701147220795, 0.12167047292780339140527701147220795,
	0.11550566805372559919806718653489951, 0.11550566805372559919806718653489951,
	0.10744427011596563437123563744535204, 0.10744427011596563437123563744535204,
	0.09761865210411388438238589060347294, 0.09761865210411388438238589060347294,
	0.08619016153195327434310968328645685, 0.08619016153195327434310968328645685, 
	0.07334648141108029983925575834291521, 0.07334648141108029983925575834291521,
	0.05929858491543678333801636881617014, 0.05929858491543678333801636881617014,
	0.04427743881741980774835454326421313, 0.04427743881741980774835454326421313,
	0.02853138862893366337059042336932179, 0.02853138862893366337059042336932179,
	0.01234122979998720018302016399047715, 0.01234122979998720018302016399047715
};

for (int i = 0; i < 24; i++) {
	float corrected_t = z2 * Tvalues[i] + z2;
	sum += Cvalues[i] * cubicF(corrected_t, seg);
}

return z2 * sum;
}

CGPoint WDBezierSegmentGetClosestPoint(WDBezierSegment seg, CGPoint test, float *error, float *distance)
{
float       delta = 0.001f;
float       sum = 0.0f;
float       smallestDistance = MAXFLOAT;
CGPoint     closest, current, last = seg.a_;

for (float t = 0; t < (1.0f + delta); t += delta) {
	current = WDBezierSegmentPointAtT(seg, t);
	sum += WDDistance(last, current);
	
	float testDistance = WDDistance(current, test);
	if (testDistance < smallestDistance) {
		smallestDistance = testDistance;
		*error = testDistance;
		*distance = sum;
		closest = current;
	}
	
	last = current;
}

return closest;
}


BOOL WDBezierSegmentGetIntersection(WDBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect)
{
if (!CGRectIntersectsRect(WDBezierSegmentGetControlBounds(seg), WDRectWithPoints(a, b))) {
	return NO;
}

float       r, delta = 0.01f;
CGPoint     current, last = seg.a_;

for (float t = 0; t < (1.0f + delta); t += delta) {
	current = WDBezierSegmentPointAtT(seg, t);

	if (WDLineSegmentsIntersectWithValues(last, current, a, b, &r, NULL)) {
		*tIntersect = WDClamp(0, 1, (t-delta) + delta * r);
		return YES;
	}

	last = current;
}

return NO;
}

BOOL WDBezierSegmentsFormCorner(WDBezierSegment a, WDBezierSegment b)
{
CGPoint p, q, r;

if (!CGPointEqualToPoint(a.b_, a.in_)) {
	p = a.in_;
} else {
	p = a.out_;
}

if (!CGPointEqualToPoint(b.a_, b.out_)) {
	r = b.out_;
} else {
	r = b.in_;
}
	
q = b.a_;

return !WDCollinear(p, q, r);    
}

float WDBezierSegmentOutAngle(WDBezierSegment seg)
{
CGPoint a;

if (!CGPointEqualToPoint(seg.b_, seg.in_)) {
	a = seg.in_;
} else {
	a = seg.out_;
}

CGPoint delta = WDSubtractPoints(seg.b_, a);

return atan2f(delta.y, delta.x);
}

BOOL WDBezierSegmentPointDistantFromPoint(WDBezierSegment seg, float distance, CGPoint pt, CGPoint *result, float *tResult)
{
CGPoint     current, last = seg.a_;
float       start = 0.0f, end = 1.0f, step = 0.1f;

for (float t = start; t < (end + step); t += step) {
	current = WDBezierSegmentPointAtT(seg, t);
	
	if (WDDistance(current, pt) >= distance) {
		start = (t - step); // back up one iteration
		end = t;

		// it's between the last and current point, let's get more precise
		step = 0.0001f;
		
		for (float t = start; t < (end + step); t += step) {
			current = WDBezierSegmentPointAtT(seg, t);
			
			if (WDDistance(current, pt) >= distance) {
				*tResult = t - (step / 2);
				*result = WDBezierSegmentPointAtT(seg, t);
				return YES;
			}
		}
	}
	
	last = current;
}

return NO;
}
