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
/*
	CGPathCreateWithOvalShapeInRect
	-------------------------------
	Similar to CGPathCreateWithEllipseInRect but uses 
	circlefactor with least deviation.
*/

CGPathRef CGPathCreateWithOvalShapeInRect(CGRect R)
{
	CGFloat px = 0.5*R.size.width;
	CGFloat py = 0.5*R.size.height;
	CGFloat cx = px * kWDShapeCircleFactor;
	CGFloat cy = py * kWDShapeCircleFactor;
	CGFloat mx = R.origin.x + px;
	CGFloat my = R.origin.y + py;

	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPathMoveToPoint(pathRef, nil, mx, my-py);
	CGPathAddCurveToPoint(pathRef, nil, mx+cx, my-py, mx+px, my-cy, mx+px, my);
	CGPathAddCurveToPoint(pathRef, nil, mx+px, my+cy, mx+cx, my+py, mx, my+py);
	CGPathAddCurveToPoint(pathRef, nil, mx-cx, my+py, mx-px, my+cy, mx-px, my);
	CGPathAddCurveToPoint(pathRef, nil, mx-px, my-cy, mx-cx, my-py, mx, my-py);
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


