//
//  WDColorController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDColorController.h"
#import "WDColorSlider.h"
#import "WDColorWell.h"
#import "WDColor.h"

NSString *WDColorSpaceDefault = @"WDColorSpaceDefault";

@implementation WDColorController

@synthesize tracking = mTracking;
@synthesize target = target_;
@synthesize action = action_;

////////////////////////////////////////////////////////////////////////////////

- (void) setGradientStopMode:(BOOL)state
{ mColorWell.gradientStopMode = state; }

- (void) setShadowMode:(BOOL)state
{ mColorWell.shadowMode = state; }

- (void) setStrokeMode:(BOOL)state
{ mColorWell.strokeMode = state; }

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{ [self setColor:color notify:NO]; }

- (void) setUIColor:(UIColor *)color
{ [self setColor:[WDColor colorWithUIColor:color] notify:NO]; }

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.opaque = NO;
	self.view.backgroundColor = nil;

	[self setColorSpace:(WDColorSpace)
		[[NSUserDefaults standardUserDefaults]
			integerForKey:WDColorSpaceDefault]];

	mSlider3.mode = WDColorSliderModeAlpha;

	// set up connections
	[self setSliderAction:@selector(adjustColor:)
		forControlEvents:
		//	UIControlEventTouchDown |
			UIControlEventTouchDragInside |
			UIControlEventTouchDragOutside];

	[self setSliderAction:@selector(adjustColorFinal:)
		forControlEvents:
			UIControlEventTouchUpInside |
			UIControlEventTouchUpOutside];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSliderAction:(SEL)action forControlEvents:(UIControlEvents)eventMask
{
	[mSlider0 addTarget:self action:action forControlEvents:eventMask];
	[mSlider1 addTarget:self action:action forControlEvents:eventMask];
	[mSlider2 addTarget:self action:action forControlEvents:eventMask];
	[mSlider3 addTarget:self action:action forControlEvents:eventMask];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color notify:(BOOL)notify
{
	mColor = color;
	
	// Update sliders
	[mSlider0 setColor:color];
	[mSlider1 setColor:color];
	[mSlider2 setColor:color];
	[mSlider3 setColor:color];

	// Update colorwell
	[mColorWell setPainter:color];

	// Update value labels
	if (colorSpace_ == WDColorSpaceHSB) {
		component0Value_.text =
		[NSString stringWithFormat:@"%d°", (int) round(color.hue * 360)];
		component1Value_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.saturation * 100)];
		component2Value_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.brightness * 100)];
		alphaValue_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.alpha * 100)];
	}
	else
	{
		component0Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.red * 255)];
		component1Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.green * 255)];
		component2Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.blue * 255)];
		alphaValue_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.alpha * 100)];
	}
	
	// Never notify, we are only responsible for direct messaging between
	// colorcontrols and represented object
/*
	if (notify) {
		[[UIApplication sharedApplication] sendAction:action_ to:target_ from:self forEvent:nil];
	}
*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColorSpace:(WDColorSpace)space
{
	colorSpace_ = space;
	
	if (space == WDColorSpaceRGB)
	{
		mSlider0.mode = WDColorSliderModeRed;
		mSlider1.mode = WDColorSliderModeGreen;
		mSlider2.mode = WDColorSliderModeBlue;
		
		component0Name_.text = @"R";
		component1Name_.text = @"G";
		component2Name_.text = @"B";

		[colorSpaceButton_ setTitle:@"RGB" forState:UIControlStateNormal];
	}
	else
	{
		mSlider0.mode = WDColorSliderModeHue;
		mSlider1.mode = WDColorSliderModeSaturation;
		mSlider2.mode = WDColorSliderModeBrightness;
		
		component0Name_.text = @"H";
		component1Name_.text = @"S";
		component2Name_.text = @"B";

		[colorSpaceButton_ setTitle:@"HSB" forState:UIControlStateNormal];
	}
	
	[self setColor:[self color]];
	
	[[NSUserDefaults standardUserDefaults]
	setInteger:colorSpace_ forKey:WDColorSpaceDefault];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) takeColorSpaceFrom:(id)sender
{
	[self setColorSpace:
	colorSpace_ == WDColorSpaceHSB ?
	WDColorSpaceRGB : WDColorSpaceHSB];
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) color
{ return mColor ? mColor : (mColor = [self colorFromGUI]); }

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) colorFromGUI
{
	CGFloat cmp[4] = {
		[mSlider0 floatValue],
		[mSlider1 floatValue],
		[mSlider2 floatValue],
		[mSlider3 floatValue] };

	return
	colorSpace_ == WDColorSpaceHSB ?
	[WDColor colorWithHSBA:cmp]:
	[WDColor colorWithRGBA:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (UIColor *) UIColor
{ return [[self color] UIColor]; }

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColor:(id)sender
{
	// Allow interface update
	[self setColor:(sender != mSlider3) ? [self colorFromGUI]:
	[[self color] colorWithAlphaComponent:[sender floatValue]]];

/*
	if ([sender isContinuous])
	{
		[[UIApplication sharedApplication]
		sendAction:action_ to:target_ from:self forEvent:nil];
	}
*/
	mTracking = YES;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColorFinal:(id)sender
{
	//
	[self adjustColor:sender];
	mTracking = NO;

	//if (![sender isContinuous])
	{
		[[UIApplication sharedApplication]
		sendAction:action_ to:target_ from:self forEvent:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
