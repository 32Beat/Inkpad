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
NSString *const WDStrokeColorKey = @"WDStrokeColor";
NSString *const WDStrokeLineWidthKey = @"WDStrokeLineWidth";
NSString *const WDStrokeLineCapKey = @"WDStrokeLineCap";
NSString *const WDStrokeLineJoinKey = @"WDStrokeLineJoin";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStrokeOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize color = mColor;
@synthesize lineWidth = mLineWidth;
@synthesize lineCap = mLineCap;
@synthesize lineJoin = mLineJoin;
//@synthesize miterLimit = mMiterLimit;
@synthesize dashOptions = mDashOptions;

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties
{
	mLineWidth = 1.0;
	mLineCap = kCGLineCapButt;
	mLineJoin = kCGLineJoinMiter;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDStrokeOptions *)src
{
	self->mColor = src->mColor;
	self->mLineWidth = src->mLineWidth;
	self->mLineCap = src->mLineCap;
	self->mLineJoin = src->mLineJoin;
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:mColor forKey:WDStrokeColorKey];
	[coder encodeDouble:mLineWidth forKey:WDStrokeLineWidthKey];
	[coder encodeInt:mLineCap forKey:WDStrokeLineCapKey];
	[coder encodeInt:mLineJoin forKey:WDStrokeLineJoinKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDStrokeColorKey])
	{ mColor = [coder decodeObjectForKey:WDStrokeColorKey]; }

	if ([coder containsValueForKey:WDStrokeLineWidthKey])
	{ mLineWidth = [coder decodeFloatForKey:WDStrokeLineWidthKey]; }

	if ([coder containsValueForKey:WDStrokeLineCapKey])
	{ mLineCap = [coder decodeFloatForKey:WDStrokeLineCapKey]; }

	if ([coder containsValueForKey:WDStrokeLineJoinKey])
	{ mLineJoin = [coder decodeFloatForKey:WDStrokeLineJoinKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	CGContextSetStrokeColorWithColor(context, [self color].CGColor);
	CGContextSetLineWidth(context, [self lineWidth]);
	CGContextSetLineCap(context, [self lineCap]);
	CGContextSetLineJoin(context, [self lineJoin]);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



