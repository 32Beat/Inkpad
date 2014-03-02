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

#import "WDStrokeOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDStrokeOptionsKey = @"WDStrokeOptions";
NSString *const WDStrokeActiveKey = @"WDStrokeActive";
NSString *const WDStrokeColorKey = @"WDStrokeColor";
NSString *const WDStrokeLineWidthKey = @"WDStrokeLineWidth";
NSString *const WDStrokeLineCapKey = @"WDStrokeLineCap";
NSString *const WDStrokeLineJoinKey = @"WDStrokeLineJoin";
NSString *const WDStrokeMiterLimitKey = @"WDStrokeMiterLimit";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStrokeOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize active = mActive;
@synthesize color = mColor;
@synthesize lineWidth = mLineWidth;
@synthesize lineCap = mLineCap;
@synthesize lineJoin = mLineJoin;
@synthesize miterLimit = mMiterLimit;
@synthesize dashOptions = mDashOptions;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mActive = YES;
	mColor = nil;
	mLineWidth = 1.0;
	mLineCap = kCGLineCapButt;
	mLineJoin = kCGLineJoinMiter;
	mMiterLimit = 0.0;
	mDashOptions = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDStrokeOptions *)src
{
	self->mActive = src->mActive;
	self->mColor = src->mColor;
	self->mLineWidth = src->mLineWidth;
	self->mLineCap = src->mLineCap;
	self->mLineJoin = src->mLineJoin;
	self->mMiterLimit = src->mMiterLimit;
	self->mDashOptions = [src->mDashOptions copy];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeBool:mActive forKey:WDStrokeActiveKey];
	[coder encodeObject:mColor forKey:WDStrokeColorKey];
	[coder encodeFloat:mLineWidth forKey:WDStrokeLineWidthKey];
	[coder encodeInt:mLineCap forKey:WDStrokeLineCapKey];
	[coder encodeInt:mLineJoin forKey:WDStrokeLineJoinKey];
	[coder encodeFloat:mMiterLimit forKey:WDStrokeMiterLimitKey];
	[coder encodeObject:mDashOptions forKey:WDDashOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDStrokeActiveKey])
	{ mActive = [coder decodeBoolForKey:WDStrokeActiveKey]; }

	if ([coder containsValueForKey:WDStrokeColorKey])
	{ mColor = [coder decodeObjectForKey:WDStrokeColorKey]; }

	if ([coder containsValueForKey:WDStrokeLineWidthKey])
	{ mLineWidth = [coder decodeFloatForKey:WDStrokeLineWidthKey]; }

	if ([coder containsValueForKey:WDStrokeLineCapKey])
	{ mLineCap = [coder decodeIntForKey:WDStrokeLineCapKey]; }

	if ([coder containsValueForKey:WDStrokeLineJoinKey])
	{ mLineJoin = [coder decodeIntForKey:WDStrokeLineJoinKey]; }

	if ([coder containsValueForKey:WDStrokeMiterLimitKey])
	{ mMiterLimit = [coder decodeFloatForKey:WDStrokeMiterLimitKey]; }

	if ([coder containsValueForKey:WDDashOptionsKey])
	{ mDashOptions = [coder decodeObjectForKey:WDDashOptionsKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) visible
{ return mActive && mColor.visible && (mLineWidth > 0.0); }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)R
{
//	CGFloat min = MIN(R.size.width, R.size.height);
	return [self resultAreaForRect:R scale:1.0];
}

- (CGRect) resultAreaForRect:(CGRect)R  scale:(CGFloat)scale
{
	if ([self visible])
	{
		CGFloat r = 0.5 * mLineWidth * scale;
		R = CGRectInset(R, -r, -r);
	}

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (id) optionsWithScale:(float)scale
{
	WDStrokeOptions *options = [self copy];
	options->mLineWidth *= scale;
	options->mDashOptions = [self->mDashOptions optionsWithScale:scale];
	return options;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForPath:(CGPathRef)path
{ return WDStrokeOptionsStyleBoundsForPath(self, path); }

- (CGRect) resultAreaForPath:(CGPathRef)path scale:(CGFloat)scale
{ return WDStrokeOptionsStyleBoundsForPath([self optionsWithScale:scale], path); }

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	if ([self visible])
	{
		CGContextSetStrokeColorWithColor(context, mColor.CGColor);
		CGContextSetLineWidth(context, mLineWidth*scale);
		CGContextSetLineCap(context, mLineCap);
		CGContextSetLineJoin(context, mLineJoin);

		if (mMiterLimit > 0.0)
		CGContextSetMiterLimit(context, mMiterLimit);

		[mDashOptions prepareCGContext:context];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



