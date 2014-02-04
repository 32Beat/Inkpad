////////////////////////////////////////////////////////////////////////////////
/*
	WDPieShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDPieShape.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDPieShape
////////////////////////////////////////////////////////////////////////////////

- (id) paramName
{ return @"Chunk Size"; } // TODO: localize

- (int) paramVersion
{ return 1; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGPoint M = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint N = { R.origin.x + M.x, R.origin.y + M.y };
	CGPoint A, B, C;

	double t = mValue;
	double r = (1-t) * kWDShapeCircleFactor; // circlefactor length

	NSMutableArray *nodes = [NSMutableArray array];

	[nodes addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:N]];

	double a = t * M_PI;
	double da = 0.5 * (M_PI - a);
	for (long n=0; n!=5; n++)
	{
		double dx = cos(a);
		double dy = sin(a);
		a += da;

		A.x = N.x + M.x * dx;
		A.y = N.y + M.y * dy;

		B.x = A.x - M.x * dy * r * (n!=4);
		B.y = A.y + M.y * dx * r * (n!=4);

		C.x = A.x + M.x * dy * r * (n!=0);
		C.y = A.y - M.y * dx * r * (n!=0);

		[nodes addObject:
		[WDBezierNode bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////

