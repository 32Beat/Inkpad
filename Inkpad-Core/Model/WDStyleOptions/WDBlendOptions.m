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

- (void) copyPropertiesFrom:(WDBlendOptions *)src
{
	self->mMode = src->mMode;
	self->mOpacity = src->mOpacity;
}

////////////////////////////////////////////////////////////////////////////////

+ (id) blendOptionsWithMode:(CGBlendMode)mode opacity:(CGFloat)opacity
{ return [[self alloc] initWithMode:mode opacity:opacity]; }

////////////////////////////////////////////////////////////////////////////////

- (id) initWithMode:(CGBlendMode)mode opacity:(CGFloat)opacity
{
	self = [super init];
	if (self != nil)
	{
		mMode = mode;
		mOpacity = opacity;
	}

	return self;
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

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	CGContextSetBlendMode(context, mMode);
	CGContextSetAlpha(context, mOpacity);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) transparent
{ return mMode != kCGBlendModeNormal || mOpacity != 1.0; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



