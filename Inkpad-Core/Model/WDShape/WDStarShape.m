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

static NSInteger WDParamVersion = 1;
static NSString *WDParamVersionKey = @"WDStarShapeVersion";
static NSString *WDParamPointCountKey = @"WDStarShapePointCount";
static NSString *WDParamInnerRadiusKey = @"WDStarShapeInnerRadius";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStarShape
////////////////////////////////////////////////////////////////////////////////

- (long) shapeOptions
{ return WDShapeOptionsCustom; }

////////////////////////////////////////////////////////////////////////////////

- (id) initWithBounds:(CGRect)bounds
{
	self = [super initWithBounds:bounds];
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

#define NSStringFromCGFloat(v) (sizeof(v)>32)? \
[[NSNumber numberWithDouble:v] stringValue]:\
[[NSNumber numberWithFloat:v] stringValue]

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	// Save parameters version
	[coder encodeInteger:WDParamVersion forKey:WDParamVersionKey];

	// Save point count
	NSString *N = [[NSNumber numberWithInteger:mCount] stringValue];
	[coder encodeObject:N forKey:WDParamPointCountKey];

	// Save inner radius
	NSString *R = NSStringFromCGFloat(mRadius);
	[coder encodeObject:R forKey:WDParamInnerRadiusKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		NSString *N = [coder decodeObjectForKey:WDParamPointCountKey];
		if (N != nil) { mCount = [N integerValue]; }
		NSString *R = [coder decodeObjectForKey:WDParamInnerRadiusKey];
		if (R != nil) { mRadius = [R doubleValue]; }
	}

	return self;
}

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
		double a = 2.0*M_PI*n/N;
		double x = mx * sin(a);
		double y = my * cos(a);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:(CGPoint){ x, y }]];

		a = 2.0*M_PI*(2*n+1)/(2*N);
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
