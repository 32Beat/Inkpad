////////////////////////////////////////////////////////////////////////////////
/*
	WDRectangleShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////


#import "WDRectangleShape.h"


////////////////////////////////////////////////////////////////////////////////
@implementation WDRectangleShape
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) shapeVersion
{ return 1; }

- (id) paramName
{ return @"Corner Radius"; } // TODO: localize

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGFloat W = CGRectGetWidth(R);
	CGFloat H = CGRectGetHeight(R);
	CGFloat maxRadius = 0.5 * MIN(W, H);

	CGFloat radius = maxRadius;
	if (0.0 <= mValue && mValue <= 1.0)
	{ radius *= mValue; }

	return (radius > 0.0) ?
	[self _bezierNodesWithRect:R cornerRadius:radius]:
	[self _bezierNodesWithRect:R];
}

////////////////////////////////////////////////////////////////////////////////

- (id) _bezierNodesWithRect:(CGRect)R
{
	CGPoint P0 = R.origin;
	CGPoint P1 = R.origin;
	CGPoint P2 = R.origin;
	CGPoint P3 = R.origin;

	P1.x += R.size.width;
	P2.x += R.size.width;
	P2.y += R.size.height;
	P3.y += R.size.height;

	return @[
	[WDBezierNode bezierNodeWithAnchorPoint:P0],
	[WDBezierNode bezierNodeWithAnchorPoint:P1],
	[WDBezierNode bezierNodeWithAnchorPoint:P2],
	[WDBezierNode bezierNodeWithAnchorPoint:P3]];
}

////////////////////////////////////////////////////////////////////////////////
/*
	CGRectGetCornerPoint
	--------------------
	Fetch cornerpoint in Mathematical order:
	0 = bottom left,
	1 = bottom right,
	2 = top left,
	3 = top right
*/

CGPoint CGRectGetCornerPoint(CGRect R, long index)
{
	if (index & 0x01) R.origin.x += R.size.width;
	if (index & 0x02) R.origin.y += R.size.height;
	return R.origin;
}

////////////////////////////////////////////////////////////////////////////////

static inline CGVector CGVectorScale(CGVector vector, CGFloat m)
{ return (CGVector){ m*vector.dx, m*vector.dy }; }

static inline CGPoint _PreparePoint(CGPoint a, CGVector b, CGFloat r)
{ return (CGPoint){ a.x+r*b.dx, a.y+r*b.dy }; }

- (id) _bezierNodesWithRect:(CGRect)R cornerRadius:(CGFloat)radius
{
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGVector D[] = {
	{ 0,+1}, { 0,-c}, { 0, 0},
	{+1, 0}, { 0, 0}, {-c, 0},
	{-1, 0}, {+c, 0}, { 0, 0},
	{ 0,+1}, { 0, 0}, { 0,-c},
	{ 0,-1}, { 0,+c}, { 0, 0},
	{-1, 0}, { 0, 0}, {+c, 0},
	{+1, 0}, {-c, 0}, { 0, 0},
	{ 0,-1}, { 0, 0}, { 0,+c}};

	static const CGVector cornerPoints[] =
	{{-1,-1},{+1,-1},{+1,+1},{-1,+1}};

	CGFloat mx = 0.5 * R.size.width;
	CGFloat my = 0.5 * R.size.height;
	CGPoint M = { R.origin.x + mx, R.origin.y + my };

	NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:8];

	for (int i=0; i!=4; i++)
	{
		CGPoint P = (CGPoint){
		M.x + mx * cornerPoints[i].dx,
		M.y + my * cornerPoints[i].dy };

		CGPoint A, B, C;
		A = _PreparePoint(P, D[6*i+0], radius);
		B = _PreparePoint(A, D[6*i+1], radius);
		C = _PreparePoint(A, D[6*i+2], radius);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

		A = _PreparePoint(P, D[6*i+3], radius);
		B = _PreparePoint(A, D[6*i+4], radius);
		C = _PreparePoint(A, D[6*i+5], radius);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
