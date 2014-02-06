////////////////////////////////////////////////////////////////////////////////
/*
	WDStarShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStarShape.h"

////////////////////////////////////////////////////////////////////////////////

static NSInteger WDStarShapeVersion = 1;
static NSString *WDParamPointCountKey = @"WDStarShapePointCount";
static NSString *WDParamInnerRadiusKey = @"WDStarShapeInnerRadius";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStarShape
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) shapeVersion
{ return WDStarShapeVersion; }

- (NSInteger) shapeOptions
{ return WDShapeOptionsCustom; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self != nil)
	{
		mCount = 5;
		mRadius = 0.25;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDStarShape *shape = [super copyWithZone:zone];
	if (shape != nil)
	{
		shape->mCount = self->mCount;
		shape->mRadius = self->mRadius;
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	[self encodePointCountWithCoder:coder];
	[self encodeInnerRadiusWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodePointCountWithCoder:(NSCoder *)coder
{
	NSString *str = [[NSNumber numberWithInteger:mCount] stringValue];
	[coder encodeObject:str forKey:WDParamPointCountKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeInnerRadiusWithCoder:(NSCoder *)coder
{
	NSString *str = [[NSNumber numberWithFloat:mRadius] stringValue];
	[coder encodeObject:str forKey:WDParamInnerRadiusKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		[self decodePointCountWithCoder:coder];
		[self decodeInnerRadiusWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodePointCountWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDParamPointCountKey])
	{
		NSString *str = [coder decodeObjectForKey:WDParamPointCountKey];
		if (str != nil) { mCount = [str integerValue]; }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeInnerRadiusWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDParamInnerRadiusKey])
	{
		NSString *str = [coder decodeObjectForKey:WDParamInnerRadiusKey];
		if (str != nil) { mRadius = [str floatValue]; }
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (long) pointCount
{ return mCount; }

- (void) setPointCount:(long)count
{
	mCount = count;
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

- (float) innerRadius
{ return mRadius; }

- (void) setInnerRadius:(float)radius
{
	mRadius = radius;
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustPointCount:(long)count
{ [self adjustPointCount:count withUndo:YES]; }

- (void) adjustPointCount:(long)count withUndo:(BOOL)shouldUndo
{
	// Record undo
	if (shouldUndo)
	[[self.undoManager prepareWithInvocationTarget:self]
	adjustPointCount:mCount withUndo:YES];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new radius
	[self setPointCount:count];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustInnerRadius:(float)radius
{ [self adjustInnerRadius:radius withUndo:YES]; }

- (void) adjustInnerRadius:(float)radius withUndo:(BOOL)shouldUndo
{
	// Record undo
	if (shouldUndo)
	[[self.undoManager prepareWithInvocationTarget:self]
	adjustInnerRadius:mRadius withUndo:YES];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new radius
	[self setInnerRadius:radius];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Protocol
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGFloat mx = 0.5 * R.size.width;
	CGFloat my = 0.5 * R.size.height;
	CGFloat r = mRadius;

	NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:2*mCount];

	long N = mCount <= 3 ? 3 : mCount;
	for (long n=0; n!=N; n++)
	{
		double a = M_PI*(2*n+0)/N;
		double x = mx * sin(a);
		double y = my * cos(a);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:(CGPoint){ x, y }]];

		a = M_PI*(2*n+1)/N;
		x = r * mx * sin(a);
		y = r * my * cos(a);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:(CGPoint){ x, y }]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
