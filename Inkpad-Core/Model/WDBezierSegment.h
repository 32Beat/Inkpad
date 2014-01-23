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
// Operations

inline CGPoint WDBezierSegmentPointAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentTangentAtT(WDBezierSegment S, CGFloat t);
inline CGPoint WDBezierSegmentSplitAtT(WDBezierSegment S,
										WDBezierSegment *L,
										WDBezierSegment *R, CGFloat t);

////////////////////////////////////////////////////////////////////////////////

extern const float kDefaultFlatness;

inline BOOL WDBezierSegmentIsFlat
(WDBezierSegment seg, CGFloat deviceTolerance);

////////////////////////////////////////////////////////////////////////////////

CGRect WDBezierSegmentGetCurveBounds(WDBezierSegment S);
CGRect WDBezierSegmentGetControlBounds(WDBezierSegment seg);

////////////////////////////////////////////////////////////////////////////////

BOOL WDBezierSegmentIntersectsRect(WDBezierSegment seg, CGRect rect);
BOOL WDLineIntersectsRect(CGPoint a, CGPoint b, CGRect R);

//BOOL WDLineInRect(CGPoint a, CGPoint b, CGRect test);

BOOL WDBezierSegmentIsStraight(WDBezierSegment segment);
BOOL WDBezierSegmentIsFlat(WDBezierSegment seg, float tolerance);
void WDBezierSegmentFlatten(WDBezierSegment seg, CGPoint **vertices, NSUInteger *size, NSUInteger *index);

BOOL WDBezierSegmentFindPointOnSegment(WDBezierSegment seg, CGPoint testPoint, float tolerance, CGPoint *nearestPoint, float *split);

CGRect WDBezierSegmentBounds(WDBezierSegment seg);
CGRect WDBezierSegmentGetSimpleBounds(WDBezierSegment seg);

float WDBezierSegmentCurvatureAtT(WDBezierSegment seg, float t);
CGPoint WDBezierSegmentPointAndTangentAtDistance(WDBezierSegment seg, float distance, CGPoint *tangent, float *curvature);
float WDBezierSegmentLength(WDBezierSegment seg);

CGPoint WDBezierSegmentGetClosestPoint(WDBezierSegment seg, CGPoint test, float *error, float *distance);
BOOL WDBezierSegmentsFormCorner(WDBezierSegment a, WDBezierSegment b);

BOOL WDBezierSegmentGetIntersection(WDBezierSegment seg, CGPoint a, CGPoint b, float *tIntersect);

float WDBezierSegmentOutAngle(WDBezierSegment seg);
BOOL WDBezierSegmentPointDistantFromPoint(WDBezierSegment segment, float distance, CGPoint pt, CGPoint *result, float *t);
