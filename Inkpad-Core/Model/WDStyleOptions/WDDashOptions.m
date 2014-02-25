////////////////////////////////////////////////////////////////////////////////
/*
	WDDashOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDDashOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDDashOptionsKey = @"WDDashOptions";
NSString *const WDDashActiveKey = @"WDDashActive";
NSString *const WDDashPhaseKey = @"WDDashPhase";
NSString *const WDDashPatternKey = @"WDDashPattern";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDDashOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize active = mActive;
@synthesize phase = mPhase;
@synthesize pattern = mPattern;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mActive = YES;
	mPhase = 0.0;
	mPattern = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDDashOptions *)src
{
	self->mActive = src->mActive;
	self->mPhase = src->mPhase;
	self->mPattern = src->mPattern;
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeBool:mActive forKey:WDDashActiveKey];
	[coder encodeFloat:mPhase forKey:WDDashPhaseKey];
	[coder encodeObject:mPattern forKey:WDDashPatternKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDDashActiveKey])
	{ mActive = [coder decodeBoolForKey:WDDashActiveKey]; }

	if ([coder containsValueForKey:WDDashPhaseKey])
	{ mPhase = [coder decodeFloatForKey:WDDashPhaseKey]; }

	if ([coder containsValueForKey:WDDashPatternKey])
	{ mPattern = [coder decodeObjectForKey:WDDashPatternKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) active
{ return mActive; }

- (BOOL) visible
{
	if (mActive)
	{
		for (id value in mPattern)
		{ if ([value floatValue] != 0.0) return YES; }
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (id) patternWithScale:(float)scale
{
	if (mPattern.count)
	{
		NSMutableArray *scaledPattern =
		[NSMutableArray arrayWithCapacity:mPattern.count];

		for (id value in mPattern)
		{ [scaledPattern addObject:@(scale * [value floatValue])]; }

		return scaledPattern;
	}

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (id) optionsWithScale:(float)scale
{
	WDDashOptions *options = [[self class] new];
	options->mActive = self->mActive;
	options->mPhase *= scale;
	options->mPattern = [self patternWithScale:scale];
	return options;
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) dash0
{ return mPattern.count > 0 ? [mPattern[0] floatValue] : 0.0; }

- (CGFloat) gap0
{ return mPattern.count > 1 ? [mPattern[1] floatValue] : 0.0; }

- (CGFloat) dash1
{ return mPattern.count > 2 ? [mPattern[2] floatValue] : 0.0; }

- (CGFloat) gap1
{ return mPattern.count > 3 ? [mPattern[3] floatValue] : 0.0; }

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	if ([self visible])
	{
		CGFloat pattern[mPattern.count];
		for (int i=0; i!=mPattern.count; i++)
		{ pattern[i] = [mPattern[i] floatValue]; }

		CGContextSetLineDash(context, mPhase, pattern, mPattern.count);
	}
	else
		CGContextSetLineDash(context, 0.0, nil, 0);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



