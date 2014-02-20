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
@synthesize colorWell = colorWell_;

////////////////////////////////////////////////////////////////////////////////


- (void) setColor:(WDColor *)color
{ [self setColor:color notify:NO]; }

- (void) setUIColor:(UIColor *)color
{ [self setColor:[WDColor colorWithUIColor:color] notify:NO]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color notify:(BOOL)notify
{
	// Update sliders
	[component0Slider_ setColor:color];
	[component1Slider_ setColor:color];
	[component2Slider_ setColor:color];
	[alphaSlider_ setColor:color];

	// Update colorwell
	[[self colorWell] setPainter:color];

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
		component0Slider_.mode = WDColorSliderModeRed;
		component1Slider_.mode = WDColorSliderModeGreen;
		component2Slider_.mode = WDColorSliderModeBlue;
		
		component0Name_.text = @"R";
		component1Name_.text = @"G";
		component2Name_.text = @"B";

		[colorSpaceButton_ setTitle:@"RGB" forState:UIControlStateNormal];
	}
	else
	{
		component0Slider_.mode = WDColorSliderModeHue;
		component1Slider_.mode = WDColorSliderModeSaturation;
		component2Slider_.mode = WDColorSliderModeBrightness;
		
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
	if (colorSpace_ == WDColorSpaceRGB) {
		[self setColorSpace:WDColorSpaceHSB];
	} else {
		[self setColorSpace:WDColorSpaceRGB];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = nil;
	self.view.opaque = NO;
	
	[self setColorSpace:(WDColorSpace)
	[[NSUserDefaults standardUserDefaults] integerForKey:WDColorSpaceDefault]];
	alphaSlider_.mode = WDColorSliderModeAlpha;
	
	// set up connections
	UIControlEvents dragEvents =
//	UIControlEventTouchDown |
	UIControlEventTouchDragInside |
	UIControlEventTouchDragOutside;
	
	[component0Slider_ addTarget:self action:@selector(adjustColor:) forControlEvents:dragEvents];
	[component1Slider_ addTarget:self action:@selector(adjustColor:) forControlEvents:dragEvents];
	[component2Slider_ addTarget:self action:@selector(adjustColor:) forControlEvents:dragEvents];
	[alphaSlider_ addTarget:self action:@selector(adjustColor:) forControlEvents:dragEvents];
	
	UIControlEvents touchEndEvents =
	UIControlEventTouchUpInside |
	UIControlEventTouchUpOutside;
	
	[component0Slider_ addTarget:self action:@selector(adjustColorFinal:) forControlEvents:touchEndEvents];
	[component1Slider_ addTarget:self action:@selector(adjustColorFinal:) forControlEvents:touchEndEvents];
	[component2Slider_ addTarget:self action:@selector(adjustColorFinal:) forControlEvents:touchEndEvents];
	[alphaSlider_ addTarget:self action:@selector(adjustColorFinal:) forControlEvents:touchEndEvents];
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) color
{ return [WDColor colorWithUIColor:[self UIColor]]; }

- (UIColor *) UIColor
{
	CGFloat cmp[4] = {
		[component0Slider_ floatValue],
		[component1Slider_ floatValue],
		[component2Slider_ floatValue],
		[alphaSlider_ floatValue] };

	return (colorSpace_ == WDColorSpaceHSB) ?
	[UIColor colorWithHSBA:cmp]:
	[UIColor colorWithRGBA:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColor:(id)sender
{
	// Allow interface update
	[self setColor:[self color]];

	[[UIApplication sharedApplication]
	sendAction:action_ to:target_ from:self forEvent:nil];
	mTracking = YES;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColorFinal:(id)sender
{
	[self adjustColor:sender];
	mTracking = NO;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
