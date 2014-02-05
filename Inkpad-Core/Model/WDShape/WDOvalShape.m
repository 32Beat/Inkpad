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

CGPathRef CGPathCreateWithOvalShapeInRect(CGRect R)
{
	CGFloat px = 0.5*R.size.width;
	CGFloat py = 0.5*R.size.height;
	CGFloat cx = px * (1.0-kWDShapeCircleFactor);
	CGFloat cy = py * (1.0-kWDShapeCircleFactor);

	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPoint P = R.origin;
	CGPathMoveToPoint(pathRef, nil, P.x, P.y+py);
	CGPathAddCurveToPoint(pathRef, nil, P.x, P.y+cy, P.x+cx, P.y, P.x+px, P.y);

	P.x += R.size.width;
	CGPathAddCurveToPoint(pathRef, nil, P.x-cx, P.y, P.x, P.y+cy, P.x, P.y+py);

	P.y += R.size.height;
	CGPathAddCurveToPoint(pathRef, nil, P.x, P.y-cy, P.x-cx, P.y, P.x-px, P.y);

	P.x -= R.size.width;
	CGPathAddCurveToPoint(pathRef, nil, P.x+cx, P.y, P.x, P.y-cy, P.x, P.y-py);

	CGPathCloseSubpath(pathRef);

	return pathRef;
}

- (CGPathRef) createSourcePath
{ return CGPathCreateWithOvalShapeInRect([self sourceRect]); }



+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint P[] = {
	{ 0,+1}, {-c, 0}, {+c, 0},
	{-1, 0}, { 0,-c}, { 0,+c},
	{ 0,-1}, {+c, 0}, {-c, 0},
	{+1, 0}, { 0,+c}, { 0,-c}};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:4];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


