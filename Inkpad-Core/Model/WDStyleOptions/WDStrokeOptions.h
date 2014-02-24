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
#import "WDColor.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDStrokeOptions
	---------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDStrokeOptionsKey;
extern NSString *const WDStrokeActiveKey;
extern NSString *const WDStrokeColorKey;
extern NSString *const WDStrokeLineWidthKey;
extern NSString *const WDStrokeLineCapKey;
extern NSString *const WDStrokeLineJoinKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDStrokeOptions : WDStyleOptions
{
	BOOL 		mActive;
	WDColor 	*mColor;
	CGFloat 	mLineWidth;
	CGLineCap 	mLineCap;
	CGLineJoin 	mLineJoin;
	id 			mDashOptions;
}

@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGLineCap lineCap;
@property (nonatomic, assign) CGLineJoin lineJoin;
@property (nonatomic, strong) id dashOptions;

- (id) optionsWithScale:(float)scale;

- (BOOL) visible;
- (CGRect) resultAreaForRect:(CGRect)R  scale:(CGFloat)scale;
- (CGRect) resultAreaForPath:(CGPathRef)path scale:(CGFloat)scale;

@end
////////////////////////////////////////////////////////////////////////////////





