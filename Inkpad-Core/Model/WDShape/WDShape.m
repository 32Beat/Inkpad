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

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Encoding
////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	[coder encodeObject:[self shapeName] forKey:WDShapeNameKey];
	[coder encodeInteger:[self shapeVersion] forKey:WDShapeVersionKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) contentPath
{ return self.resultPath; }

////////////////////////////////////////////////////////////////////////////////

- (WDQuad) frameQuad
{
	return WDQuadWithRect([self sourceStrokeBounds], [self sourceTransform]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceStrokeBounds
{
	if (CGRectIsEmpty(mSourceStrokeBounds))
	{ mSourceStrokeBounds = [self computeSourceStrokeBounds]; }
	return mSourceStrokeBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeSourceStrokeBounds
{
	CGRect R = self.strokeOptions != nil ?
	[self.strokeOptions resultAreaForPath:[self sourcePath]
	scale:1.0/[self resizeScale]]:
	[self sourceRect];

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultStrokeBounds
{
	if (CGRectIsEmpty(mResultStrokeBounds))
	{ mResultStrokeBounds = [self computeResultStrokeBounds]; }
	return mResultStrokeBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeResultStrokeBounds
{
	CGRect R = self.strokeOptions != nil ?
	[self.strokeOptions resultAreaForPath:[self resultPath]]:
	[self frameBounds];

	return R;
}

////////////////////////////////////////////////////////////////////////////////
/*
	For an arbitrary path the bounding box of the resultPath
	has no direct relation to the bounding box of the sourcePath 
*/
- (CGRect) computeStyleBounds
{
	CGRect R = [self frameBounds];

	if (self.strokeOptions != nil)
	{ R = [self.strokeOptions resultAreaForPath:[self resultPath]]; }

	if (self.shadowOptions != nil)
	{ R = [self.shadowOptions resultAreaForRect:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushCache
{
	mSourceNodes = nil;
	
	[self flushSourcePath];
	mSourceStrokeBounds = CGRectZero;

	[self flushResultPath];
	mResultStrokeBounds = CGRectZero;

	[super flushCache];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
- (CGSize) sourceSize
{ return (CGSize){ 2.0, 2.0 }; }

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) computeSourceTransform
{
	CGAffineTransform T = [super computeSourceTransform];

	CGSize size = [self size];
	CGFloat sx = size.width / [self sourceSize].width;
	CGFloat sy = size.height / [self sourceSize].height;

	T = CGAffineTransformScale(T, sx, -sy);

	return T;
}
*/
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
/*
- (CGRect) frameRect
{
	return
	mFrameRect.size.width != 0.0 ||
	mFrameRect.size.height != 0.0 ?
	mFrameRect : (mFrameRect = [self computeFrameRect]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeFrameRect
{ return [self styleBounds]; }

////////////////////////////////////////////////////////////////////////////////

- (void) flushFrameRect
{
	mFrameRect.size.width = 0;
	mFrameRect.size.height = 0;
}
*/
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

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






