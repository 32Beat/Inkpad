////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierSegment.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
#pragma align = packed 

typedef struct
{
	CGPoint a_;
	CGPoint out_;
	CGPoint in_;
	CGPoint b_;
}
WDBezierSegment;

#pragma align = reset
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
// Initializers

static inline WDBezierSegment
WDBezierSegmentMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d)
{ return (WDBezierSegment){ a, b, c, d }; }

inline WDBezierSegment
WDBezierSegmentMakeWithQuadPoints(CGPoint a, CGPoint b, CGPoint c);

// TODO: remove from this file
@class WDBezierNode;
inline WDBezierSegment
WDBezierSegmentMakeWithNodes(WDBezierNode *a, WDBezierNode *b);

////////////////////////////////////////////////////////////////////////////////

inline BOOL WDBezierSegmentIsLineSegment(WDBezierSegment S);
// Test whether segment represents a line between endpoints

inline BOOL WDBezierSegmentIsCollinear(WDBezierSegment S);
// Test whether segment points form a line

inline BOOL WDBezierSegmentIsContained(WDBezierSegment S);
// Test whether controlpoints fall within endpoints

inline BOOL WDBezierSegmentIsLineSegmentShape(WDBezierSegment S);
// Test whether segment is collinear and contained

////////////////////////////////////////////////////////////////////////////////

extern const CGFloat kDefaultFlatness;

inline BOOL WDBezierSegmentIsFlat
(WDBezierSegment S, CGFloat deviceTolerance);
// Test whether segment can be approximated by line between endpoints

////////////////////////////////////////////////////////////////////////////////

typedef struct
{
	CGFloat min;
	CGFloat max;
}
WDRange;

////////////////////////////////////////////////////////////////////////////////

WDRange WDBezierSegmentRangeX(WDBezierSegment S);
// Get range of x coordinates of curve

WDRange WDBezierSegmentRangeY(WDBezierSegment S);
// Get range of y coordinates of curve

CGRect WDBezierSegmentCurveBounds(WDBezierSegment S);
// Get bounds rectangle encompassing curve

CGRect WDBezierSegmentControlBounds(WDBezierSegment seg);
// Get bounds rectangle encompassing segment points

CGPoint WDBezierSegmentControlBoundsCenter(WDBezierSegment S);
// Get center of control bounds rectangle

CGFloat WDBezierSegmentControlStripLength(WDBezierSegment S);
// Compute length of control strip (linestrip between segment points)

CGFloat WDBezierSegmentLineSegmentLength(WDBezierSegment S);
// Compute length of line between endpoints

////////////////////////////////////////////////////////////////////////////////

BOOL WDBezierSegmentControlBoundsIntersectsRect(WDBezierSegment S, CGRect R);
// Test if control bounds intersects rect, edge exclusive

BOOL WDBezierSegmentCurveBoundsIntersectsRect(WDBezierSegment S, CGRect R);
// Test if curve bounds intersects rect, edge exclusive

BOOL WDBezierSegmentCurveIntersectsRect(WDBezierSegment S, CGRect rect);
// Test if curve intersects rect, edge exclusive

BOOL WDLineIntersectsRect(CGPoint a, CGPoint b, CGRect R);
// Currently required for WDImage...

////////////////////////////////////////////////////////////////////////////////
// Bezier

inline CGPoint WDBezierSegmentPointAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentTangentAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentSplitAtT(WDBezierSegment S,
										WDBezierSegment *L,
										WDBezierSegment *R, CGFloat t);
inline CGPoint WDBezierSegmentSplit
(WDBezierSegment S, WDBezierSegment *L, WDBezierSegment *R);

////////////////////////////////////////////////////////////////////////////////
// Recursion

void WDBezierSegmentSplitWithBlock(WDBezierSegment S, \
					BOOL (^blockPtr)(WDBezierSegment));
void WDBezierSegmentRangeSplitWithBlock(WDBezierSegment S, WDRange range, \
					CGFloat (^blockPtr)(WDBezierSegment, WDRange));

////////////////////////////////////////////////////////////////////////////////

CGRect WDBezierSegmentFindCurveBounds(WDBezierSegment S);
// Same as WDBezierSegmentCurveBounds except it uses recursive search

////////////////////////////////////////////////////////////////////////////////

typedef struct
{
	CGFloat t; 	// t of resultpoint
	CGPoint P; 	// resultpoint
	CGFloat D; 	// distance to targetpoint
}
WDFindInfo;


WDFindInfo WDBezierSegmentFindClosestPoint(WDBezierSegment S, CGPoint P);
////////////////////////////////////////////////////////////////////////////////


double WDBezierSegmentCurvatureAtT(WDBezierSegment S, CGFloat t);

BOOL WDBezierSegmentFindPointOnSegment(
	WDBezierSegment seg,
	CGPoint testPoint,
	float tolerance,
	CGPoint *nearestPoint,
	float *split);

CGPoint WDBezierSegmentGetClosestPoint
(WDBezierSegment seg, CGPoint test, float *error, float *distance);


CGPoint WDBezierSegmentPointAndTangentAtDistance
(WDBezierSegment seg, float distance, CGPoint *tangent, float *curvature);

float WDBezierSegmentLength(WDBezierSegment seg);


BOOL WDBezierSegmentsFormCorner
(WDBezierSegment a, WDBezierSegment b);

BOOL WDBezierSegmentGetIntersection
(WDBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect);

float WDBezierSegmentOutAngle(WDBezierSegment seg);
BOOL WDBezierSegmentPointDistantFromPoint
(WDBezierSegment segment, float distance, CGPoint pt, CGPoint *result, float *t);






