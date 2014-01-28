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



static NSString *WDBezierNodeVersionKey = @"WDBezierNodeVersion";

static NSInteger WDBezierNodeVersion = 100;
static NSString *WDBezierNodeAnchorPointKey = @"WDBezierNodeAnchorPoint";
static NSString *WDBezierNodeOutPointKey = @"WDBezierNodeOutPoint";
static NSString *WDBezierNodeInPointKey = @"WDBezierNodeInPoint";

static NSInteger WDBezierNodeVersion0 = 0;
static NSString *WDBezierNodePointArrayKey = @"WDPointArrayKey";

/**************************
 * WDBezierNode
 *************************/

@implementation WDBezierNode

@synthesize inPoint = inPoint_;
@synthesize anchorPoint = anchorPoint_;
@synthesize outPoint = outPoint_;
@synthesize selected = selected_;


////////////////////////////////////////////////////////////////////////////////
// Deprecated
+ (WDBezierNode *) bezierNodeWithInPoint:(CGPoint)A
							anchorPoint:(CGPoint)B
							outPoint:(CGPoint)C
{ return [self bezierNodeWithAnchorPoint:B outPoint:C inPoint:A]; }

////////////////////////////////////////////////////////////////////////////////

+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint
{
	return [[self alloc] initWithAnchorPoint:anchorPoint];
}

+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint
									outPoint:(CGPoint)outPoint
{
	return [[self alloc] initWithAnchorPoint:anchorPoint
									outPoint:outPoint];
}

+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint
									outPoint:(CGPoint)outPoint
									 inPoint:(CGPoint)inPoint
{
	return [[self alloc] initWithAnchorPoint:anchorPoint
									outPoint:outPoint
									inPoint:inPoint];
}

////////////////////////////////////////////////////////////////////////////////
/*
	If WDBezierNodes are truly immutable, which the read-only vars suggest, 
	then we can simply return "self" in copyWithZone, and only create a true
	copy if an immutable version is requested.
*/

- (id) copyWithZone:(NSZone *)zone
{
	return self;

//	return [self mutableCopyWithZone:zone];
}

- (id) mutableCopyWithZone:(NSZone *)zone
{
	WDBezierNode *node = [WDBezierNode new];

	node->inPoint_ = inPoint_;
	node->anchorPoint_ = anchorPoint_;
	node->outPoint_ = outPoint_;
	node->selected_ = selected_;

	return node;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithAnchorPoint:(CGPoint)pt
{ return [self initWithAnchorPoint:pt outPoint:pt]; }

- (id) initWithAnchorPoint:(CGPoint)anchorPoint outPoint:(CGPoint)outPoint
{
	// Mirror outPoint
	CGPoint inPoint = {
	anchorPoint.x - (outPoint.x - anchorPoint.x),
	anchorPoint.y - (outPoint.y - anchorPoint.y) };

	return [self initWithAnchorPoint:anchorPoint outPoint:outPoint inPoint:inPoint];
}

- (id) initWithAnchorPoint:(CGPoint)anchorPoint
				  outPoint:(CGPoint)outPoint
				   inPoint:(CGPoint)inPoint
{
	self = [super init];
	if (self != nil)
	{
		anchorPoint_ = anchorPoint;
		outPoint_ = outPoint;
		inPoint_ = inPoint;
		selected_ = NO;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) isEqual:(WDBezierNode *)node
{
	if (node == self)
	{ return YES; }

	return [node isKindOfClass:[self class]]&&
	CGPointEqualToPoint(self->inPoint_, node->inPoint_) &&
	CGPointEqualToPoint(self->anchorPoint_, node->anchorPoint_) &&
	CGPointEqualToPoint(self->outPoint_, node->outPoint_);
}

////////////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder
{
	id A = NSStringFromCGPoint(anchorPoint_);
	id B = NSStringFromCGPoint(outPoint_);
	id C = NSStringFromCGPoint(inPoint_);

	[coder encodeInteger:WDBezierNodeVersion forKey:WDBezierNodeVersionKey];
	[coder encodeObject:A forKey:WDBezierNodeAnchorPointKey];
	[coder encodeObject:B forKey:WDBezierNodeOutPointKey];
	[coder encodeObject:C forKey:WDBezierNodeInPointKey];
}

////////////////////////////////////////////////////////////////////////////////

static inline BOOL CGPointIsValid(CGPoint P)
{ return !isnan(P.x) && !isnan(P.y); }

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
	if (!self) return nil;

	NSInteger version =
	[coder decodeIntegerForKey:WDBezierNodeVersionKey];

	if (version == WDBezierNodeVersion)
		[self readFromCoder:coder];
	else
	if (version == WDBezierNodeVersion0)
		[self readFromCoder0:coder];

#ifdef WD_DEBUG
	NSLog(@"%@",[self description]);
#endif

	if (!CGPointIsValid(anchorPoint_))
	{ anchorPoint_ = CGPointZero; }

	if (!CGPointIsValid(outPoint_))
	{ outPoint_ = anchorPoint_; }

	if (!CGPointIsValid(inPoint_))
	{ inPoint_ = anchorPoint_; }

    return self; 
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder:(NSCoder *)coder
{
	NSString *P;

	P = [coder decodeObjectForKey:WDBezierNodeAnchorPointKey];
	if (P != nil)
	{
		anchorPoint_ =
		outPoint_ =
		inPoint_ = CGPointFromString(P);
	}

	P = [coder decodeObjectForKey:WDBezierNodeOutPointKey];
	if (P != nil) { outPoint_ = CGPointFromString(P); }

	P = [coder decodeObjectForKey:WDBezierNodeInPointKey];
	if (P != nil) { inPoint_ = CGPointFromString(P); }

	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder0:(NSCoder *)coder
{
    const uint8_t *bytes =
	[coder decodeBytesForKey:WDBezierNodePointArrayKey returnedLength:NULL];
    
    CFSwappedFloat32 *swapped = (CFSwappedFloat32 *) bytes;
        
    inPoint_.x = CFConvertFloat32SwappedToHost(swapped[0]);
    inPoint_.y = CFConvertFloat32SwappedToHost(swapped[1]);
    anchorPoint_.x = CFConvertFloat32SwappedToHost(swapped[2]);
    anchorPoint_.y = CFConvertFloat32SwappedToHost(swapped[3]);
    outPoint_.x = CFConvertFloat32SwappedToHost(swapped[4]);
    outPoint_.y = CFConvertFloat32SwappedToHost(swapped[5]);

	return YES;
}

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@:\r%@\r%@\r%@\r", \
	[super description], \
	NSStringFromCGPoint(inPoint_), \
	NSStringFromCGPoint(anchorPoint_), \
	NSStringFromCGPoint(outPoint_)];
}

////////////////////////////////////////////////////////////////////////////////

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



/*
	Oddly enough this is the behavior for UIBezierPath
	but this is not consistent with immutability. 
	
	returning an (autoreleased) mutable copy would be more appropriate
*/
- (void) applyTransform:(CGAffineTransform)T
{
	inPoint_ = CGPointApplyAffineTransform(inPoint_, T);
	anchorPoint_ = CGPointApplyAffineTransform(anchorPoint_, T);
	outPoint_ = CGPointApplyAffineTransform(outPoint_, T);
}


/*
	This would be appropriate, indicating a private method
*/
- (void) _applyTransform:(CGAffineTransform)T
{
	inPoint_ = CGPointApplyAffineTransform(inPoint_, T);
	anchorPoint_ = CGPointApplyAffineTransform(anchorPoint_, T);
	outPoint_ = CGPointApplyAffineTransform(outPoint_, T);
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithTransform:(CGAffineTransform)T
{
	WDBezierNode *node = [self mutableCopy];

	if (node != nil)
	{ [node _applyTransform:T]; }

	return node;
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithInPoint:(CGPoint)P
{
	// If CGPointEqualToPoint(self->inPoint_, P) return self
	
	WDBezierNode *newNode = [self mutableCopy];
	newNode->inPoint_ = P;
	return newNode;
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithOutPoint:(CGPoint)P
{
	WDBezierNode *newNode = [self mutableCopy];
	newNode->outPoint_ = P;
	return newNode;
}

////////////////////////////////////////////////////////////////////////////////


- (WDBezierNode *) setInPoint:(CGPoint)pt reflectionMode:(WDBezierNodeReflectionMode)reflectionMode
{
    CGPoint flippedPoint = WDAddPoints(anchorPoint_, WDSubtractPoints(anchorPoint_, pt));
    // special case when closing a path
    return [self moveControlHandle:kWDInPoint toPoint:flippedPoint reflectionMode:reflectionMode];
}


- (WDBezierNode *) chopHandles
{
    if (!self.hasInPoint && !self.hasOutPoint)
	{ return self; }

	return [WDBezierNode
	bezierNodeWithAnchorPoint:anchorPoint_];
}

- (WDBezierNode *) chopOutHandle
{
	if (!self.hasOutPoint)
	{ return self; }

	return [WDBezierNode
	bezierNodeWithAnchorPoint:anchorPoint_
					 outPoint:anchorPoint_
					  inPoint:inPoint_];
}

- (WDBezierNode *) chopInHandle
{
	if (!self.hasInPoint)
	{ return self; }

	return [WDBezierNode
	bezierNodeWithAnchorPoint:anchorPoint_
					 outPoint:outPoint_
					  inPoint:anchorPoint_];
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
    
//    return [[WDBezierNode alloc] initWithInPoint:inPoint anchorPoint:anchorPoint_ outPoint:outPoint];

	return [WDBezierNode
	bezierNodeWithAnchorPoint:anchorPoint_
					outPoint:outPoint
					inPoint:inPoint];
}

- (WDBezierNode *) flippedNode
{
	return [WDBezierNode
	bezierNodeWithAnchorPoint:self->anchorPoint_
					outPoint:self->inPoint_
					inPoint:self->outPoint_];
}
    
- (void) getAnchorPoint:(CGPoint *)anchorPoint
				outPoint:(CGPoint *)outPoint
				inPoint:(CGPoint *)inPoint
				selected:(BOOL *)selected
{
	if (anchorPoint)
	*anchorPoint = self->anchorPoint_;
	if (outPoint)
	*outPoint = self->outPoint_;
	if (inPoint)
	*inPoint = self->inPoint_;

	if (selected)
	{ *selected = self->selected_; }
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
