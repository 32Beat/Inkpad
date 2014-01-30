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

////////////////////////////////////////////////////////////////////////////////
@implementation WDShape
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

- (void) dealloc
{
	if (mPathRef != nil)
	{ CGPathRelease(mPathRef); }
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return mBounds; }

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






