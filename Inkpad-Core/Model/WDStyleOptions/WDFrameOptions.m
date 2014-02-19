////////////////////////////////////////////////////////////////////////////////
/*
	WDFrameOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDFrameOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDFrameOptionsKey = @"WDFrameOptions";
NSString *const WDFrameSizeKey = @"WDFrameSize";
NSString *const WDFramePositionKey = @"WDFramePosition";
NSString *const WDFrameRotationKey = @"WDFrameRotation";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDFrameOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize size = mSize;
@synthesize position = mPosition;
@synthesize rotation = mRotation;

////////////////////////////////////////////////////////////////////////////////

+ (id) frameOptionsWithSize:(CGSize)size
				position:(CGPoint)position
				rotation:(CGFloat)rotation
{
	return [[self alloc]
	initWithSize:size
	position:position
	rotation:rotation];
}

////////////////////////////////////////////////////////////////////////////////
// Designated initializer

- (id) initWithSize:(CGSize)size
				position:(CGPoint)position
				rotation:(CGFloat)rotation
{
	self = [super init];
	if (self != nil)
	{
		mSize = size;
		mPosition = position;
		mRotation = rotation;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (id) frameOptionsWithFrame:(CGRect)frame
{ return [[self alloc] initWithFrame:frame]; }

////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame
{
	return [self initWithSize:frame.size
	position:WDCenterOfRect(frame) rotation:0.0];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{ [self decodeWithCoder:coder]; }
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone]
	initWithSize:[self size]
	position:[self position]
	rotation:[self rotation]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeCGSize:mSize forKey:WDFrameSizeKey];
	[coder encodeCGPoint:mPosition forKey:WDFramePositionKey];
	[coder encodeDouble:mRotation forKey:WDFrameRotationKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDFrameSizeKey])
	{ mSize = [coder decodeCGSizeForKey:WDFrameSizeKey]; }

	if ([coder containsValueForKey:WDFramePositionKey])
	{ mPosition = [coder decodeCGPointForKey:WDFramePositionKey]; }

	if ([coder containsValueForKey:WDFrameRotationKey])
	{ mRotation = [coder decodeFloatForKey:WDFrameRotationKey]; }
}

////////////////////////////////////////////////////////////////////////////////

//- (void) setTransform:(CGAffineTransform)T
//{ [self setTransform:T sourceRect:[self sourceRect]]; }

- (void) setTransform:(CGAffineTransform)T sourceRect:(CGRect)sourceRect
{
	WDQuad F = WDQuadWithRect(sourceRect, T);
	CGPoint C = WDQuadGetCenter(F);

	[self setSize:(CGSize){
		0.5*(WDDistance(F.P[0], F.P[1])+WDDistance(F.P[2], F.P[3])),
		0.5*(WDDistance(F.P[0], F.P[3])+WDDistance(F.P[1], F.P[2]))}];
	[self setPosition:C];

	CGPoint P = WDAddPoints(F.P[1], F.P[2]);
	P = WDSubtractPoints(P, C);
	P = WDSubtractPoints(P, C);
	[self setRotation:WDDegreesFromRadians(atan2(P.y, P.x))];
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) transform
{
	CGPoint P = [self position];
	CGFloat r = [self rotation];

	CGAffineTransform T =
	{ 1.0, 0.0, 0.0, 1.0, P.x, P.y};

	if (r != 0.0)
	{
		CGFloat angle = r * M_PI / 180.0;
		T.a = cos(angle);
		T.b = sin(angle);
		T.c = -T.b;
		T.d = +T.a;
	}

	return T;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)srcR
{ return srcR; }

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	CGContextConcatCTM(context, [self transform]);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



