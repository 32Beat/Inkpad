////////////////////////////////////////////////////////////////////////////////
/*
	WDStrokeOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShadowOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDShadowOptionsKey = @"WDShadowOptions";
NSString *const WDShadowOffsetKey = @"WDShadowOffset";
NSString *const WDShadowBlurKey = @"WDShadowBlur";
NSString *const WDShadowColorKey = @"WDShadowColor";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDShadowOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize offset = mOffset;
@synthesize blur = mBlur;
@synthesize color = mColor;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mOffset = CGSizeZero;
	mBlur = 0.0;
	mColor = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) takePropertiesFrom:(id)src
{
	[self setOffset:[src offset]];
	[self setBlur:[src blur]];
	[self setColor:[src color]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeCGSize:mOffset forKey:WDShadowOffsetKey];
	[coder encodeDouble:mBlur forKey:WDShadowBlurKey];
	[coder encodeObject:mColor forKey:WDShadowColorKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDShadowOffsetKey])
	{ mOffset = [coder decodeCGSizeForKey:WDShadowOffsetKey]; }

	if ([coder containsValueForKey:WDShadowBlurKey])
	{ mBlur = [coder decodeFloatForKey:WDShadowBlurKey]; }

	if ([coder containsValueForKey:WDShadowColorKey])
	{ mColor = [coder decodeObjectForKey:WDShadowColorKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) offsetRadius
{ return sqrt(mOffset.width*mOffset.width + mOffset.height*mOffset.height); }

- (void) setOffsetRadius:(CGFloat)r
{
	CGFloat angle = [self offsetAngle];
	[self setOffset:(CGSize){ r * cos(angle), r * sin(angle) }];
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) offsetAngle
{ return atan2(mOffset.height, mOffset.width); }

- (void) setOffsetAngle:(CGFloat)angle
{
	CGFloat r = [self offsetRadius];
	[self setOffset:(CGSize){ r * cos(angle), r * sin(angle) }];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)srcR
{
	CGRect dstR = srcR;
	dstR.origin.x += mOffset.width;
	dstR.origin.y += mOffset.height;
	dstR = CGRectInset(dstR, -mBlur, -mBlur);

	return CGRectUnion(srcR, dstR);
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	CGContextSetShadowWithColor(context,
		[self offset],
		[self blur],
		[self color].CGColor);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



