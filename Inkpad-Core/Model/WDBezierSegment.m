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
#pragma mark Utility functions
////////////////////////////////////////////////////////////////////////////////
/*
	CGPointInterpolate
	------------------
	Linear interpolation of points (from P1 to P2 with ratio r)
*/
static inline CGPoint CGPointInterpolate(CGPoint P1, CGPoint P2, CGFloat r)
{ return (CGPoint){ P1.x + r * (P2.x - P1.x), P1.y + r * (P2.y - P1.y) }; }

////////////////////////////////////////////////////////////////////////////////

static inline CGFloat CGPointDistanceToPoint(CGPoint P1, CGPoint P2)
{
	CGFloat dx = (P2.x-P1.x);
	CGFloat dy = (P2.y-P1.y);
	return sqrt(dx*dx+dy*dy);
}

////////////////////////////////////////////////////////////////////////////////

static inline CGPoint CGRectGetCenter(CGRect R)
{ return (CGPoint){ CGRectGetMidX(R), CGRectGetMidY(R) }; }

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
	return
	(CGRectGetMinX(R) <= P.x)&&(P.x <= CGRectGetMaxX(R))&&
	(CGRectGetMinY(R) <= P.y)&&(P.y <= CGRectGetMaxY(R));
}

////////////////////////////////////////////////////////////////////////////////
/*
	CGRectHoldsPoint
	----------------
	Determines if point is inside rectangle bounds
	
	Note that this is not equivalent to CGRectContainsPoint 
	which includes the near edges.
*/

static inline BOOL CGRectHoldsPoint(CGRect R, CGPoint P)
{
	return
	(CGRectGetMinX(R) < P.x)&&(P.x < CGRectGetMaxX(R))&&
	(CGRectGetMinY(R) < P.y)&&(P.y < CGRectGetMaxY(R));
}

////////////////////////////////////////////////////////////////////////////////
/*
	CGRectExpandToPoint
	-------------------
	Expand rectangle to include point
*/

static inline CGRect CGRectExpandToPoint(CGRect R, CGPoint P)
{
	CGFloat minX = R.origin.x;
	CGFloat minY = R.origin.y;
	CGFloat maxX = R.origin.x+R.size.width;
	CGFloat maxY = R.origin.y+R.size.height;

	if (P.x < minX)
	{ R.size.width = maxX - P.x; R.origin.x = P.x; }
	else
	if (P.x > maxX)
	{ R.size.width = P.x - minX; }

	if (P.y < minY)
	{ R.size.height = maxY - P.y; R.origin.y = P.y; }
	else
	if (P.y > maxY)
	{ R.size.height = P.y - minY; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

WDRange WDRangeUnion(WDRange a, WDRange b)
{ return (WDRange){ MIN(a.min,b.min), MAX(a.max,b.max) }; }

////////////////////////////////////////////////////////////////////////////////
/*
	WDLineBounds
	------------
	Compute normalized bounds encompassing line endpoints
	
	Will return a valid, empty rectangle for hor or ver line.
	CGRectIntersectsRect can return YES for such rectangles, i.e.:

	CGRect T1 = { 0, 0, 1, 0 };
	CGRect T2 = { 0, 0, 1, 1 };
	BOOL T = CGRectIntersectsRect(T1, T2);
	
	T will be YES...
*/

CGRect WDLineBounds(CGPoint p1, CGPoint p2)
{
	// Fetch bounds
	CGFloat x = p1.x;
	CGFloat y = p1.y;
	CGFloat w = p2.x - x;
	CGFloat h = p2.y - y;

	// Reverse parameters if necessary
	if (w < 0.0) { x += w; w = -w; }
	if (h < 0.0) { y += h; h = -h; }

	// Return CGRect
	return (CGRect){ x, y, w, h };
}

////////////////////////////////////////////////////////////////////////////////

CGPoint WDLineCenter(CGPoint a, CGPoint b)
{ return (CGPoint){ 0.5*(a.x+b.x), 0.5*(a.y+b.y) }; }

////////////////////////////////////////////////////////////////////////////////

CGFloat WDLineLength(CGPoint a, CGPoint b)
{ return CGPointDistanceToPoint(a, b); }

////////////////////////////////////////////////////////////////////////////////

WDRange WDLineRangeX(CGPoint a, CGPoint b)
{ return a.x <= b.x ? (WDRange){a.x,b.x} : (WDRange){b.x,a.x}; }

WDRange WDLineRangeY(CGPoint a, CGPoint b)
{ return a.y <= b.y ? (WDRange){a.y,b.y} : (WDRange){b.y,a.y}; }

////////////////////////////////////////////////////////////////////////////////

BOOL WDLineBoundsIntersectRect(CGPoint a, CGPoint b, CGRect R)
{
	WDRange X = WDLineRangeX(a, b);
	if (X.max <= CGRectGetMinX(R)) return NO;
	if (X.min >= CGRectGetMaxX(R)) return NO;
	WDRange Y = WDLineRangeY(a, b);
	if (Y.max <= CGRectGetMinY(R)) return NO;
	if (Y.min >= CGRectGetMaxY(R)) return NO;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDLineIntersectsRect(CGPoint a, CGPoint b, CGRect R)
{
	// Test end points
	if (CGRectHoldsPoint(R, a)||
		CGRectHoldsPoint(R, b))
		return YES;

	if (WDLineBoundsIntersectRect(a, b, R))
	{
		// Split half way
		CGPoint m = WDLineCenter(a, b);

		return
		WDLineIntersectsRect(a, m, R)||
		WDLineIntersectsRect(m, b, R);
	}

	return NO;
}

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
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIsLineSegment
	----------------------------
	Test whether segment represents a line between endpoints
	
	Technically a bezier segment is a line if controlpoints are colinear,
	but that includes cases where controlpoints extend past the endpoints, 
	and where t can traverse nonlinearly along the line.
*/

BOOL WDBezierSegmentIsLineSegment(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return
	(P[0].x == P[1].x)&&
	(P[0].y == P[1].y)&&
	(P[2].x == P[3].x)&&
	(P[2].y == P[3].y);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIsCollinear
	--------------------------
	Test whether segment renders as an uncurved line
	(but possibly extends beyond endpoints)
	
	Note the order of points tested: 
	p0, p1, p3 && 
	p0, p2, p3 would fail if p0 == p3
*/

BOOL WDBezierSegmentIsCollinear(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return
	WDCollinear(P[0], P[1], P[2])&&
	WDCollinear(P[1], P[2], P[3]);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIsContained
	--------------------------
	Test whether segment controlpoints fall within (or on the edge of) 
	the rectangle defined by endpoints
	
	If a segment is contained, it is also guaranteed to be a slope, i.e. 
	it doesn't have local min or max values.
*/

BOOL WDBezierSegmentIsContained(WDBezierSegment S)
{
	CGRect R = WDLineBounds(S.a_, S.b_);
	return
	CGRectIncludesPoint(R, S.out_)&&
	CGRectIncludesPoint(R, S.in_);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentIsLineSegmentShape
	---------------------------------
	Test whether segment renders like a straight line between endpoints
*/

BOOL WDBezierSegmentIsLineSegmentShape(WDBezierSegment S)
{
	return
	WDBezierSegmentIsCollinear(S)&&
	WDBezierSegmentIsContained(S);
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

const CGFloat kDefaultFlatness = 1.5; // 1.5 pixels both ways = 3

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
#pragma mark Bounds
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

static inline WDRange _BezierRange(double P0, double P1, double P2, double P3)
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
				if (min > v) min = v; else
				if (max < v) max = v;
			}

			// Compute root 2
			t = C / (A*t);
			if ((0.0<t)&&(t<1.0))
			{
				v = ((a*t + b)*t + c)*t + d;
				// Update min & max
				if (min > v) min = v; else
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
			if (min > v) min = v; else
			if (max < v) max = v;
		}
	}

	return (WDRange){ min, max };
}

////////////////////////////////////////////////////////////////////////////////

WDRange WDBezierSegmentRangeX(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return _BezierRange(P[0].x, P[1].x, P[2].x, P[3].x);
}

////////////////////////////////////////////////////////////////////////////////

WDRange WDBezierSegmentRangeY(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return _BezierRange(P[0].y, P[1].y, P[2].y, P[3].y);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentCurveBounds
	--------------------------
	Compute smallest rectangle encompassing curve described by segment.
*/

CGRect WDBezierSegmentCurveBounds(WDBezierSegment S)
{
	WDRange X = WDBezierSegmentRangeX(S);
	WDRange Y = WDBezierSegmentRangeY(S);
	return (CGRect){X.min, Y.min, X.max-X.min, Y.max-Y.min};
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentControlBounds
	----------------------------
	Compute smallest rectangle encompassing all 4 points in segment.
	
	This rectangle is guaranteed to also encompass the curve, 
	but might be larger than CurveBounds.
*/

CGRect WDBezierSegmentControlBounds(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;

	WDRange X = WDRangeUnion(
	WDLineRangeX(P[0], P[1]),
	WDLineRangeX(P[2], P[3]));

	WDRange Y = WDRangeUnion(
	WDLineRangeY(P[0], P[1]),
	WDLineRangeY(P[2], P[3]));

	return (CGRect){ X.min, Y.min, X.max-X.min, Y.max-Y.min };
}

////////////////////////////////////////////////////////////////////////////////

CGPoint WDBezierSegmentControlBoundsCenter(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return (CGPoint){
	0.25*(P[0].x+P[1].x+P[2].x+P[3].x),
	0.25*(P[0].y+P[1].y+P[2].y+P[3].y) };
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentControlStripLength
	---------------------------------
	Compute length of control strip (linestrip between segment points)
	
	This length is guaranteed to be larger than actual curve length,
	and the difference diminishes with splitting.

*/

CGFloat WDBezierSegmentControlStripLength(WDBezierSegment S)
{
	const CGPoint *P = &S.a_;
	return
	WDLineLength(P[0], P[1])+
	WDLineLength(P[1], P[2])+
	WDLineLength(P[2], P[3]);
}

////////////////////////////////////////////////////////////////////////////////

CGFloat WDBezierSegmentLineSegmentLength(WDBezierSegment S)
{ return WDLineLength(S.a_, S.b_); }

////////////////////////////////////////////////////////////////////////////////

BOOL WDBezierSegmentCurveBoundsIntersectsRect(WDBezierSegment S, CGRect R)
{
	WDRange X = WDBezierSegmentRangeX(S);
	if (X.max <= CGRectGetMinX(R)) return NO;
	if (X.min >= CGRectGetMaxX(R)) return NO;
	WDRange Y = WDBezierSegmentRangeY(S);
	if (Y.max <= CGRectGetMinY(R)) return NO;
	if (Y.min >= CGRectGetMaxY(R)) return NO;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDBezierSegmentControlBoundsIntersectsRect(WDBezierSegment S, CGRect R)
{
	const CGPoint *P = &S.a_;
	return
	CGRectHoldsPoint(R, P[0])&&
	CGRectHoldsPoint(R, P[1])&&
	CGRectHoldsPoint(R, P[2])&&
	CGRectHoldsPoint(R, P[3]);
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

BOOL WDBezierSegmentCurveIntersectsRect(WDBezierSegment S, CGRect R)
{
	// If either of the end points is inside R, then the curve intersects
	if (CGRectHoldsPoint(R, S.b_)||
		CGRectHoldsPoint(R, S.a_))
		return YES;

	// If curvebounds still intersects with rect, then continue recursively
	if (WDBezierSegmentCurveBoundsIntersectsRect(S, R))
	{
		WDBezierSegment Sn;
		WDBezierSegmentSplit(S, &S, &Sn);

		return
		WDBezierSegmentCurveIntersectsRect(Sn, R)||
		WDBezierSegmentCurveIntersectsRect(S, R);
	}

	return NO;
}

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

CGPoint WDBezierSegmentSplit
(WDBezierSegment S, WDBezierSegment *L, WDBezierSegment *R)
{
	const CGPoint *P = &S.a_;

	CGPoint A = WDLineCenter(P[0], P[1]);
	CGPoint B = WDLineCenter(P[1], P[2]);
	CGPoint C = WDLineCenter(P[2], P[3]);

	CGPoint D = WDLineCenter(A, B);
	CGPoint E = WDLineCenter(B, C);

	CGPoint F = WDLineCenter(D, E);

	*L = WDBezierSegmentMake(S.a_, A, D, F);
	*R = WDBezierSegmentMake(F, E, C, S.b_);
	return F;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Recursive Splitting
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentSplitWithBlock
	-----------------------------
	Split segment recursively while block returns YES
	(sub segments are guaranteed to pass in order from a_ to b_)

	Usage:

		__block localVar = ...

		WDBezierSegmentSplitWithBlock(S,
			^BOOL(WDBezierSegment subSegment)
			{
				1. Do something with subSegment and localVar
				2. return YES/NO depending on whether you want to continue
				splitting the subSegment
			});
	

	For more sophisticated control, see:
	WDBezierSegmentRangeSplitWithBlock
*/

void WDBezierSegmentSplitWithBlock(WDBezierSegment S,
					BOOL (^blockPtr)(WDBezierSegment))
{
	if (blockPtr(S))
	{
		WDBezierSegment Sn;
		WDBezierSegmentSplit(S, &S, &Sn);

		WDBezierSegmentSplitWithBlock(S, blockPtr);
		WDBezierSegmentSplitWithBlock(Sn, blockPtr);
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentRangeSplitWithBlock
	----------------------------------
	TODO: design customizable with WDSplitInfo 
	i.e. would like recursion break option
	
	typedef struct 
	{
		WDBezierSegment S;
		CGFloat t1;
		CGFloat t2;
		BOOL done;
	}
	WDSplitInfo;
	
	inline WDSplitInfoMakeWithSegment(WDBezierSegment S)
	{ return (WDSplitInfo){ S, 0.0, 1.0, NO }; }
	

*/

static const WDRange WDRangeDefault = { 0.0, 1.0 };

static inline WDRange WDRangeSplitL(WDRange r, CGFloat t)
{ return (WDRange){ r.min, r.min + t * (r.max - r.min) }; }

static inline WDRange WDRangeSplitR(WDRange r, CGFloat t)
{ return (WDRange){ r.min + t * (r.max - r.min), r.max }; }

void WDBezierSegmentRangeSplitWithBlock(WDBezierSegment S, WDRange range,
					CGFloat(^blockPtr)(WDBezierSegment,WDRange))
{
	CGFloat t = blockPtr(S, range);
	if (t != 0.0)
	{
		WDBezierSegment Sn;
		WDBezierSegmentSplitAtT(S, &S, &Sn, t);

		WDBezierSegmentRangeSplitWithBlock(S, WDRangeSplitL(range, t), blockPtr);
		WDBezierSegmentRangeSplitWithBlock(Sn, WDRangeSplitR(range, t), blockPtr);
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
WDSplitInfo WDBezierSegmentCustomSplitWithBlock(WDBezierSegment S, WDSplitInfo info,
					CGFloat(^blockPtr)(WDBezierSegment,WDSplitInfo*))
{
	CGFloat t = blockPtr(S, &info);
	if (t != 0.0)
	{
		WDBezierSegment Sn;
		WDBezierSegmentSplitAtT(S, &S, &Sn, t);

		info = WDBezierSegmentCustomSplitWithBlock(S, info, blockPtr);
		if (info.done) return info;
		info = WDBezierSegmentRangeSplitWithBlock(Sn, info, blockPtr);
		if (info.done) return info;
	}

	return info;
}
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentFindCurveBounds
	------------------------------
	Find curve bounds by recursion. 

	Primarily meant as an example for SplitWithBlock,
	WDBezierSegmentGetCurveBounds will compute bounds without recursion.
*/

CGRect WDBezierSegmentFindCurveBounds(WDBezierSegment S)
{
	__block CGRect R = { S.a_, {0,0}};

	WDBezierSegmentSplitWithBlock(S,
		^(WDBezierSegment subSegment)
		{
			// Splitting guarantees containment eventually
			// If not contained yet, split further
			if (!WDBezierSegmentIsContained(subSegment))
			{ return YES; }

			// Otherwise expand bounds
			R = CGRectExpandToPoint(R, subSegment.b_);

			// And stop splitting subSegment
			return NO;
		});

	return R;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentFindClosestPointOnSlope
	--------------------------------------
	If a segment is contained, it represents a slope and lacks 
	local minima/maxima. The closest point distance is therefore 
	unique and can be found with a binary search variant.
	
	1. Begin with start point minT = 0
	2. Compute distance for minT+d
	3. If distance is closer update minT = minT+d and repeat 2
	4. If not, reduce and invert d
	5. If d below precision stop, otherwise repeat 2
*/

WDFindInfo WDBezierSegmentFindClosestPointOnSlope(WDBezierSegment S, CGPoint P)
{
	CGFloat minT = 0.0;
	CGPoint minP = S.a_;
	CGFloat minD = WDLineLength(P, S.a_);

	CGFloat d = 0.5;

	do
	{
		CGFloat t = minT + d;
		if (t < 0.0) t = 0.0;
		if (t > 1.0) t = 1.0;

		CGPoint T = WDBezierSegmentPointAtT(S, t);
		CGFloat D = WDLineLength(P, T);
		if (D < minD)
		{
			minT = t;
			minP = T;
			minD = D;
		}
		else
		{ d = -0.5*d; }
	}
	while (fabs(d) > 0.0001);

	return (WDFindInfo)
	{ minT, minP, minD };
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentFindClosestPoint
	-------------------------------
	Find point on segment closest to targetpoint P
	
	Reply struct:

	typedef struct
	{
		CGFloat t; 	// t of resultpoint
		CGFloat D; 	// distance to targetpoint
		CGPoint P; 	// resultpoint
	}
	WDFindInfo;
*/

WDFindInfo WDBezierSegmentFindClosestPoint(WDBezierSegment S, CGPoint P)
{
	// Initialize reply
	__block WDFindInfo minInfo =
	{ 0.0, S.a_, WDLineLength(P, S.a_) };

	// Start recursive search
	WDBezierSegmentRangeSplitWithBlock(S, WDRangeDefault,
		^CGFloat(WDBezierSegment subSegment, WDRange subRange)
		{
			// Subdivide until segment is contained
			if (!WDBezierSegmentIsContained(subSegment))
			{ return 0.5; }

			// Find closest point on slope
			WDFindInfo info =
			WDBezierSegmentFindClosestPointOnSlope(subSegment, P);

			// If shorter than previous, save range
			if (info.D < minInfo.D)
			{
				minInfo = info;
				minInfo.t = subRange.min + info.t*(subRange.max-subRange.min);
			}

			// Stop splitting
			return 0.0;
		});

	return minInfo;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegmentComputeLength
	----------------------------
	Compute segment length based on controlpoints of subsegments
	
	The return value is not the exact length, but a reasonable 
	approximation depending on precision and initial length
*/

CGFloat WDBezierSegmentComputeLength(WDBezierSegment S, CGFloat precision)
{
	// Initialize return value
	__block CGFloat length = 0.0;

	// True length <= Controlstrip length
	CGFloat maxL = WDBezierSegmentControlStripLength(S);
	if (maxL <= 0.0) return 0.0;

	// Compute precision scale
	CGFloat scale = precision ? 1.0/precision : 1.0;

	// Split recursively
	WDBezierSegmentSplitWithBlock(S,
		^(WDBezierSegment subSegment)
		{
			CGFloat L = WDBezierSegmentControlStripLength(subSegment);
			// Test for small enough subsegment
			if ((scale*L) < maxL)
			{
				// Add length
				length += L;
				// Stop splitting
				return NO;
			}
			// Split subsegment further
			return YES;
		});

	return length;
}

////////////////////////////////////////////////////////////////////////////////
/*
// TODO: test assumptions
	
	assumption: 
	the ratio of
	ControlStripLength of subSegment and
	ControlStripLength of all subSegments
	
	is equal to ratio of true curve lengths
*/
CGFloat WDBezierSegmentFindLengthRatio(WDBezierSegment *S, CGFloat r)
{
	CGFloat targetD = r * WDBezierSegmentControlStripLength(*S);
	if (targetD > 0.0)
	{
		double t1 = 0.0;
		double t2 = 1.0;

		do
		{
			double t = 0.5*(t1+t2);
			
			WDBezierSegment L, R;
			WDBezierSegmentSplitAtT(*S, &L, &R, t);

			double D = WDBezierSegmentControlStripLength(L);
			if (D < targetD)
				t1 = t;
			else
				t2 = t;
		}
		while((t2-t1)>0.0001);

		WDBezierSegmentSplitAtT(*S, S, nil, t2);
		return t2;
	}

	return 0.0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Curvature
////////////////////////////////////////////////////////////////////////////////

static inline double _Derivative1
(double P0, double P1, double P2, double P3, double t)
{
	// Compute cubic polynomial co-efficients
	//double d = P0;
	double c = 3*(P1-P0);
	double b = 3*(P2-P1) - c;
	double a = (P3-P0) - b - c;

	// Compute polynomial co-efficients for derivative
	double A = a+a+a;
	double B = b+b;
	double C = c;

	return (A*t+B)*t+C;
}

static inline double _Derivative2
(double P0, double P1, double P2, double P3, double t)
{
	// Compute cubic polynomial co-efficients
	//double d = P0;
	double c = 3*(P1-P0);
	double b = 3*(P2-P1) - c;
	double a = (P3-P0) - b - c;

	// Compute polynomial co-efficients for derivative
	double A = a+a+a;
	double B = b+b;

	return 2*A*t+B;
}

CGPoint WDBezierSegmentDerivativeAtT(WDBezierSegment S, CGFloat t)
{
	const CGPoint *P = &S.a_;
	return (CGPoint){
		_Derivative1(P[0].x, P[1].x, P[2].x, P[3].x, t),
		_Derivative1(P[0].y, P[1].y, P[2].y, P[3].y, t) };
}

CGPoint WDBezierSegmentSecondDerivativeAtT(WDBezierSegment S, CGFloat t)
{
	const CGPoint *P = &S.a_;
	return (CGPoint){
		_Derivative2(P[0].x, P[1].x, P[2].x, P[3].x, t),
		_Derivative2(P[0].y, P[1].y, P[2].y, P[3].y, t) };
}

////////////////////////////////////////////////////////////////////////////////

double WDBezierSegmentCurvatureAtT(WDBezierSegment S, CGFloat t)
{
	CGPoint D1 = WDBezierSegmentDerivativeAtT(S, t);
	double D = D1.x*D1.x + D1.y*D1.y;
	if (D > 0.0)
	{
		CGPoint D2 = WDBezierSegmentSecondDerivativeAtT(S, t);
		double N = D1.x * D2.y - D1.y * D2.x;

		return -N / pow(D, 1.5);
	}

	return 0.0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////


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
	CGRect  bbox = CGRectInset(WDBezierSegmentControlBounds(seg), -tolerance / 2, -tolerance / 2);

	if (!CGRectContainsPoint(bbox, testPoint))
		return NO;
	else
	if (WDBezierSegmentIsLineSegmentShape(seg))
	{
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
	}
	else
	if((CGRectGetWidth(bbox) < tolerance * 1.1) ||
		(CGRectGetHeight(bbox) < tolerance * 1.1))
	{
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

BOOL WDBezierSegmentFindPointOnSegment(
	WDBezierSegment seg,
	CGPoint testPoint,
	float tolerance,
	CGPoint *nearestPoint, float *split)
{
//	CGPoint P = WDBezierSegmentFindClosestPoint(seg, testPoint);

//	if (P.x != P.y){ P.x = 0.0; }

if (split) {
	*split = 0.0f;
}

return WDBezierSegmentFindPointOnSegment_R(seg, testPoint, tolerance, nearestPoint, split, 1.0);
}

CGPoint WDBezierSegmentPointAndTangentAtDistance(WDBezierSegment seg, float distance, CGPoint *tangent, float *curvature)
{
if (WDBezierSegmentIsLineSegment(seg)) {
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


float _WDBezierSegmentLength(WDBezierSegment seg)
{
//if (WDBezierSegmentIsStraight(seg)) {
//	return WDDistance(seg.a_, seg.b_);
//}

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



float WDBezierSegmentLength(WDBezierSegment S)
{
	return _WDBezierSegmentLength(S);
	return WDBezierSegmentControlStripLength(S);
}



//*
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
//*/

BOOL WDBezierSegmentGetIntersection(WDBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect)
{
if (!CGRectIntersectsRect(WDBezierSegmentControlBounds(seg), WDRectWithPoints(a, b))) {
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
