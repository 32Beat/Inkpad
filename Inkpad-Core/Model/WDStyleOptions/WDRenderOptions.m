////////////////////////////////////////////////////////////////////////////////
/*
	WDRenderOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDRenderOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDRenderOptions
////////////////////////////////////////////////////////////////////////////////

- (id) initWithDelegate:(id<WDRenderOptionsDelegate>)delegate
{
	self = [super init];
	if (self != nil)
	{
		mDelegate = delegate;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	mContainer = [coder valueForKey:NSStringFromClass([self class])];
	if (mContainer != nil) mContainer = [mContainer mutableCopy];
/*
	if ([coder containsValueForKey:WDBlendOptionsKey])
	{ [self setOptions:[coder decodeObjectForKey:WDBlendOptionsKey]]; }
	if ([coder containsValueForKey:WDShadowOptionsKey])
	{ [self setOptions:[coder decodeObjectForKey:WDShadowOptionsKey]]; }
*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	if (mContainer != nil)
	[coder encodeObject:mContainer forKey:NSStringFromClass([self class])];
/*
	if (mBlendOptions != nil)
	[coder encodeObject:mBlendOptions forKey:WDBlendOptionsKey];
	if (mShadowOptions != nil)
	[coder encodeObject:mShadowOptions forKey:WDShadowOptionsKey];
*/
}

////////////////////////////////////////////////////////////////////////////////

- (id) container
{ return mContainer ? mContainer : (mContainer = [NSMutableDictionary new]); }

////////////////////////////////////////////////////////////////////////////////

- (id) valueForKey:(id)key
{ return [[self container] valueForKey:key]; }

- (void) setValue:(id)value forKey:(id)key
{ [[self container] setValue:value forKey:key]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setOptions:(id)options
{ [self setOptions:options forKey:NSStringFromClass([options class])]; }

- (void) setOptions:(id)options forKey:(id)key
{
	[mDelegate renderOptions:self willSetOptionsForKey:key];
	[self setValue:options forKey:key];
	[mDelegate renderOptions:self didSetOptionsForKey:key];
}

////////////////////////////////////////////////////////////////////////////////
/*
- (void) setBlendOptions:(id)options
{ [self setOptions:options forKey:WDBlendOptionsKey]; }

- (void) setShadowOptions:(id)options
{ [self setOptions:options forKey:WDShadowOptionsKey]; }
*/
////////////////////////////////////////////////////////////////////////////////

- (void) willSetOptionsForKey:(id)key
{ [mDelegate renderOptions:self willSetOptionsForKey:key]; }

- (void) didSetOptionsForKey:(id)key
{ [mDelegate renderOptions:self didSetOptionsForKey:key]; }

////////////////////////////////////////////////////////////////////////////////

- (id) blendOptions
{ return mBlendOptions; }

- (void) setBlendOptions:(id)options
{
	[self willSetOptionsForKey:WDBlendOptionsKey];
	mBlendOptions = options;
	[self didSetOptionsForKey:WDBlendOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) shadowOptions
{ return mShadowOptions; }

- (void) setShadowOptions:(id)options
{
	[self willSetOptionsForKey:WDShadowOptionsKey];
	mShadowOptions = options;
	[self didSetOptionsForKey:WDShadowOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)R
{
	if (mShadowOptions != nil)
	{ R = [mShadowOptions resultAreaForRect:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	[mBlendOptions prepareCGContext:context];
	[mShadowOptions prepareCGContext:context];

//	for (id options in [mContainer objectEnumerator])
//	{ [options prepareCGContext:context]; }
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////





