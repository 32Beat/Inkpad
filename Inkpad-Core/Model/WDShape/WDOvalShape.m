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
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDOvalShape
////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithRect:(CGRect)R
{
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint D[] = {
	{ 0,+1}, {-c, 0}, {+c, 0},
	{-1, 0}, { 0,-c}, { 0,+c},
	{ 0,-1}, {+c, 0}, {-c, 0},
	{+1, 0}, { 0,+c}, { 0,-c}};

	// Center point and radius vector
	CGPoint P = { CGRectGetMidX(R), CGRectGetMidY(R) };
	CGPoint V = { 0.5*R.size.width, 0.5*R.size.height };

	NSMutableArray *nodes = [NSMutableArray array];

	for (int i=0; i!=4; i++)
	{
		CGPoint A, B, C;
		A = WDAddPoints(P, WDMultiplyPoints(V, D[3*i+0]));
		B = WDAddPoints(A, WDMultiplyPoints(V, D[3*i+1]));
		C = WDAddPoints(A, WDMultiplyPoints(V, D[3*i+2]));

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


