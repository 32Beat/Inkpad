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
// Test whether segment points are collinear

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

CGRect WDBezierSegmentGetCurveBounds(WDBezierSegment S);
CGRect WDBezierSegmentGetControlBounds(WDBezierSegment seg);
CGPoint WDBezierSegmentGetControlBoundsCenter(WDBezierSegment S);
CGFloat WDBezierSegmentGetDiminishingLength(WDBezierSegment S);

////////////////////////////////////////////////////////////////////////////////
// Bezier

inline CGPoint WDBezierSegmentPointAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentTangentAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentSplitAtT(WDBezierSegment S,
										WDBezierSegment *L,
										WDBezierSegment *R, CGFloat t);

////////////////////////////////////////////////////////////////////////////////
// Recursion

void WDBezierSegmentSplitWithBlock(WDBezierSegment S, \
					BOOL (^blockPtr)(WDBezierSegment));
void WDBezierSegmentRangeSplitWithBlock(WDBezierSegment S, CGPoint range, \
					CGFloat (^blockPtr)(WDBezierSegment, CGPoint));

////////////////////////////////////////////////////////////////////////////////

CGRect WDBezierSegmentFindCurveBounds(WDBezierSegment S);
// Same as WDBezierSegmentGetCurveBounds except it uses recursive search

BOOL WDBezierSegmentIntersectsRect(WDBezierSegment seg, CGRect rect);
BOOL WDLineIntersectsRect(CGPoint a, CGPoint b, CGRect R);

//CGFloat WDBezierSegmentGetFlattenedLength(WDBezierSegment S);
CGPoint WDBezierSegmentFindClosestPoint(WDBezierSegment S, CGPoint P);


BOOL WDBezierSegmentFindPointOnSegment(
	WDBezierSegment seg,
	CGPoint testPoint,
	float tolerance,
	CGPoint *nearestPoint,
	float *split);


//CGRect WDBezierSegmentBounds(WDBezierSegment seg);
//CGRect WDBezierSegmentGetSimpleBounds(WDBezierSegment seg);

float WDBezierSegmentCurvatureAtT(WDBezierSegment seg, float t);
CGPoint WDBezierSegmentPointAndTangentAtDistance(WDBezierSegment seg, float distance, CGPoint *tangent, float *curvature);
float WDBezierSegmentLength(WDBezierSegment seg);

CGPoint WDBezierSegmentGetClosestPoint(WDBezierSegment seg, CGPoint test, float *error, float *distance);
BOOL WDBezierSegmentsFormCorner(WDBezierSegment a, WDBezierSegment b);

BOOL WDBezierSegmentGetIntersection(WDBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect);

float WDBezierSegmentOutAngle(WDBezierSegment seg);
BOOL WDBezierSegmentPointDistantFromPoint(WDBezierSegment segment, float distance, CGPoint pt, CGPoint *result, float *t);






