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
/*
	Defines radius and tangent function for spirals
	
	The following tangent approximation works fine:
	return (spiralRadius(a+0.0001) - spiralRadius(a-0.0001)) / 0.0002;
*/

#define kB 0.30634896253003 // ln((1+sqrt(5))/2)/M_PI_2

double spiralRadius1(double a)
{ return exp(kB*a); }
double spiralTangent1(double a)
{ return exp(kB*a)*kB; }


double spiralRadius(double a, double m)
//{ return pow(1.6180339887499, a/M_PI_2); } // (1.0+sqrt(5.0))/2.0
{ return a / M_PI_2; }

double spiralTangent(double a, double m)
//{ return 1 / M_PI_2; }
{
	return (
	spiralRadius(a+0.0001, m) -
	spiralRadius(a-0.0001, m))/0.0002;
}


- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGPoint D = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint M = { R.origin.x + D.x, R.origin.y + D.y };

	NSMutableArray *nodes = [NSMutableArray array];

	// 81 anchors = origin + 10 rotations with 8 anchors
	long total = 2 + 8*3*mValue*mValue;

	double maxAngle = M_PI_4 * (total-1);
	double maxRadius = spiralRadius(maxAngle, mValue);
	D.x /= maxRadius;
	D.y /= maxRadius;

	for (long n=0; n!=total; n++)
	{
		CGPoint A, B, C;

		// Angle
		double a = n * M_PI_4;

		// Radius
		double f0 = spiralRadius(a, mValue);
		A.x = M.x + D.x * f0 * cos(a);
		A.y = M.y + D.y * f0 * sin(a);

		// Tangent
		double f1 = spiralTangent(a, mValue);
		double dx = D.x * (f1*cos(a) - f0*sin(a));
		double dy = D.y * (f0*cos(a) + f1*sin(a));

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

