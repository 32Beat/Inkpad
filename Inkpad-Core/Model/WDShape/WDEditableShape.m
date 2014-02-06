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

static int WDEditableShapeVersion = 1;
static NSString *WDEditableShapeVersionKey = @"WDEditableShapeVersion";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDEditableShape
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) shapeOptions
{ return WDShapeOptionsDefault; }

////////////////////////////////////////////////////////////////////////////////

// Used for encoding/decoding mValue
- (id) paramKey
{ return [NSString stringWithFormat:@"%@%@",[self shapeName],@"PrmValue"]; }

// Called by ShapeOptionsController for slider label
- (id) paramName
{ return @"Value"; } // TODO: localize

// Called by ShapeOptionsController to initialize slider
- (float) paramValue
{ return mValue; }

// Called repeatedly by ShapeOptionsController during slider changes
- (void) setParamValue:(float)value withUndo:(BOOL)shouldUndo
{ [self adjustValue:value withUndo:shouldUndo]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
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

- (void) encodeWithCoder:(NSCoder *)coder
{
	// Encode superclass
	[super encodeWithCoder:coder];

	// Encode this class version
	[coder encodeInt:WDEditableShapeVersion forKey:WDEditableShapeVersionKey];

	// Encode parameter
	[self encodeValueWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeValueWithCoder:(NSCoder *)coder
{
	NSString *str = [[NSNumber numberWithFloat:mValue] stringValue];
	[coder encodeObject:str forKey:[self paramKey]];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		[self decodeValueWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeValueWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:[self paramKey]])
	{
		NSString *str = [coder decodeObjectForKey:[self paramKey]];
		if (str != nil) { mValue = [str floatValue]; }
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) setValue:(float)value
{
	if (mValue != value)
	{
		mValue = value;
		[self flushCache];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustValue:(float)value withUndo:(BOOL)shouldUndo
{
	// Record current value for undo
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

