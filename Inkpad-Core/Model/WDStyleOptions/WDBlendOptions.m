////////////////////////////////////////////////////////////////////////////////
/*
	WDBlendOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDBlendOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDBlendOptionsKey = @"WDBlendOptions";
NSString *const WDBlendModeKey = @"WDBlendMode";
NSString *const WDBlendOpacityKey = @"WDBlendOpacity";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDBlendOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize mode = mMode;
@synthesize opacity = mOpacity;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mMode = kCGBlendModeNormal;
	mOpacity = 1.0;
}

////////////////////////////////////////////////////////////////////////////////

- (void) takePropertiesFrom:(id)src
{
	[self setMode:[src mode]];
	[self setOpacity:[src opacity]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:mMode forKey:WDBlendModeKey];
	[coder encodeDouble:mOpacity forKey:WDBlendOpacityKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDBlendModeKey])
	{ mMode = [coder decodeIntegerForKey:WDBlendModeKey]; }

	if ([coder containsValueForKey:WDBlendOpacityKey])
	{ mOpacity = [coder decodeFloatForKey:WDBlendOpacityKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)srcR
{ return srcR; }

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	CGContextSetBlendMode(context, [self mode]);
	CGContextSetAlpha(context, [self opacity]);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



