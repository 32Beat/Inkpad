////////////////////////////////////////////////////////////////////////////////
/*
	WDHeartShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDHeartShape.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDHeartShape
////////////////////////////////////////////////////////////////////////////////


+ (id) bezierNodesWithRect:(CGRect)R
{
	static const CGFloat p = 0.0; // Curvature (1.0 = cardssuit shape, 0.0 = valentine shape)
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint D[] = {
	{ 0.0,-1.0}, { 0, +p*c}, { 0, +p*c}, // center bottom
	{+1.0,+0.5}, { 0, +0.5*c}, { 0, -1.0*c},
	{+0.5,+1.0}, { -0.5*c, 0}, { +0.5*c, 0},
	{ 0.0,+0.5}, { 0, +0.5*c}, { 0, +0.5*c}, // center top
	{-0.5,+1.0}, { -0.5*c, 0}, { +0.5*c, 0},
	{-1.0,+0.5}, { 0, -1.0*c}, { 0, +0.5*c}};

	NSMutableArray *nodes = [NSMutableArray array];

	CGPoint M = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint P = { R.origin.x + M.x, R.origin.y + M.y };

	// TODO: implement better flip strategy 
	// Heart shape is not vertically symmetrical, need to flip for SVG
	M.y = -M.y;

	for (int i=0; i!=6; i++)
	{
		CGPoint A, B, C;
		A = WDAddPoints(P, WDMultiplyPoints(D[3*i+0], M));
		B = WDAddPoints(A, WDMultiplyPoints(D[3*i+1], M));
		C = WDAddPoints(A, WDMultiplyPoints(D[3*i+2], M));

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


