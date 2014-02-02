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

static NSString *WDShapeVersionKey = @"WDShapeVersion";

static NSInteger WDShapeVersion = 1;
static NSString *WDShapeTypeKey = @"WDShapeType";
static NSString *WDShapeSizeKey = @"WDShapeSize";
static NSString *WDShapeBoundsKey = @"WDShapeBounds";
static NSString *WDShapeTransformKey = @"WDShapeTransform";

////////////////////////////////////////////////////////////////////////////////
@implementation WDShape
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) shapeWithBounds:(CGRect)bounds
{ return [[self alloc] initWithBounds:bounds]; }

- (id) initWithBounds:(CGRect)bounds
{
	self = [super init];
	if (self != nil)
	{
		mTransform =
		(CGAffineTransform)
		{ 1.0, 0.0, 0.0, 1.0,
		CGRectGetMidX(bounds),
		CGRectGetMidY(bounds) };

		mSize = bounds.size;
//		mTransform = CGAffineTransformIdentity;
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
		shape->mTransform = self->mTransform;
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (WDShapeType) shapeType
{ return mType; }

- (NSString *) shapeTypeName
{ return @"WDShapeTypeRectangle"; }

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	[coder encodeInteger:WDShapeVersion forKey:WDShapeVersionKey];
	[coder encodeInteger:mType forKey:WDShapeTypeKey];
	[coder encodeCGSize:mSize forKey:WDShapeSizeKey];
	[coder encodeCGAffineTransform:mTransform forKey:WDShapeTransformKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		mTransform = CGAffineTransformIdentity;

		NSInteger version =
		[coder decodeIntegerForKey:WDShapeVersionKey];

		if (version == WDShapeVersion)
			[self readFromCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder:(NSCoder *)coder
{
	//NSString *T = [coder decodeObjectForKey:WDShapeTypeKey];
	//if (T != nil) { mType = [T integerValue]; }

	if ([coder containsValueForKey:WDShapeSizeKey])
	{ mSize = [coder decodeCGSizeForKey:WDShapeSizeKey]; }
	else
	if ([coder containsValueForKey:WDShapeBoundsKey])
	{ mSize = [coder decodeCGRectForKey:WDShapeBoundsKey].size; }

	if ([coder containsValueForKey:WDShapeTransformKey])
	{ mTransform = [coder decodeCGAffineTransformForKey:WDShapeTransformKey]; }

	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Parameters
////////////////////////////////////////////////////////////////////////////////

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

- (void) setPosition:(CGPoint)P
{
	if ((mTransform.tx != P.x)||
		(mTransform.ty != P.y))
	{
		mTransform.tx = P.x;
		mTransform.ty = P.y;
		[self flushResult];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFrame:(CGRect)frame
{
	mSize = frame.size;
	[self flushCache];
}


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
	[self setTransform:T];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
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
	[self flushBoundsPath];
	[self flushResultPath];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceRect
{ return (CGRect){{-0.5*mSize.width, -0.5*mSize.height}, mSize }; }

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) sourcePath
{
	return mSourcePath ? mSourcePath :
	(mSourcePath = [self createSourcePath]);
}

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
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return [self computeBounds]; }

- (CGRect) computeBounds
{ return CGRectApplyAffineTransform([self sourceRect], mTransform); }

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) boundsPath
{
	return mBoundsPath ? mBoundsPath :
	(mBoundsPath = [self createBoundsPath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createBoundsPath
{ return CGPathCreateWithRect([self sourceRect], &mTransform); }

////////////////////////////////////////////////////////////////////////////////

- (void) flushBoundsPath
{
	if (mBoundsPath != nil)
	{
		CGPathRelease(mBoundsPath);
		mBoundsPath = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) pathRef
{ return [self resultPath]; }

- (CGPathRef) resultPath
{
	return mResultPath ? mResultPath :
	(mResultPath = [self createResultPath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createResultPath
{ return CGPathCreateCopyByTransformingPath([self sourcePath], &mTransform); }

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
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// TODO: rename to applyTransform:

- (NSSet *) transform:(CGAffineTransform)T
{
	[super transform:T];

	T = CGAffineTransformConcat(mTransform, T);
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
	WDGLRenderCGPathRefWithTransform([self boundsPath], T);
	WDGLRenderCGPathRefWithTransform([self resultPath], T);
}

////////////////////////////////////////////////////////////////////////////////
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
#pragma mark -
#pragma mark Cached Parameters
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodes
{ return mSourceNodes ? mSourceNodes : (mSourceNodes=[self createNodes]); }

- (id) createNodes
{ return [self bezierNodesWithRect:[self sourceRect]]; }

////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithRect:(CGRect)R
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

- (NSArray *) segmentNodes
{ return [[self bezierNodes] arrayByAddingObject:[[self bezierNodes] firstObject]]; }

- (CGPathRef) createSourcePath
{ return [self createPathRefWithNodes:[self segmentNodes]]; }

- (CGPathRef) createPathRefWithNodes:(NSArray *)nodes
{
	CGMutablePathRef pathRef = CGPathCreateMutable();
	if (pathRef != nil)
	{
		WDBezierNode *lastNode = nil;
		for (WDBezierNode *nextNode in nodes)
		{
			CGPathAddSegmentWithNodes(pathRef, lastNode, nextNode);
			lastNode = nextNode;
		}

		// For closed path, objectptr is copied
		if (nodes.firstObject==nodes.lastObject)
		{ CGPathCloseSubpath(pathRef); }
	}

	return pathRef;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (long) shapeTypeOptions
{ return WDShapeOptionsNone; }

- (float) paramValue
{ return 0.0; }

- (void) setParamValue:(float)value
{ }

- (void) prepareSetParamValue
{ }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






