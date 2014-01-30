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

+ (id) shapeWithBounds:(CGRect)bounds radius:(CGFloat)radius
{ return [[self alloc] initWithBounds:bounds radius:radius]; }

- (id) initWithBounds:(CGRect)bounds radius:(CGFloat)radius
{
	self = [super initWithBounds:bounds];
	if (self != nil)
	{
		mType = WDShapeTypeRectangle;
		mRadius = radius;
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
	[self resetPath];
}

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Protocol
////////////////////////////////////////////////////////////////////////////////

- (void) prepareNodes
{
	if (mRadius <= 0.0)
		[self prepareRect:mBounds];
	else
		[self prepareRect:mBounds cornerRadius:mRadius];
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareRect:(CGRect)R
{
	CGPoint P = R.origin;
	[[self nodes] addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:P]];
	P.x += R.size.width;
	[[self nodes] addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:P]];
	P.y += R.size.height;
	[[self nodes] addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:P]];
	P.x -= R.size.width;
	[[self nodes] addObject:
	[WDBezierNode bezierNodeWithAnchorPoint:P]];
}

////////////////////////////////////////////////////////////////////////////////

static inline CGPoint _PreparePoint(CGPoint a, CGVector b, CGFloat r)
{ return (CGPoint){ a.x+r*b.dx, a.y+r*b.dy }; }

- (void) prepareRect:(CGRect)R cornerRadius:(CGFloat)radius
{
	CGFloat W = CGRectGetWidth(R);
	CGFloat H = CGRectGetHeight(R);
	CGFloat maxRadius = 0.5 * MIN(W, H);

	if (radius > maxRadius)
	{ radius = maxRadius; }

	if (radius <= 0.0)
	{ [self prepareRect:R]; }
	else
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
		{{0,0},{1,0},{1,1},{0,1}};

		for (int i=0; i!=4; i++)
		{
			CGPoint P = (CGPoint){
			R.origin.x + W * cornerPoints[i].dx,
			R.origin.y + H * cornerPoints[i].dy };

			CGPoint A, B, C;
			A = _PreparePoint(P, D[6*i+0], radius);
			B = _PreparePoint(A, D[6*i+1], radius);
			C = _PreparePoint(A, D[6*i+2], radius);

			[[self nodes] addObject:[WDBezierNode
			bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

			A = _PreparePoint(P, D[6*i+3], radius);
			B = _PreparePoint(A, D[6*i+4], radius);
			C = _PreparePoint(A, D[6*i+5], radius);

			[[self nodes] addObject:[WDBezierNode
			bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
