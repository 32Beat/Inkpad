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

NSString *const WDShadowOptionsKey;
NSString *const WDShadowColorKey;
NSString *const WDShadowOffsetKey;
NSString *const WDShadowBlurKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDShadowOptions : WDStyleOptions
{
}

- (CGSize) shadowOffset;
- (void) setShadowOffset:(CGSize)offset;

- (CGFloat) shadowBlur;
- (void) setShadowBlur:(CGFloat)blurRadius;

- (UIColor *) shadowColor;
- (void) setShadowColor:(UIColor *)color;

@end
////////////////////////////////////////////////////////////////////////////////





