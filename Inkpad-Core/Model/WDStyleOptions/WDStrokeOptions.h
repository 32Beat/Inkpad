////////////////////////////////////////////////////////////////////////////////
/*
	WDStrokeOptions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStyleOptions.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDStrokeOptions
	---------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDStrokeOptionsKey;
extern NSString *const WDStrokeColorKey;
extern NSString *const WDStrokeLineWidthKey;
extern NSString *const WDStrokeLineCapKey;
extern NSString *const WDStrokeLineJoinKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDStrokeOptions : WDStyleOptions
{
	UIColor 	*mColor;
	CGFloat 	mLineWidth;
	CGLineCap 	mLineCap;
	CGLineJoin 	mLineJoin;
	id 			mDashOptions;
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGLineCap lineCap;
@property (nonatomic, assign) CGLineJoin lineJoin;
@property (nonatomic, strong) id dashOptions;

@end
////////////////////////////////////////////////////////////////////////////////





