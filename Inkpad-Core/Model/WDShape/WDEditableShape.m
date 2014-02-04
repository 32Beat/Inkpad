////////////////////////////////////////////////////////////////////////////////
/*
	WDEditableShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDEditableShape.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

static NSInteger WDEditableShapeVersion = 1;
static NSString *WDEditableShapeVersionKey = @"WDEditableShapeVersion";
static NSString *WDParamVersionKey = @"WDParamVersion";
static NSString *WDParamValueKey = @"WDParamValue";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDEditableShape
////////////////////////////////////////////////////////////////////////////////

- (long) shapeOptions
{ return WDShapeOptionsDefault; }

////////////////////////////////////////////////////////////////////////////////

- (id) paramName
{ return @"Value"; } // TODO: localize

- (int) paramVersion
{ return 0; }

- (float) paramValue
{ return mValue; }

- (void) setParamValue:(float)value withUndo:(BOOL)shouldUndo
{ [self adjustValue:value withUndo:shouldUndo]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) initWithBounds:(CGRect)bounds
{
	self = [super initWithBounds:bounds];
	if (self != nil)
	{
		mValue = 0.25;
		// may init from user defaults using classname
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDEditableShape *shape = [super copyWithZone:zone];
	if (shape != nil)
	{
		shape->mValue = self->mValue;
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

	[coder encodeInteger:WDEditableShapeVersion forKey:WDEditableShapeVersionKey];
	[coder encodeInteger:[self paramVersion] forKey:WDParamVersionKey];

	NSString *V = NSStringFromCGFloat(mValue);
	[coder encodeObject:V forKey:WDParamValueKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		NSString *V = [coder decodeObjectForKey:WDParamValueKey];
		if (V != nil) { mValue = [V doubleValue]; }
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) setValue:(CGFloat)value
{
	mValue = value;
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustValue:(CGFloat)value withUndo:(BOOL)shouldUndo
{
	// Record current radius for undo
	if (shouldUndo)
	[[self.undoManager prepareWithInvocationTarget:self]
	adjustValue:mValue withUndo:YES];

	// Store update areas
	[self cacheDirtyBounds];

	// Set new value
	[self setValue:value];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Protocol
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithShapeInRect:(CGRect)R
{
	CGPoint M = { 0.5*R.size.width, 0.5*R.size.height };
	CGPoint N = { R.origin.x + M.x, R.origin.y + M.y };
	CGPoint A, B, C;

	double t = mValue;
	double r = (1-t) * kWDShapeCircleFactor; // circlefactor length

	NSMutableArray *nodes = [NSMutableArray array];

	[nodes addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:N]];

	double a = t * M_PI;
	double da = 0.5 * (M_PI - a);
	for (long n=0; n!=5; n++)
	{
		double dx = cos(a);
		double dy = sin(a);
		a += da;

		A.x = N.x + M.x * dx;
		A.y = N.y + M.y * dy;

		B.x = A.x - M.x * dy * r * (n!=4);
		B.y = A.y + M.y * dx * r * (n!=4);

		C.x = A.x + M.x * dy * r * (n!=0);
		C.y = A.y - M.y * dx * r * (n!=0);

		[nodes addObject:
		[WDBezierNode bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////

