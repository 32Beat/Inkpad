////////////////////////////////////////////////////////////////////////////////
/*
	CGPathShapes.c
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#include "CGPathShapes.h"

////////////////////////////////////////////////////////////////////////////////
/*
	CGPathCreateWithRectangleShapeInRect
	------------------------------------
	Creates path for rectangle with rounded corners
	
	cornerRadius should be in the range = [0.0, 1.0] and is interpreted 
	relative to half the minimum size of rectangle's dimensions.
*/

CGPathRef CGPathCreateWithRectangleShapeInRect(CGRect R, CGFloat cornerRadius)
{
	// Compute absolute cornerRadius
	cornerRadius *= 0.5 * (R.size.width<R.size.height?R.size.width:R.size.height);
	// Define offsets relative to cornerpoints
	CGFloat p = cornerRadius;
	CGFloat c = cornerRadius * (1.0 - kCGPathShapesCircleFactor);

	// Start path
	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPoint P = R.origin;
	CGPathMoveToPoint(pathRef, nil, P.x, P.y+p);
	CGPathAddCurveToPoint(pathRef, nil, P.x, P.y+c, P.x+c, P.y, P.x+p, P.y);

	P.x += R.size.width;
	CGPathAddLineToPoint(pathRef, nil, P.x-p, P.y);
	CGPathAddCurveToPoint(pathRef, nil, P.x-c, P.y, P.x, P.y+c, P.x, P.y+p);

	P.y += R.size.height;
	CGPathAddLineToPoint(pathRef, nil, P.x, P.y-p);
	CGPathAddCurveToPoint(pathRef, nil, P.x, P.y-c, P.x-c, P.y, P.x-p, P.y);

	P.x -= R.size.width;
	CGPathAddLineToPoint(pathRef, nil, P.x+p, P.y);
	CGPathAddCurveToPoint(pathRef, nil, P.x+c, P.y, P.x, P.y-c, P.x, P.y-p);

	CGPathCloseSubpath(pathRef);

	return pathRef;
}

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
	CGFloat cx = px * kCGPathShapesCircleFactor;
	CGFloat cy = py * kCGPathShapesCircleFactor;
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

////////////////////////////////////////////////////////////////////////////////

CGPathRef CGPathCreateWithLeafShapeInRect(CGRect R)
{
	CGFloat px = 0.5*R.size.width;
	CGFloat py = 0.5*R.size.height;
	//CGFloat cx = px * kCGPathShapesCircleFactor;
	CGFloat cy = py * kCGPathShapesCircleFactor;
	CGFloat mx = R.origin.x + px;
	CGFloat my = R.origin.y + py;

	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPathMoveToPoint(pathRef, nil, mx-px, my);
	CGPathAddCurveToPoint(pathRef, nil, mx-px, my-cy, mx, my-py, mx, my-py);
	CGPathAddCurveToPoint(pathRef, nil, mx, my-py, mx+px, my-cy, mx+px, my);
	CGPathAddCurveToPoint(pathRef, nil, mx+px, my+cy, mx, my+py, mx, my+py);
	CGPathAddCurveToPoint(pathRef, nil, mx, my+py, mx-px, my+cy, mx-px, my);
	CGPathCloseSubpath(pathRef);

	return pathRef;
}

////////////////////////////////////////////////////////////////////////////////
/*
	CGPathCreateWithDiamondShapeInRect
	----------------------------------
*/

CGPathRef CGPathCreateWithDiamondShapeInRect(CGRect R)
{
	CGFloat px = 0.5*R.size.width;
	CGFloat py = 0.5*R.size.height;
	CGFloat mx = R.origin.x + px;
	CGFloat my = R.origin.y + py;

	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPathMoveToPoint(pathRef, nil, mx, my+py);
	CGPathAddLineToPoint(pathRef, nil, mx-px, my);
	CGPathAddLineToPoint(pathRef, nil, mx, my-py);
	CGPathAddLineToPoint(pathRef, nil, mx+px, my);
	CGPathCloseSubpath(pathRef);

	return pathRef;
}

////////////////////////////////////////////////////////////////////////////////





