////////////////////////////////////////////////////////////////////////////////
/*
	WDDiamondShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDDiamondShape.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDDiamondShape
////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithRect:(CGRect)R
{
	CGPoint M = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint P = { R.origin.x + M.x, R.origin.y + M.y };

	CGPoint P0 = { P.x, P.y+M.y };
	CGPoint P1 = { P.x-M.x, P.y };
	CGPoint P2 = { P.x, P.y-M.y };
	CGPoint P3 = { P.x+M.x, P.y };

	return @[
	[WDBezierNode bezierNodeWithAnchorPoint:P0],
	[WDBezierNode bezierNodeWithAnchorPoint:P1],
	[WDBezierNode bezierNodeWithAnchorPoint:P2],
	[WDBezierNode bezierNodeWithAnchorPoint:P3]];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


