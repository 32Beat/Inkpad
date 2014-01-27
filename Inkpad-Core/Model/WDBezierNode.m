//
//  WDBezierNode.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#if TARGET_OS_IPHONE
#import <OpenGLES/ES1/gl.h>

#else
#import <UIKit/UIKit.h>
#import <OpenGL/gl.h>
#endif

#import "UIColor+Additions.h"
#import "WDBezierNode.h"
#import "WDGLUtilities.h"
#import "WDUtilities.h"

#define kAnchorRadius 4
#define kControlPointRadius 3.5

NSString *WDPointArrayKey = @"WDPointArrayKey";

/**************************
 * WDBezierNode
 *************************/

@implementation WDBezierNode

@synthesize inPoint = inPoint_;
@synthesize anchorPoint = anchorPoint_;
@synthesize outPoint = outPoint_;
@synthesize selected = selected_;

+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)pt
{
    return [[self alloc] initWithAnchorPoint:pt];
}

+ (WDBezierNode *) bezierNodeWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)pt outPoint:(CGPoint)outPoint
{
    return [[self alloc] initWithInPoint:inPoint anchorPoint:pt outPoint:outPoint];
}

+ (WDBezierNode *) bezierNodeWithPoints:(const CGPoint *)P
{ return [self bezierNodeWithInPoint:P[0] anchorPoint:P[1] outPoint:P[2]]; }




- (id) copyWithZone:(NSZone *)zone
{
    WDBezierNode *node = [[WDBezierNode alloc] init];
    
    node->inPoint_ = inPoint_;
    node->anchorPoint_ = anchorPoint_;
    node->outPoint_ = outPoint_;
    node->selected_ = selected_;

    return node;
}



- (id) initWithAnchorPoint:(CGPoint)pt
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    inPoint_ = anchorPoint_ = outPoint_ = pt;
    
    return self;
}

- (id) initWithInPoint:(CGPoint)inPoint anchorPoint:(CGPoint)pt outPoint:(CGPoint)outPoint
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    inPoint_ = inPoint;
    anchorPoint_ = pt;
    outPoint_ = outPoint;
    
    return self;
}

- (BOOL) isEqual:(WDBezierNode *)node
{
    if (node == self) {
        return YES;
    }
    
    if (![node isKindOfClass:[WDBezierNode class]]) {
        return NO;
    }
    
    return (CGPointEqualToPoint(self.inPoint, node.inPoint) &&
            CGPointEqualToPoint(self.anchorPoint, node.anchorPoint) &&
            CGPointEqualToPoint(self.outPoint, node.outPoint));
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    CFSwappedFloat32    swapped[6];
    float               points[6] = { inPoint_.x, inPoint_.y, anchorPoint_.x, anchorPoint_.y, outPoint_.x, outPoint_.y };
    
    for (NSUInteger ix = 0; ix < 6; ix++) {
        swapped[ix] = CFConvertFloat32HostToSwapped(points[ix]);
    }
    
    [coder encodeBytes:(const uint8_t *)swapped length:(6 * sizeof(CFSwappedFloat32)) forKey:WDPointArrayKey];
}

static inline BOOL CGPointIsValid(CGPoint P)
{ return !isnan(P.x) && !isnan(P.y); }

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    const uint8_t   *bytes = [coder decodeBytesForKey:WDPointArrayKey returnedLength:NULL];
    
    CFSwappedFloat32 *swapped = (CFSwappedFloat32 *) bytes;
        
    inPoint_.x = CFConvertFloat32SwappedToHost(swapped[0]);
    inPoint_.y = CFConvertFloat32SwappedToHost(swapped[1]);
    anchorPoint_.x = CFConvertFloat32SwappedToHost(swapped[2]);
    anchorPoint_.y = CFConvertFloat32SwappedToHost(swapped[3]);
    outPoint_.x = CFConvertFloat32SwappedToHost(swapped[4]);
    outPoint_.y = CFConvertFloat32SwappedToHost(swapped[5]);

	if (!CGPointIsValid(anchorPoint_))
	{ anchorPoint_ = CGPointZero; }

	if (!CGPointIsValid(inPoint_))
	{ inPoint_ = anchorPoint_; }

	if (!CGPointIsValid(outPoint_))
	{ outPoint_ = anchorPoint_; }

    return self; 
}


- (BOOL) readFromCoder:(NSCoder *)coder
{
//	int version = [coder decodeIntForKey:WDFileVersionID];

	return YES;
}

- (BOOL) readFromCoder_v000:(NSCoder *)coder
{
    const uint8_t   *bytes = [coder decodeBytesForKey:WDPointArrayKey returnedLength:NULL];
    
    CFSwappedFloat32 *swapped = (CFSwappedFloat32 *) bytes;
        
    inPoint_.x = CFConvertFloat32SwappedToHost(swapped[0]);
    inPoint_.y = CFConvertFloat32SwappedToHost(swapped[1]);
    anchorPoint_.x = CFConvertFloat32SwappedToHost(swapped[2]);
    anchorPoint_.y = CFConvertFloat32SwappedToHost(swapped[3]);
    outPoint_.x = CFConvertFloat32SwappedToHost(swapped[4]);
    outPoint_.y = CFConvertFloat32SwappedToHost(swapped[5]);

	if (!CGPointIsValid(anchorPoint_))
	{ anchorPoint_ = CGPointZero; }

	if (!CGPointIsValid(inPoint_))
	{ inPoint_ = anchorPoint_; }

	if (!CGPointIsValid(outPoint_))
	{ outPoint_ = anchorPoint_; }

	return YES;
}

- (BOOL) readFromCoder_v100:(NSCoder *)coder
{

	if (!CGPointIsValid(anchorPoint_))
	{ anchorPoint_ = CGPointZero; }

	if (!CGPointIsValid(inPoint_))
	{ inPoint_ = anchorPoint_; }

	if (!CGPointIsValid(outPoint_))
	{ outPoint_ = anchorPoint_; }

	return YES;
}




- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: (%@) -- [%@] -- (%@)", [super description],
            NSStringFromCGPoint(inPoint_), NSStringFromCGPoint(anchorPoint_), NSStringFromCGPoint(outPoint_)];
}

- (WDBezierNodeReflectionMode) reflectionMode
{
    // determine whether the points are colinear
    
    // normalize the handle points first
    CGPoint     a = WDAddPoints(anchorPoint_, WDNormalizePoint(WDSubtractPoints(inPoint_, anchorPoint_)));
    CGPoint     b = WDAddPoints(anchorPoint_, WDNormalizePoint(WDSubtractPoints(outPoint_, anchorPoint_)));
    
    // then compute the area of the triangle
    float triangleArea = fabs(anchorPoint_.x * (a.y - b.y) + a.x * (b.y - anchorPoint_.y) + b.x * (anchorPoint_.y - a.y));
    
    if (triangleArea < 1.0e-3 && !CGPointEqualToPoint(inPoint_, outPoint_)) {
        return WDReflectIndependent;
    }
    
    return WDIndependent;
}

- (BOOL) hasInPoint
{
    return !CGPointEqualToPoint(self.anchorPoint, self.inPoint);
}

- (BOOL) hasOutPoint
{
    return !CGPointEqualToPoint(self.anchorPoint, self.outPoint);
}

- (BOOL) isCorner
{
    if (![self hasInPoint] || ![self hasOutPoint]) {
        return YES;
    }
    
    return !WDCollinear(inPoint_, anchorPoint_, outPoint_);
}

- (WDBezierNode *) transform:(CGAffineTransform)transform
{
    CGPoint tXIn = CGPointApplyAffineTransform(inPoint_, transform);
    CGPoint tXAnchor = CGPointApplyAffineTransform(anchorPoint_, transform);
    CGPoint tXOut = CGPointApplyAffineTransform(outPoint_, transform);
    
    WDBezierNode *transformed = [[WDBezierNode alloc] initWithInPoint:tXIn anchorPoint:tXAnchor outPoint:tXOut];
    
    return transformed;
}


- (WDBezierNode *) copyWithInPoint:(CGPoint)P
{
	WDBezierNode *newNode = [self copyWithZone:nil];
	newNode->inPoint_ = P;
	return newNode;
}

- (WDBezierNode *) copyWithOutPoint:(CGPoint)P
{
	WDBezierNode *newNode = [self copyWithZone:nil];
	newNode->outPoint_ = P;
	return newNode;
}




- (WDBezierNode *) setInPoint:(CGPoint)pt reflectionMode:(WDBezierNodeReflectionMode)reflectionMode
{
    CGPoint flippedPoint = WDAddPoints(anchorPoint_, WDSubtractPoints(anchorPoint_, pt));
    // special case when closing a path
    return [self moveControlHandle:kWDInPoint toPoint:flippedPoint reflectionMode:reflectionMode];
}

- (WDBezierNode *) chopHandles
{
    if (self.hasInPoint || self.hasOutPoint) {
        return [WDBezierNode bezierNodeWithAnchorPoint:anchorPoint_];
    } else {
        return self;
    }
}

- (WDBezierNode *) chopOutHandle
{
    if (self.hasOutPoint) {
        return [WDBezierNode bezierNodeWithInPoint:inPoint_ anchorPoint:anchorPoint_ outPoint:anchorPoint_];
    } else {
        return self;
    }
}

- (WDBezierNode *) chopInHandle
{
    if (self.hasInPoint) {
        return [WDBezierNode bezierNodeWithInPoint:anchorPoint_ anchorPoint:anchorPoint_ outPoint:outPoint_];
    } else {
        return self;
    }
}

- (WDBezierNode *) moveControlHandle:(WDPickResultType)pointToTransform toPoint:(CGPoint)pt reflectionMode:(WDBezierNodeReflectionMode)reflectionMode
{
    CGPoint     inPoint = inPoint_, outPoint = outPoint_;
    
    if (pointToTransform == kWDInPoint) {
        inPoint = pt;
        
        if (reflectionMode == WDReflect) {
            CGPoint delta = WDSubtractPoints(anchorPoint_, inPoint);
            outPoint = WDAddPoints(anchorPoint_, delta);
        } else if (reflectionMode == WDReflectIndependent) {
            CGPoint outVector = WDSubtractPoints(outPoint_, anchorPoint_);
            float magnitude = WDDistance(outVector, CGPointZero);
            
            CGPoint inVector = WDNormalizePoint(WDSubtractPoints(anchorPoint_, inPoint));
            
            if (CGPointEqualToPoint(inVector, CGPointZero)) {
                // If the in vector is 0, we'll inadvertently chop the out vector. Don't want that.
                outPoint = outPoint_;
            } else {
                outVector = WDMultiplyPointScalar(inVector, magnitude);
                outPoint = WDAddPoints(anchorPoint_, outVector);
            }
        }
    } else if (pointToTransform == kWDOutPoint) {
        outPoint = pt;
        
        if (reflectionMode == WDReflect) {
            CGPoint delta = WDSubtractPoints(anchorPoint_, outPoint);
            inPoint = WDAddPoints(anchorPoint_, delta);
        } else if (reflectionMode == WDReflectIndependent) {
            CGPoint inVector = WDSubtractPoints(inPoint_, anchorPoint_);
            float magnitude = WDDistance(inVector, CGPointZero);
            
            CGPoint outVector = WDNormalizePoint(WDSubtractPoints(anchorPoint_, outPoint));
            
            if (CGPointEqualToPoint(outVector, CGPointZero)) {
                // If the out vector is 0, we'll inadvertently chop the in vector. Don't want that.
                inPoint = inPoint_;
            }  else {
                inVector = WDMultiplyPointScalar(outVector, magnitude);
                inPoint = WDAddPoints(anchorPoint_, inVector);
            }
        }
    }
    
    return [[WDBezierNode alloc] initWithInPoint:inPoint anchorPoint:anchorPoint_ outPoint:outPoint];
}

- (WDBezierNode *) flippedNode
{
    return [WDBezierNode bezierNodeWithInPoint:self.outPoint anchorPoint:self.anchorPoint outPoint:self.inPoint];
}
    
- (void) getInPoint:(CGPoint *)inPoint anchorPoint:(CGPoint *)anchorPoint outPoint:(CGPoint *)outPoint selected:(BOOL *)selected
{
    *inPoint = inPoint_;
    *anchorPoint = anchorPoint_;
    *outPoint = outPoint_;
    
    if (selected) {
        *selected = selected_;
    }
}

@end

@implementation WDBezierNode (GLRendering)

- (void) drawGLWithViewTransform:(CGAffineTransform)transform
	color:(UIColor *)color mode:(WDBezierNodeRenderMode)mode
{
	CGPoint A = CGPointApplyAffineTransform(anchorPoint_, transform);
	CGPoint L = CGPointApplyAffineTransform(inPoint_, transform);
	CGPoint R = CGPointApplyAffineTransform(outPoint_, transform);
		
	// draw the control handles
	if (mode == kWDBezierNodeRenderSelected)
	{
		[color openGLSet];
		
		if ([self hasInPoint])
		{ WDGLStrokeLine(L, A); }

		if ([self hasOutPoint])
		{ WDGLStrokeLine(R, A); }
	}

	// draw the anchor
	if (mode == kWDBezierNodeRenderClosed)
	{
		[color openGLSet];
		WDGLFillSquareMarker(A);
	}
	else
	if (mode == kWDBezierNodeRenderSelected)
	{
		[color openGLSet];
		WDGLFillSquareMarker(A);
		glColor4f(1, 1, 1, 1);
		WDGLStrokeSquareMarker(A);
	}
	else
	{
		glColor4f(1, 1, 1, 1);
		WDGLFillSquareMarker(A);
		[color openGLSet];
		WDGLStrokeSquareMarker(A);
	}

	// draw the control handle knobs
	if (mode == kWDBezierNodeRenderSelected)
	{
		[color openGLSet];
		
		if ([self hasInPoint])
		{ WDGLFillCircleMarker(L); }
		
		if ([self hasOutPoint])
		{ WDGLFillCircleMarker(R); }
	}
}

@end
