////////////////////////////////////////////////////////////////////////////////
/*
	WDBezierNode.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDBezierNode.h"

#import "UIColor+Additions.h"
#import "WDGLUtilities.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

static NSString *WDBezierNodeVersionKey = @"WDBezierNodeVersion";

static NSInteger WDBezierNodeVersion = 1;
static NSString *WDBezierNodeAnchorPointKey = @"WDBezierNodeAnchorPoint";
static NSString *WDBezierNodeOutPointKey = @"WDBezierNodeOutPoint";
static NSString *WDBezierNodeInPointKey = @"WDBezierNodeInPoint";

static NSInteger WDBezierNodeVersion0 = 0;
static NSString *WDBezierNodePointArrayKey = @"WDPointArrayKey";

////////////////////////////////////////////////////////////////////////////////
@implementation WDBezierNode
////////////////////////////////////////////////////////////////////////////////

@synthesize anchorPoint = anchorPoint_;
@synthesize outPoint = outPoint_;
@synthesize inPoint = inPoint_;
@synthesize selected = selected_;

////////////////////////////////////////////////////////////////////////////////
// Deprecated
+ (WDBezierNode *) bezierNodeWithInPoint:(CGPoint)C
							anchorPoint:(CGPoint)A
							outPoint:(CGPoint)B
{ return [self bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]; }

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
/*
	If WDBezierNodes are truly immutable, which the read-only vars suggest, 
	then we can simply return "self" in copyWithZone, and only create a true
	copy if a mutable version is requested.
*/

- (id) copyWithZone:(NSZone *)zone
{
	return self;

//	return [self mutableCopyWithZone:zone];
}

- (id) mutableCopyWithZone:(NSZone *)zone
{
	WDBezierNode *node = [WDBezierNode new];
	if (node != nil)
	{
		node->anchorPoint_ = self->anchorPoint_;
		node->outPoint_ = self->outPoint_;
		node->inPoint_ = self->inPoint_;
		node->selected_ = self->selected_;
	}

	return node;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) isEqual:(WDBezierNode *)node
{
	if (node == self)
	{ return YES; }

	return [node isKindOfClass:[self class]]&&
	CGPointEqualToPoint(self->anchorPoint_, node->anchorPoint_) &&
	CGPointEqualToPoint(self->outPoint_, node->outPoint_)&&
	CGPointEqualToPoint(self->inPoint_, node->inPoint_);
}

////////////////////////////////////////////////////////////////////////////////

static inline BOOL CGPointIsValid(CGPoint P)
{ return !isnan(P.x) && !isnan(P.y); }

- (BOOL) isValid
{
	return
	CGPointIsValid(self->anchorPoint_)&&
	CGPointIsValid(self->outPoint_)&&
	CGPointIsValid(self->inPoint_);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) recoverContents
{
	long bitMask =
	CGPointIsValid(self->anchorPoint_)+
	2*CGPointIsValid(self->outPoint_)+
	4*CGPointIsValid(self->inPoint_);

	// Test for valid anchorpoint, recover handles if necessary
	if (bitMask & 0x01)
	{
		if ((bitMask & 0x02) == 0)
		{ self->outPoint_ = self->anchorPoint_; }
		if ((bitMask & 0x04) == 0)
		{ self->inPoint_ = self->anchorPoint_; }
	}
	else
	// Test for 2 valid handles, must recover anchor
	if (bitMask == 6)
	{
		self->anchorPoint_ =
		WDInterpolatePoints(self->inPoint_, self->outPoint_, 0.5);
	}
	else
	// Must recover anchor & out
	if (bitMask == 4)
	{
		self->anchorPoint_ = self->inPoint_;
		self->outPoint_ = self->inPoint_;
	}
	else
	// Must recover anchor & in
	if (bitMask == 2)
	{
		self->anchorPoint_ = self->outPoint_;
		self->inPoint_ = self->outPoint_;
	}
	else
	{
		self->anchorPoint_ =
		self->outPoint_ =
		self->inPoint_ = CGPointZero;
	}

	// Invert bitMask: bits then indicate recovered values
	self->state_ = bitMask^0x07;

	// Report recoverability
	return bitMask != 7;
}

////////////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder
{
	// Save format version
	[coder encodeInteger:WDBezierNodeVersion forKey:WDBezierNodeVersionKey];

	// Save Anchorpoint
	NSString *A = NSStringFromCGPoint(anchorPoint_);
	[coder encodeObject:A forKey:WDBezierNodeAnchorPointKey];

	// Save outPoint if necessary
	if ([self hasOutPoint])
	{
		NSString *B = NSStringFromCGPoint(outPoint_);
		[coder encodeObject:B forKey:WDBezierNodeOutPointKey];
	}

	// Save inPoint if necessary
	if ([self hasInPoint])
	{
		NSString *C = NSStringFromCGPoint(inPoint_);
		[coder encodeObject:C forKey:WDBezierNodeInPointKey];
	}
}

////////////////////////////////////////////////////////////////////////////////

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

	// Test for valid node
	if ([self isValid])
	{ return self; }


#ifdef WD_DEBUG
NSLog(@"%@",[self description]);
#endif

	// Test for recoverability
	if ([self recoverContents])
	{ return self; }

	//TODO: corrupt file notification stategy
    return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder:(NSCoder *)coder
{
	// Read anchorPoint first, must be present
	NSString *P = [coder decodeObjectForKey:WDBezierNodeAnchorPointKey];
	if (P == nil) { return NO; } 

	// Assign to all
	anchorPoint_ =
	outPoint_ =
	inPoint_ = CGPointFromString(P);

	// Assign outPoint if available
	P = [coder decodeObjectForKey:WDBezierNodeOutPointKey];
	if (P != nil) { outPoint_ = CGPointFromString(P); }

	// Assign inPoint if available
	P = [coder decodeObjectForKey:WDBezierNodeInPointKey];
	if (P != nil) { inPoint_ = CGPointFromString(P); }

	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder0:(NSCoder *)coder
{
	NSUInteger length = 0;
    const uint8_t *bytes =
	[coder decodeBytesForKey:WDBezierNodePointArrayKey returnedLength:&length];

    if ((bytes != nil) && (length >= 6*sizeof(CFSwappedFloat32)))
	{
		CFSwappedFloat32 *swapped = (CFSwappedFloat32 *) bytes;
			
		inPoint_.x = CFConvertFloat32SwappedToHost(swapped[0]);
		inPoint_.y = CFConvertFloat32SwappedToHost(swapped[1]);
		anchorPoint_.x = CFConvertFloat32SwappedToHost(swapped[2]);
		anchorPoint_.y = CFConvertFloat32SwappedToHost(swapped[3]);
		outPoint_.x = CFConvertFloat32SwappedToHost(swapped[4]);
		outPoint_.y = CFConvertFloat32SwappedToHost(swapped[5]);

		return YES;
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@:\r\tA:%@\r\to:%@\r\ti:%@\r", \
	[super description], \
	NSStringFromCGPoint(anchorPoint_), \
	NSStringFromCGPoint(outPoint_), \
	NSStringFromCGPoint(inPoint_)];
}

////////////////////////////////////////////////////////////////////////////////
/*
	Perhaps another reflectionMode:
	1. Adjusting outPoint always adjusts inPoint (preserve angle)
	2. Adjusting inPoint always independent
*/

- (WDBezierNodeReflectionMode) reflectionMode
{
	if ([self hasInPoint]&&[self hasOutPoint])
	{
		if (!CGPointEqualToPoint(outPoint_, inPoint_))
		{
			CGFloat r = WDCollinearity(anchorPoint_, outPoint_, inPoint_);
			CGFloat d = WDDistance(outPoint_, inPoint_);

			if ((r/d) < 1.0e-3)
			{ return WDReflectIndependent; }
		}
	}

	return WDIndependent;
}

////////////////////////////////////////////////////////////////////////////////

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
- (id) applyTransform:(CGAffineTransform)T
{
	return [[self mutableCopy] _applyTransform:T];
}


/*
	This would be appropriate, indicating a private method
*/
- (id) _applyTransform:(CGAffineTransform)T
{
	anchorPoint_ = CGPointApplyAffineTransform(anchorPoint_, T);
	outPoint_ = CGPointApplyAffineTransform(outPoint_, T);
	inPoint_ = CGPointApplyAffineTransform(inPoint_, T);
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithTransform:(CGAffineTransform)T
{
	return [[self mutableCopy] _applyTransform:T];
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithNewOutPoint:(CGPoint)P
{
	WDBezierNode *node = [self mutableCopy];
	if (node != nil)
	{ node->outPoint_ = P; }

	return node;
}

////////////////////////////////////////////////////////////////////////////////

- (WDBezierNode *) copyWithNewInPoint:(CGPoint)P
{
	// If CGPointEqualToPoint(self->inPoint_, P) return self
	
	WDBezierNode *node = [self mutableCopy];
	if (node != nil)
	{ node->inPoint_ = P; }

	return node;
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
	{ *anchorPoint = self->anchorPoint_; }
	if (outPoint)
	{ *outPoint = self->outPoint_; }
	if (inPoint)
	{ *inPoint = self->inPoint_; }

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
		[[UIColor whiteColor] openGLSet];
		WDGLStrokeSquareMarker(A);
	}
	else
	{
		[[UIColor whiteColor] openGLSet];
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
