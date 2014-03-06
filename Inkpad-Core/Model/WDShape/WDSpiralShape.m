////////////////////////////////////////////////////////////////////////////////
/*
	WDSpiralShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////


#import "WDSpiralShape.h"
#import "WDUtilities.h"


////////////////////////////////////////////////////////////////////////////////
@implementation WDSpiralShape
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) shapeVersion
{ return 1; }

- (id) paramName
{ return @"Decrease"; } // TODO: localize

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createSourcePath
{ return WDCreateCGPathRefWithNodes([self bezierNodes], NO); }

////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGPoint D = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint M = { R.origin.x + D.x, R.origin.y + D.y };

	NSMutableArray *nodes = [NSMutableArray array];

	long total = 2 + 199*mValue*mValue;

	double maxAngle = M_PI_4 * (total-1);
	D.x /= maxAngle;
	D.y /= maxAngle;

	for (long n=0; n!=total; n++)
	{
		CGPoint A, B, C;

		double a = n * M_PI_4;
		A.x = M.x + D.x * a * cos(a);
		A.y = M.y + D.y * a * sin(a);

		// Derivative
		double dx = D.x * (cos(a) - a * sin(a));
		double dy = D.y * (a * cos(a) + sin(a));
		// Handlesize
		dx *= (kWDShapeCircleFactor/2);
		dy *= (kWDShapeCircleFactor/2);

		B.x = A.x + dx;
		B.y = A.y + dy;
		C.x = A.x - dx;
		C.y = A.y - dy;

		[nodes addObject:
		[WDBezierNode bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////

