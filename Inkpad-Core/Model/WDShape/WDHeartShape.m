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

////////////////////////////////////////////////////////////////////////////////
@implementation WDHeartShape
////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat p = 1.0; // Curvature (1.0 = cardssuit shape, 0.0 = valentine shape)
	static const CGFloat cx = 0.5 * kWDShapeCircleFactor;
	static const CGFloat cy = 0.4 * kWDShapeCircleFactor;
	static const CGFloat b = 0.4 * 1.732050807568877; //sqrt(3.0);
	static const CGPoint P[] = {
	{ 0.0, -0.2-b}, { 0, +p*cy}, { 0, +p*cy}, // center bottom
	{+1.0, +0.6}, { 0, +cy}, { 0, -cy*2},
	{+0.5, +1.0}, { -cx, 0}, { +cx, 0},
	{ 0.0, +0.6}, { 0, +cy}, { 0, +cy}, // center top
	{-0.5, +1.0}, { -cx, 0}, { +cx, 0},
	{-1.0, +0.6}, { 0, -cy*2}, { 0, +cy}};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:6];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


