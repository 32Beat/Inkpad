////////////////////////////////////////////////////////////////////////////////
/*
	WDShadowOptions.h
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
	WDShadowOptions
	---------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDShadowOptionsKey;
extern NSString *const WDShadowColorKey;
extern NSString *const WDShadowAngleKey;
extern NSString *const WDShadowOffsetKey;
extern NSString *const WDShadowBlurKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDShadowOptions : WDStyleOptions
{
	UIColor *mColor;
	float 	mAngle;
	float 	mOffset;
	float 	mBlur;
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) float angle;
@property (nonatomic, assign) float offset;
@property (nonatomic, assign) float blur;

- (CGSize) offsetVector;

@end
////////////////////////////////////////////////////////////////////////////////





