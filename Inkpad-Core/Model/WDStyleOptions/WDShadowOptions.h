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
#import "WDColor.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDShadowOptions
	---------------
	Parameters for shadow generation:
	
		angle = angle of shadowoffset
		offset = radius of shadowoffset
		blur = blur radius
	
	Note: uses CGContextShadowWithColor to apply shadow. 
	CGContextShadowWithColor always operates independently from the CTM
	but does seem to honor contentscalefactor.
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDShadowOptionsKey;
extern NSString *const WDShadowActiveKey;
extern NSString *const WDShadowColorKey;
extern NSString *const WDShadowAngleKey;
extern NSString *const WDShadowOffsetKey;
extern NSString *const WDShadowBlurKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDShadowOptions : WDStyleOptions
{
	BOOL 		mActive;

	WDColor 	*mColor;
	CGFloat 	mAngle;
	CGFloat 	mOffset;
	CGFloat 	mBlur;
}

@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, assign) CGFloat blur;

- (BOOL) isVisible;
- (id) optionsWithScale:(float)scale;

@end
////////////////////////////////////////////////////////////////////////////////





