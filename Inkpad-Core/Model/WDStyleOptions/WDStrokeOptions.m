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
NSString *const WDStrokeLineJoinKey = @"WDStrokeLineJoin";
NSString *const WDStrokeLineCapKey = @"WDStrokeLineCap";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStrokeOptions
////////////////////////////////////////////////////////////////////////////////

@synthesize color = mColor;
@synthesize lineWidth = mLineWidth;
@synthesize lineJoin = mLineJoin;
@synthesize lineCap = mLineCap;
@synthesize dashOptions = mDashOptions;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



