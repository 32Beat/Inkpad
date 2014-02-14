////////////////////////////////////////////////////////////////////////////////
/*
	WDShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShape.h"
#import "WDBezierNode.h"
#import "WDUtilities.h"
#import "WDGLUtilities.h"

////////////////////////////////////////////////////////////////////////////////

static int WDShapeMasterVersion = 1;
static NSString *WDShapeMasterVersionKey = @"WDShapeMasterVersion";

static NSString *WDShapeNameKey = @"WDShapeName";
static NSString *WDShapeVersionKey = @"WDShapeVersion";
static NSString *WDShapeSizeKey = @"WDShapeSize";
static NSString *WDShapeRotationKey = @"WDShapeRotation";
static NSString *WDShapePositionKey = @"WDShapePosition";

////////////////////////////////////////////////////////////////////////////////
@implementation WDShape
////////////////////////////////////////////////////////////////////////////////

- (NSString *) shapeName
{ return NSStringFromClass([self class]); }

- (NSInteger) shapeVersion
{ return 0; }

- (NSInteger) shapeOptions
{ return WDShapeOptionsNone; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) shapeWithFrame:(CGRect)frame
{ return [[self alloc] initWithFrame:frame]; }

- (id) initWithFrame:(CGRect)frame
{
	self = [super init];
	if (self != nil)
	{
		[self setFrame:frame];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDShape *shape = [super copyWithZone:zone];
	if (shape != nil)
	{
		[shape takePropertiesFrom:self];
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (void) takePropertiesFrom:(WDShape *)shape
{
	// super...
	[self setSize:shape->mSize];
	[self setPosition:shape->mPosition];
	[self setRotation:shape->mRotation];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Encoding
////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	[coder encodeInteger:WDShapeMasterVersion forKey:WDShapeMasterVersionKey];

	[self encodeTypeWithCoder:coder];
	[self encodeSizeWithCoder:coder];
	[self encodePositionWithCoder:coder];
	[self encodeRotationWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeTypeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[self shapeName] forKey:WDShapeNameKey];
	[coder encodeInteger:[self shapeVersion] forKey:WDShapeVersionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeSizeWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGSize(mSize);
	[coder encodeObject:str forKey:WDShapeSizeKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodePositionWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGPoint(mPosition);
	[coder encodeObject:str forKey:WDShapePositionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeRotationWithCoder:(NSCoder *)coder
{
	NSString *str = sizeof(mRotation) > 32 ?
	[[NSNumber numberWithDouble:mRotation] stringValue]:
	[[NSNumber numberWithFloat:mRotation] stringValue];
	[coder encodeObject:str forKey:WDShapeRotationKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Decoding
////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		mSize = (CGSize){ 2.0, 2.0 };
		mPosition = (CGPoint){ 0.0, 0.0 };
		mRotation = 0.0;

		NSInteger version =
		[coder decodeIntegerForKey:WDShapeMasterVersionKey];

		if (version == WDShapeMasterVersion)
		{ }
		[self decodeWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) decodeWithCoder:(NSCoder *)coder
{
	[self decodeSizeWithCoder:coder];
	[self decodePositionWithCoder:coder];
	[self decodeRotationWithCoder:coder];

	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeSizeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDShapeSizeKey])
	{
		NSString *str = [coder decodeObjectForKey:WDShapeSizeKey];
		if (str != nil) { mSize = CGSizeFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodePositionWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDShapePositionKey])
	{
		NSString *str = [coder decodeObjectForKey:WDShapePositionKey];
		if (str != nil) { mPosition = CGPointFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeRotationWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDShapeRotationKey])
	{
		NSString *str = [coder decodeObjectForKey:WDShapeRotationKey];
		if (str != nil)
		{
			mRotation = sizeof(mRotation)>32 ?
			[str doubleValue] : [str floatValue];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////
/*
	setSize
	-------
	Set size of original source shape
	
	Some shapes do not scale proportionally so instead of 
	applying a scale, flush the source so beziernodes can 
	be rebuild properly .
*/

- (void) setSize:(CGSize)size
{
	if ((mSize.width!=size.width)||
		(mSize.height!=size.height))
	{
		mSize = size;
		[self flushSource];
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	setPosition
	-----------
	Set position of result shape
*/

- (void) setPosition:(CGPoint)P
{
	if ((mPosition.x != P.x)||
		(mPosition.y != P.y))
	{
		mPosition.x = P.x;
		mPosition.y = P.y;
		[self flushResult];
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	setRotation
	-----------
	Set rotation of result shape
*/

- (void) setRotation:(CGFloat)degrees
{
	if (mRotation != degrees)
	{
		mRotation = degrees;
		[self flushResult];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	setFrame
	--------
	Set size and position, reset rotation
*/

- (void) setFrame:(CGRect)frame
{
	[self setSize:frame.size];
	[self setPosition:(CGPoint){ CGRectGetMidX(frame), CGRectGetMidY(frame) }];
	[self setRotation:0.0];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustTransform:(CGAffineTransform)T
{
	// Record current state for undo
	[self saveState];

	// Store update areas
	[self cacheDirtyBounds];

/*
	If we ever want to support numeric transformations,
	we need to limit our transforms to normal rotation, scale, and move.
	
	They currently are, attempt breaking it down.
*/
	// Test for rotation
	if ((T.b != 0.0)||(T.c != 0.0))
	{
		double a1 = atan2(+T.b, +T.a);
		double a2 = atan2(-T.c, +T.d);
		double a = 0.5*(a1+a2);
		double degrees = 180.0*a/M_PI;

		degrees += mRotation;
		[self setRotation:degrees];
	}
	else
	// Test for scale
	if ((T.a != 1.0)||(T.d != 1.0))
	{
		CGSize size = mSize;
		size.width *= T.a;
		size.height *= T.d;
		[self setSize:size];
	}

	// Always move
	CGPoint P = mPosition;
	P = CGPointApplyAffineTransform(P, T);
	[self setPosition:P];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
/*
	TODO: move up in object chain or implement proper hierarchy
*/
- (void) saveState
{
	// Record current properties for undo
	[[self.undoManager prepareWithInvocationTarget:self]
	resetState:[self copy]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) resetState:(WDShape *)shape
{
	if (shape != nil)
	{
		// Save state for redo
		[self saveState];

		// Store update areas
		[self cacheDirtyBounds];

		// Copy properties from shape
		[self takePropertiesFrom:shape];

		// Notify drawingcontroller
		[self postDirtyBoundsChange];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return [self frameRect]; }

- (CGPathRef) pathRef
{ return [self resultPath]; }

- (WDQuad) frameQuad
{
	CGRect B = [self styleBoundsForPath:[self sourcePath]];
	CGAffineTransform T = [self sourceTransform];
	return WDQuadWithRect(B, T);
}


- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)delta
{
	CGPoint P0 = [self frameControlPointAtIndex:n];
	CGPoint P1 = WDAddPoints(P0, delta);

	CGPoint C = mPosition;
	CGPoint D0 = WDSubtractPoints(P0,C);
	CGPoint D1 = WDSubtractPoints(P1,C);

	CGFloat a0 = atan2(D0.y, D0.x);
	CGFloat a1 = atan2(D1.y, D1.x);
	CGFloat da = a1 - a0;

	CGFloat d0 = WDDistance(P0, C);
	CGFloat d1 = WDDistance(P1, C);
	CGFloat d = d0 != 0.0 && d1 != 0.0 ? d1 / d0 : 1.0;

	// Store update areas
	[self cacheDirtyBounds];

	[self setSize:WDScaleSize(mSize, d, d)];
	[self setRotation:mRotation + 180.0*da/M_PI];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (void) flushCache
{
	// [super flushSource];
	[self flushSource];
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushSource
{
	// [self flushBezierNodes];
	mSourceNodes = nil;
	[self flushSourcePath];
	[self flushResult];
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushResult
{
	[self flushResultPath];
	[self flushFramePath];
	[self flushFrameRect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceRect
{ return (CGRect){{-0.5*mSize.width, -0.5*mSize.height}, mSize }; }

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) sourceTransform
{
	CGAffineTransform T =
	{ 1.0, 0.0, 0.0, 1.0, mPosition.x, mPosition.y};

	if (mRotation != 0.0)
	{
		CGFloat angle = mRotation * M_PI / 180.0;
		T.a = cos(angle);
		T.b = sin(angle);
		T.c = -T.b;
		T.d = +T.a;
	}

	return T;
}

////////////////////////////////////////////////////////////////////////////////
/*
	frameRect
	---------
	Returns bounding box of transformed sourcerect
	
	This involves 2 steps: 
	- transforming cornerpoints
	- find the boundingbox of those cornerpoints 
	While this is not in itself computationally expensive, 
	frameRect is used as a basis to compute update regions 
	and may potentially be called several times from more 
	time critical procedures. Hence caching.
*/
- (CGRect) frameRect
{
	return
	mFrameRect.size.width != 0.0 ||
	mFrameRect.size.height != 0.0 ?
	mFrameRect : (mFrameRect = [self computeFrameRect]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeFrameRect
//{ return CGRectApplyAffineTransform([self sourceRect], [self sourceTransform]); }
{ return [self styleBounds]; }

////////////////////////////////////////////////////////////////////////////////

- (void) flushFrameRect
{
	mFrameRect.size.width = 0;
	mFrameRect.size.height = 0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Frame Path
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) framePath
{
	return mFramePath ? mFramePath :
	(mFramePath = [self createFramePath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createFramePath
{
	CGRect B = [self styleBoundsForPath:[self sourcePath]];
	CGAffineTransform T = [self sourceTransform];

	return CGPathCreateWithRect(B, &T);
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushFramePath
{
	if (mFramePath != nil)
	{
		CGPathRelease(mFramePath);
		mFramePath = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Result Path
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) resultPath
{
	return mResultPath ? mResultPath :
	(mResultPath = [self createResultPath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createResultPath
{
	CGPathRef srcPath = [self sourcePath];
	CGAffineTransform T = [self sourceTransform];
	return CGPathCreateCopyByTransformingPath(srcPath, &T);
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushResultPath
{
	if (mResultPath != nil)
	{
		CGPathRelease(mResultPath);
		mResultPath = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Source Path
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) sourcePath
{
	return mSourcePath ? mSourcePath :
	(mSourcePath = [self createSourcePath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createSourcePath
{ return WDCreateCGPathRefWithNodes([self bezierNodes], YES); }

////////////////////////////////////////////////////////////////////////////////

- (void) flushSourcePath
{
	if (mSourcePath != nil)
	{
		CGPathRelease(mSourcePath);
		mSourcePath = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Bezier Nodes
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodes
{ return mSourceNodes ? mSourceNodes : (mSourceNodes=[self createNodes]); }

- (id) createNodes
{ return [self bezierNodesWithShapeInRect:[self sourceRect]]; }

////////////////////////////////////////////////////////////////////////////////
/*
	bezierNodesWithRect
	-------------------
	Create array of WDBezierNode to define shape path within rectangle
	
*/

- (id) bezierNodesWithShapeInRect:(CGRect)R
{ return [[self class] bezierNodesWithShapeInRect:R]; }

+ (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGPoint P0 = R.origin;
	CGPoint P1 = R.origin;
	CGPoint P2 = R.origin;
	CGPoint P3 = R.origin;

	P1.x += R.size.width;
	P2.x += R.size.width;
	P2.y += R.size.height;
	P3.y += R.size.height;

	return @[
	[WDBezierNode bezierNodeWithAnchorPoint:P0],
	[WDBezierNode bezierNodeWithAnchorPoint:P1],
	[WDBezierNode bezierNodeWithAnchorPoint:P2],
	[WDBezierNode bezierNodeWithAnchorPoint:P3]];
}

////////////////////////////////////////////////////////////////////////////////


CGPoint CGRectPointFromNormalizedPoint(CGRect R, CGPoint P)
{
	return (CGPoint){
	R.origin.x + 0.5 * (P.x+1.0) * R.size.width,
	R.origin.y + 0.5 * (1.0-P.y) * R.size.height };
}

////////////////////////////////////////////////////////////////////////////////

+ (id) bezierNodesWithShapeInRect:(CGRect)R
		normalizedPoints:(const CGPoint *)P count:(int)nodeCount
{
	NSMutableArray *nodes = [NSMutableArray array];

	for (int i=0; i!=nodeCount; i++)
	{
		CGPoint A = P[3*i+0];
		CGPoint B = WDAddPoints(A, P[3*i+1]);
		CGPoint C = WDAddPoints(A, P[3*i+2]);

		A = CGRectPointFromNormalizedPoint(R, A);
		B = CGRectPointFromNormalizedPoint(R, B);
		C = CGRectPointFromNormalizedPoint(R, C);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// TODO:remove for better mvc separation
/*
	Make encompassing path object which holds WDShape 
	which acts like a kind of controller on WDShape
	it should handle drawing, and conversion
*/
////////////////////////////////////////////////////////////////////////////////
// TODO: rename to applyTransform: or appendTransform:

- (NSSet *) transform:(CGAffineTransform)T
{
	[super transform:T];

	[self adjustTransform:T];

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (WDPickResult *) hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
	// Test for Stylable hits (particularly gradient anchors)
	WDPickResult *result =
	[super hitResultForPoint:point viewScale:viewScale snapFlags:flags];
	if (result != nil) return result;

	CGFloat hitRadius = kNodeSelectionTolerance / viewScale;
	CGRect hitArea = WDRectFromPoint(point, hitRadius, hitRadius);

	if (CGRectIntersectsRect(hitArea, [self bounds]))
	{
		if ((flags & kWDSnapNodes) || (flags & kWDSnapEdges)) {
			result = WDSnapToRectangle([self bounds], nil, point, viewScale, flags);
			if (result.snapped) {
				result.element = self;
				return result;
			}
		}

		if (flags & kWDSnapFills) {
			if (CGPathContainsPoint(self.pathRef, NULL, point, true)) {
				result.element = self;
				result.type = kWDObjectFill;
				return result;
			}
		}
	}

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawContentWithTransform:(CGAffineTransform)T
{
	WDGLRenderCGPathRef([self resultPath], &T);
}

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)T
{
	[super drawOpenGLHighlightWithTransform:T];
	WDGLRenderCGPathRef([self framePath], &T);
	WDGLRenderCGPathRef([self resultPath], &T);
}

////////////////////////////////////////////////////////////////////////////////
/*
	This would scale styling as well
*/
- (void) ___renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	if (metaData.flags & WDRenderOutlineOnly)
	{
		//[self renderOutlineInContext:ctx metaData:metaData];
	}
	else
	if ([self.strokeStyle willRender] || self.fill || self.maskedElements)
	{
		[self beginTransparencyLayer:ctx metaData:metaData];

CGContextSaveGState(ctx);
CGContextConcatCTM(ctx, [self sourceTransform]);

		if (self.fill) {
			//[self.fill paintPath:self inContext:ctx];
		}
		


		if (self.strokeStyle && [self.strokeStyle willRender]) {
			[self.strokeStyle applyInContext:ctx];
			CGContextAddPath(ctx, self.sourcePath);
			CGContextStrokePath(ctx);
		}


CGContextRestoreGState(ctx);
		[self endTransparencyLayer:ctx metaData:metaData];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






