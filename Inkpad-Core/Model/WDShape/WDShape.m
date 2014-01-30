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
static NSString *WDShapeBoundsKey = @"WDShapeBounds";

////////////////////////////////////////////////////////////////////////////////
@implementation WDShape
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	if (mPathRef != nil)
	{ CGPathRelease(mPathRef); }
	mPathRef = nil;
}

////////////////////////////////////////////////////////////////////////////////

+ (id) shapeWithBounds:(CGRect)bounds
{ return [[self alloc] initWithBounds:bounds]; }

- (id) initWithBounds:(CGRect)bounds
{
	self = [super init];
	if (self != nil)
	{
		mBounds = bounds;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDShape *shape = [super copyWithZone:zone];
	if (shape != nil)
	{
		shape->mBounds = self->mBounds;
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) shapeTypeName
{
	return @"WDShapeTypeRectangle";
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	[coder encodeInteger:WDShapeVersion forKey:WDShapeVersionKey];

	NSString *T = [[NSNumber numberWithLong:mType] stringValue];
	[coder encodeObject:T forKey:WDShapeTypeKey];

	NSString *B = NSStringFromCGRect(mBounds);
	[coder encodeObject:B forKey:WDShapeBoundsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
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

	NSString *B = [coder decodeObjectForKey:WDShapeBoundsKey];
	if (B == nil) return NO;

	mBounds = CGRectFromString(B);

	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Parameters
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return mBounds; }

- (void) setBounds:(CGRect)bounds
{
	mBounds = bounds;
	[self resetPath];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustBounds:(CGRect)bounds
{
	// Record current bounds for undo
	[[self.undoManager prepareWithInvocationTarget:self] adjustBounds:mBounds];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new bounds
	[self setBounds:bounds];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// TODO: rename to applyTransform:

- (NSSet *) transform:(CGAffineTransform)T
{
	[super transform:T];
	// Set new bounds
	[self adjustBounds:CGRectApplyAffineTransform(mBounds, T)];

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

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform
							viewTransform:(CGAffineTransform)viewTransform
{
	[super drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];

	CGAffineTransform T = CGAffineTransformConcat(transform, viewTransform);
	CGPathRef pathRef = CGPathCreateCopyByTransformingPath([self pathRef], &T);
	if (pathRef != nil)
	{
		WDGLRenderCGPathRef(pathRef);
		CGPathRelease(pathRef);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Cached Parameters
////////////////////////////////////////////////////////////////////////////////

- (void) resetPath
{
	CGPathRelease(mPathRef);
	mPathRef = nil;
	mNodes = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (id) nodes
{ return mNodes ? mNodes : (mNodes=[self createNodes]); }

- (id) createNodes
{
	mNodes=[NSMutableArray new];
	[self prepareNodes];
	return mNodes.count ? mNodes : nil;
}

- (void) prepareNodes
{
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) pathRef
{ return mPathRef ? mPathRef : (mPathRef = [self createPathRef]); }

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
{ return [[self nodes] arrayByAddingObject:[[self nodes] firstObject]]; }

- (CGMutablePathRef) createPathRef
{ return [self createPathRefWithNodes:[self segmentNodes]]; }

- (CGMutablePathRef) createPathRefWithNodes:(NSArray *)nodes
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
@end
////////////////////////////////////////////////////////////////////////////////






