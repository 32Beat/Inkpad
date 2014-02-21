////////////////////////////////////////////////////////////////////////////////
/*
	WDColorController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

@class WDColor;
@class WDColorWell;
@class WDColorSlider;

////////////////////////////////////////////////////////////////////////////////

typedef enum
{
	WDColorSpaceRGB,
	WDColorSpaceHSB,
}
WDColorSpace;

////////////////////////////////////////////////////////////////////////////////
@interface WDColorController : UIViewController
{
	IBOutlet WDColorWell 		*mColorWell;

	IBOutlet WDColorSlider      *mSlider0;
	IBOutlet WDColorSlider      *mSlider1;
	IBOutlet WDColorSlider      *mSlider2;
	IBOutlet WDColorSlider      *mSlider3;
	
	IBOutlet UILabel            *component0Name_;
	IBOutlet UILabel            *component1Name_;
	IBOutlet UILabel            *component2Name_;

	IBOutlet UILabel            *component0Value_;
	IBOutlet UILabel            *component1Value_;
	IBOutlet UILabel            *component2Value_;
	IBOutlet UILabel            *alphaValue_;
	
	IBOutlet UIButton           *colorSpaceButton_;
	WDColorSpace 				colorSpace_;
	
	BOOL mTracking;
	WDColor *mColor;
}

@property (nonatomic, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

- (void) setGradientStopMode:(BOOL)state;
- (void) setShadowMode:(BOOL)state;
- (void) setStrokeMode:(BOOL)state;

- (WDColor *)color;
- (void) setColor:(WDColor *)color;

- (IBAction) switchColorSpace:(id)sender;

@end

extern NSString *const WDColorSpaceDefault;



