////////////////////////////////////////////////////////////////////////////////
/*
	WDRectangleShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDRectangleShape.h"
#import "WDBezierNode.h"

static NSString *WDShapeTypeNameRectangle = @"WDShapeTypeRectangle";
static NSString *WDShapeCornerRadiusKey = @"WDShapeCornerRadius";

////////////////////////////////////////////////////////////////////////////////
@implementation WDRectangleShape
////////////////////////////////////////////////////////////////////////////////

- (id) initWithBounds:(CGRect)bounds
{
	self = [super initWithBounds:bounds];
	if (self != nil)
	{
		mType = WDShapeTypeRectangle;
		mRadius = 0.25;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDRectangleShape *shape = [super copyWithZone:zone];
	if (shape != nil)
	{
		shape->mRadius = self->mRadius;
	}

	return shape;
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) shapeTypeName
{ return WDShapeTypeNameRectangle; }

////////////////////////////////////////////////////////////////////////////////

#define NSStringFromCGFloat(v) (sizeof(v)>32)? \
[[NSNumber numberWithDouble:v] stringValue]:\
[[NSNumber numberWithFloat:v] stringValue]

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];

	NSString *R = NSStringFromCGFloat(mRadius);
	[coder encodeObject:R forKey:WDShapeCornerRadiusKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		NSString *R = [coder decodeObjectForKey:WDShapeCornerRadiusKey];
		if (R != nil) { mRadius = [R doubleValue]; }
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setRadius:(CGFloat)radius
{
	mRadius = radius;
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustRadius:(CGFloat)radius
{
	// Record current radius for undo
	[[self.undoManager prepareWithInvocationTarget:self] adjustRadius:mRadius];
	[self _adjustRadius:radius];
}

- (void) _adjustRadius:(CGFloat)radius
{
	// Store update areas
	[self cacheDirtyBounds];

	// Set new radius
	[self setRadius:radius];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////

- (long) shapeTypeOptions
{ return WDShapeOptionsDefault; }


- (id) paramName
{ return @"Corner Radius"; } // TODO: localize

- (float) paramValue
{ return mRadius; }

- (void) setParamValue:(float)value
{ [self _adjustRadius:value]; }

- (void) prepareSetParamValue
{ [[self.undoManager prepareWithInvocationTarget:self] adjustRadius:mRadius]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Protocol
////////////////////////////////////////////////////////////////////////////////

- (id) bezierNodesWithRect:(CGRect)R
{
	CGFloat W = CGRectGetWidth(R);
	CGFloat H = CGRectGetHeight(R);
	CGFloat maxRadius = 0.5 * MIN(W, H);

	CGFloat radius = maxRadius;
	if (0.0 <= mRadius && mRadius <= 1.0)
	{ radius *= mRadius; }

	return (radius > 0.0) ?
	[self _bezierNodesWithRect:R cornerRadius:radius]:
	[self _bezierNodesWithRect:R];
}

////////////////////////////////////////////////////////////////////////////////

- (id) _bezierNodesWithRect:(CGRect)R
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

static inline CGPoint _PreparePoint(CGPoint a, CGVector b, CGFloat r)
{ return (CGPoint){ a.x+r*b.dx, a.y+r*b.dy }; }

- (id) _bezierNodesWithRect:(CGRect)R cornerRadius:(CGFloat)radius
{
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGVector D[] = {
	{ 0,+1}, { 0,-c}, { 0, 0},
	{+1, 0}, { 0, 0}, {-c, 0},
	{-1, 0}, {+c, 0}, { 0, 0},
	{ 0,+1}, { 0, 0}, { 0,-c},
	{ 0,-1}, { 0,+c}, { 0, 0},
	{-1, 0}, { 0, 0}, {+c, 0},
	{+1, 0}, {-c, 0}, { 0, 0},
	{ 0,-1}, { 0, 0}, { 0,+c}};

	static const CGVector cornerPoints[] =
	{{-1,-1},{+1,-1},{+1,+1},{-1,+1}};

	CGFloat mx = 0.5 * R.size.width;
	CGFloat my = 0.5 * R.size.height;
	CGPoint M = { R.origin.x + mx, R.origin.y + my };

	NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:8];

	for (int i=0; i!=4; i++)
	{
		CGPoint P = (CGPoint){
		M.x + mx * cornerPoints[i].dx,
		M.y + my * cornerPoints[i].dy };

		CGPoint A, B, C;
		A = _PreparePoint(P, D[6*i+0], radius);
		B = _PreparePoint(A, D[6*i+1], radius);
		C = _PreparePoint(A, D[6*i+2], radius);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

		A = _PreparePoint(P, D[6*i+3], radius);
		B = _PreparePoint(A, D[6*i+4], radius);
		C = _PreparePoint(A, D[6*i+5], radius);

		[nodes addObject:[WDBezierNode
		bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
	}

	return nodes;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
