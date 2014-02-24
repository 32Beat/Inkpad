//
//  WDUtilities.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#if TARGET_OS_MAC
#import <UIKit/UIKit.h>
#endif

#import "WDBezierNode.h"
#import "WDBezierSegment.h"
#import "WDPath.h"
#import "WDUtilities.h"
#include <CommonCrypto/CommonHMAC.h>



#define kMiterLimit 10

#pragma mark Color Conversion

void HSVtoRGB(float h, float s, float v, float *r, float *g, float *b)
{
	if (s == 0) {
		*r = *g = *b = v;
	} else {
		float   f,p,q,t;
		int     i;
		
		h *= 360;
		
		if (h == 360.0f) {
			h = 0.0f;
		}
		
		h /= 60;
		i = floor(h);
		
		f = h - i;
		p = v * (1.0 - s);
		q = v * (1.0 - (s*f));
		t = v * (1.0 - (s * (1.0 - f)));
		
		switch (i) {
			case 0: *r = v; *g = t; *b = p; break;
			case 1: *r = q; *g = v; *b = p; break;
			case 2: *r = p; *g = v; *b = t; break;
			case 3: *r = p; *g = q; *b = v; break;
			case 4: *r = t; *g = p; *b = v; break;
			case 5: *r = v; *g = p; *b = q; break;
		}
	}
}   

void RGBtoHSV(float r, float g, float b, float *h, float *s, float *v)
{
	float max = MAX(r, MAX(g, b));
	float min = MIN(r, MIN(g, b));
	float delta = max - min;
	
	*v = max;
	*s = (max != 0.0f) ? (delta / max) : 0.0f;
	
	if (*s == 0.0f) {
		*h = 0.0f;
	} else {
		if (r == max) {
			*h = (g - b) / delta;
		} else if (g == max) {
			*h = 2.0f + (b - r) / delta;
		} else if (b == max) {
			*h = 4.0f + (r - g) / delta;
		}
		
		*h *= 60.0f;
		
		if (*h < 0.0f) {
			*h += 360.0f;
		}
	}
	
	*h /= 360.0f;
}

#pragma mark -
#pragma mark Drawing Functions

void WDDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size)
{
	CGRect  square = CGRectMake(0, 0, size, size);
	float   startx = CGRectGetMinX(dest);
	float   starty = CGRectGetMinY(dest);
	
	CGContextSaveGState(ctx);
	CGContextClipToRect(ctx, dest);
	
	[[UIColor colorWithWhite:0.9f alpha:1.0f] set];
	CGContextFillRect(ctx, dest);
	
	[[UIColor colorWithWhite:0.78f alpha:1.0f] set];
	for (int y = 0; y * size < CGRectGetHeight(dest); y++) {
		for (int x = 0; x * size < CGRectGetWidth(dest); x++) {
			if ((y + x) % 2) {
				square.origin.x = startx + x * size;
				square.origin.y = starty + y * size;
				CGContextFillRect(ctx, square);
			}
		}
	}
	
	CGContextRestoreGState(ctx);
}

void WDDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest)
{
	float   minX = CGRectGetMinX(dest);
	float   maxX = CGRectGetMaxX(dest);
	float   minY = CGRectGetMinY(dest);
	float   maxY = CGRectGetMaxY(dest);
	
	// preserve the existing color
	CGContextSaveGState(ctx);
	[[UIColor whiteColor] set];
	CGContextFillRect(ctx, dest);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, minX, minY);
	CGPathAddLineToPoint(path, NULL, maxX, minY);
	CGPathAddLineToPoint(path, NULL, minX, maxY);
	CGPathCloseSubpath(path);
	
	[[UIColor blackColor] set];
	CGContextAddPath(ctx, path);
	CGContextFillPath(ctx);
	CGContextRestoreGState(ctx);
	
	CGPathRelease(path);
}

void WDContextDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef)
{
	size_t  width = CGImageGetWidth(imageRef);
	size_t  height = CGImageGetHeight(imageRef);
	float   wScale = CGRectGetWidth(bounds) / width;
	float   hScale = CGRectGetHeight(bounds) / height;
	float   scale = MAX(wScale, hScale);
	float   hOffset = 0.0f, vOffset = 0.0f;
	
	CGRect  rect = CGRectMake(0, 0, width * scale, height * scale);
	
	if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
		hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
		hOffset /= -2;
	}
	
	if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
		vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
		vOffset /= -2;
	}
	
	rect = CGRectOffset(rect, hOffset, vOffset);
	
	CGContextDrawImage(ctx, rect, imageRef);
}

#pragma mark -
#pragma mark Mathy Stuff

float WDSineCurve(float input)
{
	float result;
	
	input *= M_PI; // move from [0.0, 1.0] tp [0.0, Pi]
	input -= M_PI_2; // shift back onto a trough
	
	result = sin(input) + 1; // add 1 to put in range [0.0,2.0]
	result /= 2; // back to [0.0, 1.0];
	
	return result;
}

float WDRandomFloat()
{
	float r = random() % 10000;
	return r / 10000.0f;
}

NSData * WDSHA1DigestForData(NSData *data)
{
	unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, NULL, 0, [data bytes], [data length], cHMAC);
	
	return [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Geometry
////////////////////////////////////////////////////////////////////////////////
/*
	In order to translate existing transforms back to their constituents:
*/
CGFloat WDGetRotationFromTransform(CGAffineTransform T)
{
	double a1 = atan2(+T.b, +T.a);
	double a2 = atan2(-T.c, +T.d);
	return (CGFloat)(0.5*(a1+a2));
}

////////////////////////////////////////////////////////////////////////////////

CGSize WDGetScaleFromTransform(CGAffineTransform T)
{
	CGSize scale = { T.a, T.d };

	if ((T.b != 0.0)||(T.c != 0.0))
	{
		CGVector x = { 1.0, 0.0 };
		x = CGVectorApplyAffineTransform(x, T);
		scale.width = sqrt(x.dx*x.dx + x.dy*x.dy);
		CGVector y = { 0.0, 1.0 };
		y = CGVectorApplyAffineTransform(y, T);
		scale.height = sqrt(y.dx*y.dx + y.dy*y.dy);
	}

	return scale;
}

////////////////////////////////////////////////////////////////////////////////

CGSize WDSizeOfRectWithAngle(CGRect rect, float angle, CGPoint *upperLeft, CGPoint *upperRight)
{
	CGPoint center, corners[4];
	
	center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	CGAffineTransform transform = CGAffineTransformMakeRotation(angle * M_PI / 180.0f);
	
	corners[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
	corners[1] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
	corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	corners[3] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
	
	for (int i = 0; i < 4; i++) {
		corners[i] = CGPointApplyAffineTransform(corners[i], transform);
	}
	center = CGPointApplyAffineTransform(center, transform);
	
	float minx = corners[0].x;
	float maxx = corners[0].x;
	float miny = corners[0].y;
	float maxy = corners[0].y;
	
	for (int i = 1; i < 4; i++) {
		minx = MIN(minx, corners[i].x);
		maxx = MAX(maxx, corners[i].x);
		miny = MIN(miny, corners[i].y);
		maxy = MAX(maxy, corners[i].y);
	}
	
	if (upperLeft) {
		*upperLeft = WDSubtractPoints(corners[0], center);
	}
	
	if (upperRight) {
		*upperRight = WDSubtractPoints(corners[3], center);
	}
	
	return CGSizeMake(maxx - minx, maxy - miny);
}

CGPoint WDNormalizePoint(CGPoint vector)
{
	float distance = WDDistance(CGPointZero, vector);
	
	if (distance == 0.0f) {
		return vector;
	}
	
	return WDMultiplyPointScalar(vector, 1.0f / distance);
}

CGRect WDGrowRectToPoint(CGRect rect, CGPoint pt)
{
	double minX, minY, maxX, maxY;
	
	minX = MIN(CGRectGetMinX(rect), pt.x);
	minY = MIN(CGRectGetMinY(rect), pt.y);
	maxX = MAX(CGRectGetMaxX(rect), pt.x);
	maxY = MAX(CGRectGetMaxY(rect), pt.y);
	
	return CGRectUnion(rect, CGRectMake(minX, minY, maxX - minX, maxY - minY));
}

CGPoint WDSharpPointInContext(CGPoint pt, CGContextRef ctx)
{
	pt = CGContextConvertPointToDeviceSpace(ctx, pt);
	pt = WDFloorPoint(pt);
	pt = WDAddPoints(pt, CGPointMake(0.5f, 0.5f));
	pt = CGContextConvertPointToUserSpace(ctx, pt);
	
	return pt;
}

CGPoint WDConstrainPoint(CGPoint delta)
{
	float   angle = atan2(delta.y, delta.x);
	float   magnitude = WDDistance(delta, CGPointZero);
	
	angle = roundf(angle / M_PI_4) * M_PI_4;
	delta.x = cos(angle) * magnitude;
	delta.y = sin(angle) * magnitude;
	
	return delta;
}

CGRect WDRectWithRadius(CGPoint c, CGFloat radius)
{ return (CGRect){ c.x-radius, c.y-radius, 2*radius, 2*radius }; }

CGRect WDRectFromPoint(CGPoint a, float width, float height)
{
	return CGRectMake(a.x - (width / 2), a.y - (height / 2), width, height);
}

BOOL WDCollinear(CGPoint a, CGPoint b, CGPoint c)
{ return ((b.x-a.x)*(c.y-a.y)) == ((c.x-a.x)*(b.y-a.y)); }

CGFloat WDCollinearity(CGPoint a, CGPoint b, CGPoint c)
{ return fabs(((b.x-a.x)*(c.y-a.y)) - ((c.x-a.x)*(b.y-a.y))); }


BOOL _WDCollinear(CGPoint a, CGPoint b, CGPoint c)
{
	float temp, distances[3];
	
	distances[0] = WDDistance(a, b);
	distances[1] = WDDistance(b, c);
	distances[2] = WDDistance(a, c);

	// sort the array...
	if (distances[0] > distances[1]) {
		temp = distances[1];
		distances[1] = distances[0];
		distances[0] = temp;
	}
	
	if (distances[1] > distances[2]) {
		temp = distances[2];
		distances[2] = distances[1];
		distances[1] = temp;
	}
	
	// if the points are collinear, the sum of the shortest 2 distances is equal to the longest distance
	float shortestSum = distances[0] + distances[1];
	float difference = fabs(shortestSum - distances[2]);
	
	return (difference < 1.0e-4);
}

BOOL WDLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *rV, float *sV)
{
	float denom = (B.x - A.x) * (D.y - C.y) - (B.y - A.y) * (D.x - C.x);
	
	if (denom == 0) {
		return NO;
	}
	
	float r = (A.y - C.y) * (D.x - C.x) - (A.x - C.x) * (D.y - C.y);
	r /= denom;
	
	float s = (A.y - C.y) * (B.x - A.x) - (A.x - C.x) * (B.y - A.y);
	s /= denom;
	
	if (rV) {
		*rV = r;
	}
	
	if (sV) {
		*sV = s;
	}
	
	return (r < 0 || r > 1 || s < 0 || s > 1) ? NO : YES;;
}

BOOL WDLineSegmentsIntersect(CGPoint A, CGPoint B, CGPoint C, CGPoint D)
{
	return WDLineSegmentsIntersectWithValues(A, B, C, D, NULL, NULL);
}

CGRect WDShrinkRect(CGRect rect, float percentage)
{
	float   widthInset = CGRectGetWidth(rect) * percentage;
	float   heightInset = CGRectGetHeight(rect) * percentage;
	
	return CGRectInset(rect, widthInset, heightInset);
}

#pragma mark -
#pragma mark Paths

void convertQuadraticPathElement(void *info, const CGPathElement *element)
{
	CGMutablePathRef    converted = (CGMutablePathRef) info;
	CGPoint             prev;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint:
			CGPathMoveToPoint(converted, NULL, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddLineToPoint:
			CGPathAddLineToPoint(converted, NULL, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddQuadCurveToPoint:
			prev = CGPathGetCurrentPoint(converted);
			
			// convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
			CGPoint outPoint = WDAddPoints(prev, WDMultiplyPointScalar(WDSubtractPoints(element->points[0], prev), 2.0f / 3));
			CGPoint inPoint = WDAddPoints(element->points[1], WDMultiplyPointScalar(WDSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
			
			CGPathAddCurveToPoint(converted, NULL, outPoint.x, outPoint.y, inPoint.x, inPoint.y, element->points[1].x, element->points[1].y);
			break;
		case kCGPathElementAddCurveToPoint:
			CGPathAddCurveToPoint(converted, NULL, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
			break;
		case kCGPathElementCloseSubpath:
			CGPathCloseSubpath(converted);
			break;
	}
}

CGPathRef WDCreateCubicPathFromQuadraticPath(CGPathRef pathRef)
{
	CGMutablePathRef converted = CGPathCreateMutable();
		
	CGPathApply(pathRef, converted, &convertQuadraticPathElement);
	
	return converted;
}

void WDPathApplyAccumulateElement(void *info, const CGPathElement *element)
{
	NSMutableArray  *subpaths = (__bridge NSMutableArray *)info;
	WDPath          *path = [subpaths lastObject];
	WDBezierNode    *prev, *node;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint:
			path = [[WDPath alloc] init];
			
			node = [[WDBezierNode alloc] initWithAnchorPoint:element->points[0]];
			[path.nodes addObject:node];
			
			[subpaths addObject:path];
			break;
		case kCGPathElementAddLineToPoint:
			node = [[WDBezierNode alloc] initWithAnchorPoint:element->points[0]];
			[path.nodes addObject:node];
			break;
		case kCGPathElementAddQuadCurveToPoint:
			prev = [path lastNode];
			
			// convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
			CGPoint outPoint = WDAddPoints(prev.anchorPoint, WDMultiplyPointScalar(WDSubtractPoints(element->points[0], prev.anchorPoint), 2.0f / 3));
			CGPoint inPoint = WDAddPoints(element->points[1], WDMultiplyPointScalar(WDSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
			
			// update and replace previous node
			node = [prev copyWithNewOutPoint:outPoint];
			[path.nodes removeLastObject];
			[path.nodes addObject:node];
			
			node = [WDBezierNode
			bezierNodeWithAnchorPoint:element->points[1]
							outPoint:element->points[1]
							inPoint:inPoint];

			[path.nodes addObject:node];
			break;
		case kCGPathElementAddCurveToPoint:
			prev = [path lastNode];
			
			// update and replace previous node
			node = [prev copyWithNewOutPoint:element->points[0]];
			[path.nodes removeLastObject];
			[path.nodes addObject:node];
			
			node = [WDBezierNode
			bezierNodeWithAnchorPoint:element->points[1]
							outPoint:element->points[2]
							inPoint:element->points[1]];
			[path.nodes addObject:node];
			break;
		case kCGPathElementCloseSubpath:
			[path setClosedQuiet:YES];
			break;
	}
}

CGRect WDStrokeBoundsForPath(CGPathRef pathRef, WDStrokeStyle *strokeStyle) 
{
	CGRect basicBounds = CGPathGetPathBoundingBox(pathRef);
	
	if (!strokeStyle || ![strokeStyle willRender]) {
		return basicBounds;
	}
	
	float halfWidth = strokeStyle.width / 2.0f;
	float outset = sqrt((halfWidth * halfWidth) * 2);
	
	// expand by half the stroke width to find the basic bounding box
	CGRect styleBounds = CGRectInset(basicBounds, -outset, -outset);
	
	// include miter joins on corners
	if (strokeStyle.join == kCGLineJoinMiter) {
		NSMutableArray *subpaths = [NSMutableArray array];
		CGPathApply(pathRef, (__bridge void *)(subpaths), &WDPathApplyAccumulateElement);
		
		for (WDPath *subpath in subpaths) {
			NSArray         *nodes = subpath.nodes;
			NSInteger       nodeCount = subpath.closed ? nodes.count + 1 : nodes.count;
			
			if (nodeCount < 3) {
				continue;
			}
			
			WDBezierNode    *prev = nodes[0];
			WDBezierNode    *curr = nodes[1];
			WDBezierNode    *next;
			CGPoint         inPoint, outPoint, inVec, outVec;
			float           miterLength, angle;
			
			for (int i = 1; i < nodeCount; i++) {
				next = nodes[(i+1) % nodes.count];
				
				inPoint = [curr hasInPoint] ? curr.inPoint : prev.outPoint;
				outPoint = [curr hasOutPoint] ? curr.outPoint : next.inPoint;
				
				inVec = WDSubtractPoints(inPoint, curr.anchorPoint);
				outVec = WDSubtractPoints(outPoint, curr.anchorPoint);
				
				inVec = WDNormalizePoint(inVec);
				outVec = WDNormalizePoint(outVec);
				
				angle = acos(inVec.x * outVec.x + inVec.y * outVec.y);
				miterLength = strokeStyle.width / sin(angle / 2.0f);
				
				if ((miterLength / strokeStyle.width) < kMiterLimit) {
					CGPoint avg = WDAveragePoints(inVec, outVec);
					CGPoint directed = WDMultiplyPointScalar(WDNormalizePoint(avg), -miterLength / 2.0f);
					
					styleBounds = WDGrowRectToPoint(styleBounds, WDAddPoints(curr.anchorPoint, directed));
				}
				
				prev = curr;
				curr = next;
			}
		}
	}
	
	return styleBounds;
}


CGRect WDStrokeOptionsStyleBoundsForPath
(WDStrokeOptions *strokeOptions, CGPathRef pathRef)
{
	CGRect basicBounds = CGPathGetPathBoundingBox(pathRef);
	
	if (![strokeOptions visible]) {
		return basicBounds;
	}
	
	float halfWidth = strokeOptions.lineWidth / 2.0f;
	float outset = sqrt((halfWidth * halfWidth) * 2);
	
	// expand by half the stroke width to find the basic bounding box
	CGRect styleBounds = CGRectInset(basicBounds, -outset, -outset);
	
	// include miter joins on corners
	if (strokeOptions.lineJoin == kCGLineJoinMiter) {
		NSMutableArray *subpaths = [NSMutableArray array];
		CGPathApply(pathRef, (__bridge void *)(subpaths), &WDPathApplyAccumulateElement);
		
		for (WDPath *subpath in subpaths) {
			NSArray         *nodes = subpath.nodes;
			NSInteger       nodeCount = subpath.closed ? nodes.count + 1 : nodes.count;
			
			if (nodeCount < 3) {
				continue;
			}
			
			WDBezierNode    *prev = nodes[0];
			WDBezierNode    *curr = nodes[1];
			WDBezierNode    *next;
			CGPoint         inPoint, outPoint, inVec, outVec;
			float           miterLength, angle;
			
			for (int i = 1; i < nodeCount; i++) {
				next = nodes[(i+1) % nodes.count];
				
				inPoint = [curr hasInPoint] ? curr.inPoint : prev.outPoint;
				outPoint = [curr hasOutPoint] ? curr.outPoint : next.inPoint;
				
				inVec = WDSubtractPoints(inPoint, curr.anchorPoint);
				outVec = WDSubtractPoints(outPoint, curr.anchorPoint);
				
				inVec = WDNormalizePoint(inVec);
				outVec = WDNormalizePoint(outVec);
				
				angle = acos(inVec.x * outVec.x + inVec.y * outVec.y);
				miterLength = strokeOptions.lineWidth / sin(angle / 2.0f);
				
				if ((miterLength / strokeOptions.lineWidth) < kMiterLimit) {
					CGPoint avg = WDAveragePoints(inVec, outVec);
					CGPoint directed = WDMultiplyPointScalar(WDNormalizePoint(avg), -miterLength / 2.0f);
					
					styleBounds = WDGrowRectToPoint(styleBounds, WDAddPoints(curr.anchorPoint, directed));
				}
				
				prev = curr;
				curr = next;
			}
		}
	}
	
	return styleBounds;
}
/*
typedef struct {
	CGMutablePathRef mutablePath;
	CGAffineTransform transform;
} WDPathAndTransform;

void transformPathElement(void *info, const CGPathElement *element)
{
	WDPathAndTransform  pathAndTransform = *((WDPathAndTransform *) info);
	CGAffineTransform   transform = pathAndTransform.transform;
	CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint:
			CGPathMoveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddLineToPoint:
			CGPathAddLineToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddQuadCurveToPoint:
			CGPathAddQuadCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
			break;
		case kCGPathElementAddCurveToPoint:
			CGPathAddCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
			break;
		case kCGPathElementCloseSubpath:
			CGPathCloseSubpath(pathRef);
			break;
			
	}
}

CGPathRef WDCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform)
{
	CGMutablePathRef    transformedPath = CGPathCreateMutable();
	WDPathAndTransform  pathAndTransform = {transformedPath, transform};
	
	CGPathApply(pathRef, &pathAndTransform, &transformPathElement);
	
	return transformedPath;
}

*/

CGPathRef WDCreateTransformedCGPathRef(CGPathRef pathRef, CGAffineTransform transform)
{
	return CGPathCreateCopyByTransformingPath(pathRef, &transform);
}

////////////////////////////////////////////////////////////////////////////////

static void CGPathAddSegmentWithNodes
(CGMutablePathRef pathRef, WDBezierNode *N1, WDBezierNode *N2)
{
	if (N1 == nil)
		CGPathMoveToPoint(pathRef, NULL,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
	else
	if (N1.hasOutPoint || N2.hasInPoint)
		CGPathAddCurveToPoint(pathRef, NULL,
			N1.outPoint.x,
			N1.outPoint.y,
			N2.inPoint.x,
			N2.inPoint.y,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
	else
		CGPathAddLineToPoint(pathRef, NULL,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Misc

NSString * WDSVGStringForCGAffineTransform(CGAffineTransform t)
{
	return [NSString stringWithFormat:@"matrix(%g %g %g %g %g %g)", t.a, t.b, t.c, t.d, t.tx, t.ty];
}

WDPickResult * WDSnapToRectangle(CGRect rect, CGAffineTransform *transform, CGPoint pt, float viewScale, int snapFlags)
{
	WDPickResult    *pickResult = [WDPickResult pickResult];
	CGPoint         corner[4];
	
	corner[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
	corner[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
	corner[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	corner[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
	
	if (transform) {
		for (int i = 0; i < 4; i++) {
			corner[i] = CGPointApplyAffineTransform(corner[i], *transform);
		}
	}
	
	if (snapFlags & kWDSnapNodes) {
		for (int i = 0; i < 4; i++) {
			if (WDDistance(corner[i], pt) < (kNodeSelectionTolerance / viewScale)) {
				pickResult.snappedPoint = corner[i];
				pickResult.type = kWDRectCorner;
				return pickResult;
			}
		}
	}
	
	if (snapFlags & kWDSnapEdges) {
		WDBezierSegment     segment;
		CGPoint             nearest;
		
		for (int i = 0; i < 4; i++) {
			segment.a_ = segment.out_ = corner[i];
			segment.b_ = segment.in_ = corner[(i+1) % 4];
			
			if (WDBezierSegmentFindPointOnSegment(segment, pt, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
				pickResult.snappedPoint = nearest;
				pickResult.type = kWDRectEdge;
				return pickResult;
			}
		}
	}

	return pickResult;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark WDQuad
////////////////////////////////////////////////////////////////////////////////

WDQuad WDQuadMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d)
{
	WDQuad quad;
	
	quad.P[0] = a;
	quad.P[1] = b;
	quad.P[2] = c;
	quad.P[3] = d;
	
	return quad;
}

////////////////////////////////////////////////////////////////////////////////

WDQuad WDQuadWithRect(CGRect R, CGAffineTransform T)
{
	WDQuad quad;

	quad.P[0] = CGPointMake(CGRectGetMinX(R), CGRectGetMinY(R));
	quad.P[1] = CGPointMake(CGRectGetMaxX(R), CGRectGetMinY(R));
	quad.P[2] = CGPointMake(CGRectGetMaxX(R), CGRectGetMaxY(R));
	quad.P[3] = CGPointMake(CGRectGetMinX(R), CGRectGetMaxY(R));

	quad = WDQuadApplyTransform(quad, T);

	return quad;
}

////////////////////////////////////////////////////////////////////////////////

WDQuad WDQuadApplyTransform(WDQuad quad, CGAffineTransform T)
{
	quad.P[0] = CGPointApplyAffineTransform(quad.P[0], T);
	quad.P[1] = CGPointApplyAffineTransform(quad.P[1], T);
	quad.P[2] = CGPointApplyAffineTransform(quad.P[2], T);
	quad.P[3] = CGPointApplyAffineTransform(quad.P[3], T);
	return quad;
}

////////////////////////////////////////////////////////////////////////////////

CGFloat WDQuadGetRotation(WDQuad quad)
{
	CGPoint P1 = WDAddPoints(quad.P[0], quad.P[3]);
	CGPoint P2 = WDAddPoints(quad.P[1], quad.P[2]);
	return atan2(P2.y-P1.y, P2.x-P1.x);
}

////////////////////////////////////////////////////////////////////////////////

CGSize WDQuadGetSize(WDQuad quad)
{
	CGPoint X1 = WDAddPoints(quad.P[0], quad.P[3]);
	CGPoint X2 = WDAddPoints(quad.P[1], quad.P[2]);
	CGPoint Y1 = WDAddPoints(quad.P[0], quad.P[1]);
	CGPoint Y2 = WDAddPoints(quad.P[3], quad.P[2]);

	return (CGSize){ 0.5*WDDistance(X1,X2), 0.5*WDDistance(Y1,Y2) };
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDQuadIntersectsRect
	--------------------
	Test if any of the quad linesegments intersect rect
	
	Does not test for fully inside
*/

BOOL WDQuadIntersectsRect(WDQuad quad, CGRect R)
{
	return
	WDLineIntersectsRect(quad.P[0], quad.P[1], R)||
	WDLineIntersectsRect(quad.P[1], quad.P[2], R)||
	WDLineIntersectsRect(quad.P[2], quad.P[3], R)||
	WDLineIntersectsRect(quad.P[3], quad.P[0], R);
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDQuadContainsPoint(WDQuad quad, CGPoint P)
{
	BOOL result = NO;

	CGPathRef pathRef = WDQuadCreateCGPath(quad);
	result = CGPathContainsPoint(pathRef, nil, P, false);
	CGPathRelease(pathRef);

	return result;
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDQuadIsNull(WDQuad Q)
{
	return
	(Q.P[0].x == 0.0) && (Q.P[0].y == 0.0) &&
	(Q.P[1].x == 0.0) && (Q.P[1].y == 0.0) &&
	(Q.P[2].x == 0.0) && (Q.P[2].y == 0.0) &&
	(Q.P[3].x == 0.0) && (Q.P[3].y == 0.0);
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDQuadEqualToQuad(WDQuad a, WDQuad b)
{
	return
	CGPointEqualToPoint(a.P[0], b.P[0])&&
	CGPointEqualToPoint(a.P[1], b.P[1])&&
	CGPointEqualToPoint(a.P[2], b.P[2])&&
	CGPointEqualToPoint(a.P[3], b.P[3]);
}

////////////////////////////////////////////////////////////////////////////////

BOOL WDQuadIntersectsQuad(WDQuad a, WDQuad b)
{
	if (WDQuadEqualToQuad(a, WDQuadNull) ||
		WDQuadEqualToQuad(b, WDQuadNull))
		{ return NO; }
	
	for (int i = 0; i < 4; i++) {
		for (int n = 0; n < 4; n++) {
			if (WDLineSegmentsIntersect(a.P[i], a.P[(i+1)%4], b.P[n], b.P[(n+1)%4])) {
				return YES;
			}
		}
	}
	
	return NO;
}


CGPoint WDQuadGetCenter(WDQuad Q)
{
	const CGPoint *P = Q.P;
	return (CGPoint){
		0.25 * (P[0].x+P[1].x+P[2].x+P[3].x),
		0.25 * (P[0].y+P[1].y+P[2].y+P[3].y) };
}


NSString * NSStringFromWDQuad(WDQuad quad)
{
	return [NSString stringWithFormat:@"{{%@}, {%@}, {%@}, {%@}}", \
	NSStringFromCGPoint(quad.P[0]), \
	NSStringFromCGPoint(quad.P[1]), \
	NSStringFromCGPoint(quad.P[2]), \
	NSStringFromCGPoint(quad.P[3])];
}

CGPathRef WDQuadCreateCGPath(WDQuad q)
{
	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPathMoveToPoint(pathRef, NULL, q.P[0].x, q.P[0].y);
	CGPathAddLineToPoint(pathRef, NULL, q.P[1].x, q.P[1].y);
	CGPathAddLineToPoint(pathRef, NULL, q.P[2].x, q.P[2].y);
	CGPathAddLineToPoint(pathRef, NULL, q.P[3].x, q.P[3].y);
	CGPathCloseSubpath(pathRef);

	return pathRef;
}
