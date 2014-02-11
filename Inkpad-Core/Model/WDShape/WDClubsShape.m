////////////////////////////////////////////////////////////////////////////////
/*
	WDClubsShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDClubsShape.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDClubsShape
////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat dx = 0.5;
	static const CGFloat dy = 0.4;
	static const CGFloat cx = dx*kWDShapeCircleFactor;
	static const CGFloat cy = dy*kWDShapeCircleFactor;
	static const CGFloat mc = kWDShapeCircleFactor/3.0;
	static const CGFloat mx = 0.5;
	static const CGFloat my = 0.5 * 1.732050807568877; //sqrt(3.0);

	CGPoint P[] = {
	{ 0.5, -1.0}, { 0, 0}, { 0, 0}, // right foot
	{ 0.5, -0.99}, { -cx, 0}, { 0, 0},
	{ 0.01, -0.2}, { 0, -cy}, { 0, -2*cy},
	{ 0.5, -0.2-dy}, { +cx, 0}, { -cx, 0},
	{ 0.5+dx, -0.2}, { 0, +cy}, { 0, -cy},
	{ 0.5, -0.2+dy}, { -mc*dx, 0}, { +cx, 0},
	{ 0.5-mx*dx, -0.2+my*dy}, { dx*my*mc*2, dy*mx*mc*2}, { dx*my*mc, dy*mx*mc},
	{ 0.0+dx, -0.2+dy*my*2 }, { 0, +cy}, { 0, -dy*mc*2},
	{ 0.0, -0.2+dy*my*2 + dy}, { -cx, 0}, { +cx, 0},
	{ 0.0-dx, -0.2+dy*my*2 }, { 0, -dy*mc*2}, { 0, +cy},
	{-0.5+mx*dx, -0.2+my*dy}, {-dx*my*mc, dy*mx*mc}, {-dx*my*mc*2, dy*mx*mc*2},
	{-0.5, -0.2+dy}, { -cx, 0}, { +mc*dx, 0},
	{-0.5-dx, -0.2}, { 0, -cy}, { 0, +cy},
	{-0.5, -0.2-dy}, { +cx, 0}, { -cx, 0},
	{-0.01, -0.2}, { 0, -2*cy}, { 0, -cy},
	{-0.5, -0.99}, { 0, 0}, { +cx, 0},
	{-0.5, -1.0}, { 0, 0}, { 0, 0}
	};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:17];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


