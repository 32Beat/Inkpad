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
static NSString *WDShapeTransformKey = @"WDShapeTransform";

////////////////////////////////////////////////////////////////////////////////
@implementation WDShape
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
		shape->mSize = self->mSize;
		shape->mPosition = self->mPosition;
		shape->mRotation = self->mRotation;
		shape->mTransform = self->mTransform;
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) shapeName
{ return NSStringFromClass([self class]); }

- (NSInteger) shapeVersion
{ return 0; }

- (NSInteger) shapeOptions
{ return WDShapeOptionsNone; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Encoding
////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	[coder encodeInteger:WDShapeMasterVersion forKey:WDShapeMasterVersionKey];

	[coder encodeObject:[self shapeName] forKey:WDShapeNameKey];
	[coder encodeInteger:[self shapeVersion] forKey:WDShapeVersionKey];
	[self encodeSizeWithCoder:coder];
	[self encodePositionWithCoder:coder];
	[self encodeRotationWithCoder:coder];
	[coder encodeCGAffineTransform:mTransform forKey:WDShapeTransformKey];
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

		mTransform = CGAffineTransformIdentity;

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
#pragma mark Model Data
////////////////////////////////////////////////////////////////////////////////
/*
	setSize
	-------
	Set size of original source shape
	
	Some shapes do not scale proportionally so instead of 
	applying a scale, this will flush the source so beziernodes
	can be rebuild accordingly .
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
	
	Regardless of transform, position always overwrites translation.
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
	Set rotation of original source shape
	
	Additional transform may append additional rotation.
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

- (CGAffineTransform) computeSourceTransform
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

- (void) setPosition:(CGPoint)P withUndo:(BOOL)shouldUndo
{
	// Record current bounds for undo
	if (shouldUndo != NO)
	[[self.undoManager prepareWithInvocationTarget:self]
	setPosition:mPosition withUndo:YES];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new position
	[self setPosition:P];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) transform
{ return mTransform; }

- (void) setTransform:(CGAffineTransform)T
{
	mTransform = T;
	[self flushResult];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustTransform:(CGAffineTransform)T
{
	// Record current bounds for undo
	[[self.undoManager prepareWithInvocationTarget:self] adjustTransform:mTransform];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new bounds
	if ((T.a != 1.0)||
		(T.b != 0.0)||
		(T.c != 0.0)||
		(T.d != 1.0))

	{ [self setTransform:T]; }
	else
	{ [self setPosition:(CGPoint){ T.tx, T.ty }]; }

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustOptions:(NSDictionary *)options
{
	
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return [self frameRect]; }

- (CGPathRef) pathRef
{ return [self resultPath]; }

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
//	[self flushSourceRect];
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

- (const CGAffineTransform *) sourceTransform
{
	mTransform = [self computeSourceTransform];
	return &mTransform;
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
{ return CGRectApplyAffineTransform([self sourceRect], [self sourceTransform][0]); }

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
	return CGPathCreateWithRect([self sourceRect], [self sourceTransform]);
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
	return CGPathCreateCopyByTransformingPath([self sourcePath], [self sourceTransform]);
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

static const CGPoint _PreparePoint(CGPoint P, CGPoint M, CGPoint V)
{ return (CGPoint){ P.x+M.x*V.x, P.y+M.y*V.y }; }

+ (id) bezierNodesWithShapeInRect:(CGRect)R
		normalizedPoints:(const CGPoint *)P count:(int)nodeCount
{
	CGPoint M = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint N = { R.origin.x + M.x, R.origin.y + M.y };

	M.y = -M.y; // Flip for SVG

	NSMutableArray *nodes = [NSMutableArray array];

	for (int i=0; i!=nodeCount; i++)
	{
		CGPoint A = _PreparePoint(N, M, P[3*i+0]);
		CGPoint B = _PreparePoint(A, M, P[3*i+1]);
		CGPoint C = _PreparePoint(A, M, P[3*i+2]);

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

//	T = CGAffineTransformConcat([self sourceTransform], T);
//	T = CGAffineTransformConcat(mTransform, T);
//	[self adjustTransform:T];
	CGPoint P = mPosition;
	P.x += T.tx;
	P.y += T.ty;
	[self setPosition:P withUndo:YES];

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
/*
	transform is an additional transform because the user is currently 
	in the act of moving, scaling, or rotating
	
	viewTransform is an additional transform for current zoom&focus
*/

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform
							viewTransform:(CGAffineTransform)viewTransform
{
	[super drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];

	CGAffineTransform T = CGAffineTransformConcat(transform, viewTransform);
	WDGLRenderCGPathRefWithTransform([self framePath], T);
	WDGLRenderCGPathRefWithTransform([self resultPath], T);
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
CGContextConcatCTM(ctx, mTransform);

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






