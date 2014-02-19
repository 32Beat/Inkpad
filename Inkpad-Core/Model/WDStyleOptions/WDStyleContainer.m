////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleContainer.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStyleContainer.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStyleContainer
////////////////////////////////////////////////////////////////////////////////

- (id) initWithDelegate:(id<WDStyleContainerDelegate>)delegate
{
	self = [super init];
	if (self != nil)
	{
		mDelegate = delegate;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDStyleContainer *)srcOptions
{
	self->mBlendOptions = [srcOptions->mBlendOptions copy];
	self->mShadowOptions = [srcOptions->mShadowOptions copy];
	self->mStrokeOptions = [srcOptions->mStrokeOptions copy];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
/*
	if ([coder containsValueForKey:NSStringFromClass([self class])])
	{
		mContainer = [coder valueForKey:NSStringFromClass([self class])];
		if (mContainer != nil) mContainer = [mContainer mutableCopy];
	}
*/
//*
	if ([coder containsValueForKey:WDBlendOptionsKey])
	{ [self setBlendOptions:[coder decodeObjectForKey:WDBlendOptionsKey]]; }
	if ([coder containsValueForKey:WDShadowOptionsKey])
	{ [self setShadowOptions:[coder decodeObjectForKey:WDShadowOptionsKey]]; }
//*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
//	if (mContainer != nil) \
	[coder encodeObject:mContainer forKey:NSStringFromClass([self class])];
//*
	if (mBlendOptions != nil)
	[coder encodeObject:mBlendOptions forKey:WDBlendOptionsKey];
	if (mShadowOptions != nil)
	[coder encodeObject:mShadowOptions forKey:WDShadowOptionsKey];
//*/
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
	[mDelegate styleContainer:self willSetOptionsForKey:key];
	[self setValue:options forKey:key];
	[mDelegate styleContainer:self didSetOptionsForKey:key];
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
{ [mDelegate styleContainer:self willSetOptionsForKey:key]; }

- (void) didSetOptionsForKey:(id)key
{ [mDelegate styleContainer:self didSetOptionsForKey:key]; }

////////////////////////////////////////////////////////////////////////////////

- (id) frameOptions
{ return mFrameOptions; }

- (void) setFrameOptions:(id)options
{
	[self willSetOptionsForKey:WDFrameOptionsKey];
	mFrameOptions = [options copy];
	[self didSetOptionsForKey:WDFrameOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////
/*
	We always need blendOptions where opacity = 1.0
*/
- (id) blendOptions
{ return mBlendOptions ? mBlendOptions : (mBlendOptions = [WDBlendOptions new]); }

- (void) setBlendOptions:(id)options
{
	[self willSetOptionsForKey:WDBlendOptionsKey];
	mBlendOptions = [options copy];
	[self didSetOptionsForKey:WDBlendOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) shadowOptions
{ return mShadowOptions; }

- (void) setShadowOptions:(id)options
{
	[self willSetOptionsForKey:WDShadowOptionsKey];
	mShadowOptions = [options copy];
	[self didSetOptionsForKey:WDShadowOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) strokeOptions
{ return mStrokeOptions; }

- (void) setStrokeOptions:(id)options
{
	[self willSetOptionsForKey:WDStrokeOptionsKey];
	mStrokeOptions = [options copy];
	[self didSetOptionsForKey:WDStrokeOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)R
{
	if (mStrokeOptions != nil)
	{ R = [mStrokeOptions resultAreaForRect:R]; }
	if (mShadowOptions != nil)
	{ R = [mShadowOptions resultAreaForRect:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	[mStrokeOptions prepareCGContext:context];
	[mShadowOptions prepareCGContext:context];
	[mBlendOptions prepareCGContext:context];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////





