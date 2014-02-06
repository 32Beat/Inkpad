////////////////////////////////////////////////////////////////////////////////
/*
	WDSpadesShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDSpadesShape.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDSpadesShape
////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat cx = 0.5*kWDShapeCircleFactor;
	static const CGFloat cy = 0.4*kWDShapeCircleFactor;
	static const CGPoint P[] = {
	{ 0.5, -1.0}, { -cx, 0}, { 0, 0}, // right foot
	{ 0.01, -0.2}, { 0, -cy}, { 0, -2*cy},
	{ 0.5, -0.6}, { cx, 0}, { -cx, 0},
	{ 1.0, -0.2}, { 0, 2*cy}, { 0, -cy},
	{ 0.0, +1.0}, { 0, -cy}, { 0, -cy}, // top
	{-1.0, -0.2}, { 0, -cy}, { 0, 2*cy},
	{-0.5, -0.6}, { cx, 0}, { -cx, 0},
	{-0.01, -0.2}, { 0, -2*cy}, { 0, -cy},
	{-0.5, -1.0}, { 0, 0}, { cx, 0}
	};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:9];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


