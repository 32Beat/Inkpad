////////////////////////////////////////////////////////////////////////////////
/*
	WDShadowOptions.m
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
NSString *const WDShadowColorKey = @"WDShadowColor";
NSString *const WDShadowAngleKey = @"WDShadowAngle";
NSString *const WDShadowOffsetKey = @"WDShadowOffset";
NSString *const WDShadowBlurKey = @"WDShadowBlur";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDShadowOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize color = mColor;
@synthesize angle = mAngle;
@synthesize offset = mOffset;
@synthesize blur = mBlur;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mColor = nil;
	mAngle = 0.0;
	mOffset = 0.0;
	mBlur = 0.0;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(id)src
{
	[self setColor:[src color]];
	[self setAngle:[src angle]];
	[self setOffset:[src offset]];
	[self setBlur:[src blur]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:mColor forKey:WDShadowColorKey];
	[coder encodeFloat:mAngle forKey:WDShadowAngleKey];
	[coder encodeFloat:mOffset forKey:WDShadowOffsetKey];
	[coder encodeFloat:mBlur forKey:WDShadowBlurKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDShadowColorKey])
	{ mColor = [coder decodeObjectForKey:WDShadowColorKey]; }

	if ([coder containsValueForKey:WDShadowAngleKey])
	{ mAngle = [coder decodeFloatForKey:WDShadowAngleKey]; }

	if ([coder containsValueForKey:WDShadowOffsetKey])
	{ mOffset = [coder decodeFloatForKey:WDShadowOffsetKey]; }

	if ([coder containsValueForKey:WDShadowBlurKey])
	{ mBlur = [coder decodeFloatForKey:WDShadowBlurKey]; }

}

////////////////////////////////////////////////////////////////////////////////

- (CGSize) offsetVector
{
	CGFloat r = [self offset];
	CGFloat a = [self angle];
	return (CGSize){ r*cos(a), r*sin(a) };
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)srcR
{
	CGRect dstR = srcR;
	CGSize offset = [self offsetVector];
	dstR.origin.x += offset.width;
	dstR.origin.y += offset.height;
	dstR = CGRectInset(dstR, -mBlur, -mBlur);

	return CGRectUnion(srcR, dstR);
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	CGSize offset = CGSizeZero;
	CGFloat blurRadius = 0.0;
	CGColorRef color = [self color].CGColor;

	if (color != nil)
	{
		offset = [self offsetVector];
		blurRadius = [self blur];

		offset.width *= scale;
		offset.height *= scale;
		blurRadius *= scale;
	}

	CGContextSetShadowWithColor(context, offset, blurRadius, color);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



