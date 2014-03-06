////////////////////////////////////////////////////////////////////////////////
/*
	WDColorSlider.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

@class WDColorIndicator;
//@class WDColor;
#import "WDColor.h"

typedef enum {
	WDColorSliderModeHue,
	WDColorSliderModeSaturation,
	WDColorSliderModeBrightness,
	WDColorSliderModeRed,
	WDColorSliderModeGreen,
	WDColorSliderModeBlue,
	WDColorSliderModeAlpha,
	WDColorSliderModeRedBalance,
	WDColorSliderModeGreenBalance,
	WDColorSliderModeBlueBalance
} WDColorSliderMode;

@interface WDColorSlider : UIControl
{
	WDColor             *color_;
	float               value_;

	WDColorIndicator    *indicator_;
	BOOL                reversed_;
}

@property (nonatomic, assign) int componentIndex;

@property (nonatomic, readonly) float floatValue;
@property (nonatomic, strong) id color;
@property (nonatomic, assign) BOOL reversed;
@property (nonatomic, strong, readonly) WDColorIndicator *indicator;

@end
