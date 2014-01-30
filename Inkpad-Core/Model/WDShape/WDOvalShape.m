////////////////////////////////////////////////////////////////////////////////
/*
	WDOvalShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDOvalShape.h"
#import "WDBezierNode.h"
#import "WDUtilities.h"

static NSString *WDShapeTypeNameOval = @"WDShapeTypeOval";

////////////////////////////////////////////////////////////////////////////////
@implementation WDOvalShape
////////////////////////////////////////////////////////////////////////////////

- (NSString *) shapeTypeName
{
	return WDShapeTypeNameOval;
}

////////////////////////////////////////////////////////////////////////////////

static inline CGPoint _PreparePoint(CGPoint a, CGVector b, CGFloat r)
{ return (CGPoint){ a.x+r*b.dx, a.y+r*b.dy }; }

- (void) prepareNodes
{
	CGRect R = mBounds;
	CGFloat rx = 0.5*mBounds.size.width;
	CGFloat ry = 0.5*mBounds.size.height;

	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint D[] = {
	{ 0,+1}, {-c, 0}, {+c, 0},
	{-1, 0}, { 0,-c}, { 0,+c},
	{ 0,-1}, {+c, 0}, {-c, 0},
	{+1, 0}, { 0,+c}, { 0,-c}};

	CGPoint P = (CGPoint){ CGRectGetMidX(R), CGRectGetMidY(R) };
	CGPoint V = { rx, ry };

	for (int i=0; i!=4; i++)
	{
		CGPoint A, B, C;
		A = WDAddPoints(P, WDMultiplyPoints(D[3*i+0], V));
		B = WDAddPoints(A, WDMultiplyPoints(D[3*i+1], V));
		C = WDAddPoints(A, WDMultiplyPoints(D[3*i+2], V));

		[[self nodes] addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


