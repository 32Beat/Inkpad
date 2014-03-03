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
	self->mFillOptions = [srcOptions->mFillOptions copy];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
//*
	if ([coder containsValueForKey:WDBlendOptionsKey])
	{ [self setBlendOptions:[coder decodeObjectForKey:WDBlendOptionsKey]]; }
	if ([coder containsValueForKey:WDShadowOptionsKey])
	{ [self setShadowOptions:[coder decodeObjectForKey:WDShadowOptionsKey]]; }
	if ([coder containsValueForKey:WDStrokeOptionsKey])
	{ [self setStrokeOptions:[coder decodeObjectForKey:WDStrokeOptionsKey]]; }
	if ([coder containsValueForKey:WDFillOptionsKey])
	{ [self setFillOptions:[coder decodeObjectForKey:WDFillOptionsKey]]; }
//*/
/*
	if ([coder containsValueForKey:NSStringFromClass([self class])])
	{
		mContainer = [coder valueForKey:NSStringFromClass([self class])];
		if (mContainer != nil) mContainer = [mContainer mutableCopy];
	}
*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
//*
	if (mBlendOptions != nil)
	[coder encodeObject:mBlendOptions forKey:WDBlendOptionsKey];
	if (mShadowOptions != nil)
	[coder encodeObject:mShadowOptions forKey:WDShadowOptionsKey];
	if (mStrokeOptions != nil)
	[coder encodeObject:mStrokeOptions forKey:WDStrokeOptionsKey];
	if (mFillOptions != nil)
	[coder encodeObject:mFillOptions forKey:WDFillOptionsKey];
//*/
//	if (mContainer != nil) \
	[coder encodeObject:mContainer forKey:NSStringFromClass([self class])];
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
	[self willSetOptionsForKey:key];
	[self setValue:options forKey:key];
	[self didSetOptionsForKey:key];
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
- (WDBlendOptions *) blendOptions
{ return mBlendOptions ? mBlendOptions : (mBlendOptions = [WDBlendOptions new]); }

- (void) setBlendOptions:(id)options
{
	[self willSetOptionsForKey:WDBlendOptionsKey];
	mBlendOptions = [options copy];
	[self didSetOptionsForKey:WDBlendOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (WDShadowOptions *) shadowOptions
{ return mShadowOptions; }

- (void) setShadowOptions:(id)options
{
	[self willSetOptionsForKey:WDShadowOptionsKey];
	mShadowOptions = [options copy];
	[self didSetOptionsForKey:WDShadowOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (WDStrokeOptions *) strokeOptions
{ return mStrokeOptions; }

- (void) setStrokeOptions:(id)options
{
	[self willSetOptionsForKey:WDStrokeOptionsKey];
	mStrokeOptions = [options copy];
	[self didSetOptionsForKey:WDStrokeOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (WDFillOptions *) fillOptions
{ return mFillOptions; }

- (void) setFillOptions:(id)options
{
	[self willSetOptionsForKey:WDFillOptionsKey];
	mFillOptions = [options copy];
	[self didSetOptionsForKey:WDFillOptionsKey];
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
/*
	For an object to be visible, it needs at least visible blendOptions, 
	and then at least one of fill or stroke. If an object is not visible, 
	it will still be drawn in the preview using a faint outline
*/
- (BOOL) visible
{
	return
	// At least visible blend
	self.blendOptions.visible &&
	(
		// At least one of these
		self.fillOptions.visible ||
		self.strokeOptions.visible
	);
}

////////////////////////////////////////////////////////////////////////////////
/*
	blendOptions transparent:
	context uses already existing data in context to blend
	any newly added information
	
	shadowOptions visible:
	shadow is rendered for any newly added information
	
	If an element adds multiple drawing calls, these should be
	composited prior to blending 
*/

- (BOOL) needsTransparencyLayer
{
	return
	[[self blendOptions] transparent] ||
	[[self shadowOptions] visible];
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareContext:(const WDRenderContext *)renderContext
{
	[mBlendOptions prepareCGContext:renderContext->contextRef];
	[mShadowOptions prepareCGContext:renderContext->contextRef
		scale:renderContext->renderScale
		flipped:WDRenderUpsideDown(renderContext)];
}

////////////////////////////////////////////////////////////////////////////////
/*
	prepareCGContext
	----------------
	Prepare global options for context
	
	Other options are applied on requirement basis
*/
- (void) prepareCGContext:(CGContextRef)context
			scale:(CGFloat)scale
			flipped:(BOOL)flipped
{
	[mBlendOptions prepareCGContext:context];
	[mShadowOptions prepareCGContext:context scale:scale flipped:flipped];
}

////////////////////////////////////////////////////////////////////////////////

- (void) applyScale:(CGFloat)scale
{
	self->mStrokeOptions = [[self strokeOptions] optionsWithScale:scale];
	self->mShadowOptions = [[self shadowOptions] optionsWithScale:scale];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////





