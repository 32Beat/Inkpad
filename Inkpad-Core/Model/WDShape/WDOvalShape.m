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

////////////////////////////////////////////////////////////////////////////////
@implementation WDOvalShape
////////////////////////////////////////////////////////////////////////////////
/*
	bezierNodesWithShapeInRect
	--------------------------
	Return an array of beziernodes that define the shape within rectangle R
	
	The routine here uses "normalized" points in the order
	
		anchorPoint, outPoint, inPoint,
	
	where anchorPoint should be defined within a rectangle that has its 
	lowerleft corner at (-1,-1) and upperright at (+1,+1), and the 
	controlpoints are defined as vectors relative to anchorpoint.
	
	bezierNodesWithShapeInRect:normalizedPoints:count: will create nodes 
	that are scaled and translated to R, as well as flipped for SVG.
*/

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint P[] = {
	{ 0, +1}, {-c,  0}, {+c,  0},
	{-1,  0}, { 0, -c}, { 0, +c},
	{ 0, -1}, {+c,  0}, {-c,  0},
	{+1,  0}, { 0, +c}, { 0, -c}};

	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:4];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


