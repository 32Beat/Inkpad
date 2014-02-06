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

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat p = 0.0; // Curvature (1.0 = cardssuit shape, 0.0 = valentine shape)
	static const CGFloat c = 0.5 * kWDShapeCircleFactor;
	static const CGPoint P[] = {
	{ 0.0, -1.0}, { 0, +p*c}, { 0, +p*c}, // center bottom
	{+1.0, +0.5}, { 0, +c}, { 0, -c*2},
	{+0.5, +1.0}, { -c, 0}, { +c, 0},
	{ 0.0, +0.5}, { 0, +c}, { 0, +c}, // center top
	{-0.5, +1.0}, { -c, 0}, { +c, 0},
	{-1.0, +0.5}, { 0, -c*2}, { 0, +c}};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:6];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


