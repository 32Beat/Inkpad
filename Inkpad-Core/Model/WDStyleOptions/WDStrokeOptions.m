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

- (void) prepareCGContext:(CGContextRef)context
{
	CGContextSetStrokeColorWithColor(context, [self color].CGColor);
	CGContextSetLineWidth(context, [self lineWidth]);
	CGContextSetLineCap(context, [self lineCap]);
	CGContextSetLineJoin(context, [self lineJoin]);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



