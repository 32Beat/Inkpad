////////////////////////////////////////////////////////////////////////////////
/*
	WDColorController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColorController.h"
#import "WDColorSlider.h"
#import "WDColorWell.h"
#import "WDColor.h"

NSString *const WDColorModelDefault = @"WDColorSpaceDefault";

////////////////////////////////////////////////////////////////////////////////
@implementation WDColorController
////////////////////////////////////////////////////////////////////////////////

@synthesize tracking = mTracking;

////////////////////////////////////////////////////////////////////////////////

- (void) setGradientStopMode:(BOOL)state
{ mColorWell.gradientStopMode = state; }

- (void) setShadowMode:(BOOL)state
{ mColorWell.shadowMode = state; }

- (void) setStrokeMode:(BOOL)state
{ mColorWell.strokeMode = state; }

////////////////////////////////////////////////////////////////////////////////
/*
	Following allows mInstance = [WDColorController new];
*/

- (id) init
{ return [self initWithNibName:@"Color" bundle:nil]; }

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.opaque = NO;
	self.view.backgroundColor = nil;

	[self setColorModel:(WDColorModel)
		[[NSUserDefaults standardUserDefaults]
			integerForKey:WDColorModelDefault]];

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

	[mSlider0 setComponentIndex:0];
	[mSlider1 setComponentIndex:1];
	[mSlider2 setComponentIndex:2];
	[mSlider3 setComponentIndex:3];
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

- (void) updateViewWithColor:(WDColor *)color
{
	// Update sliders
	[mSlider0 setColor:color];
	[mSlider1 setColor:color];
	[mSlider2 setColor:color];
	[mSlider3 setColor:color];

	// Update colorwell
	[mColorWell setPainter:color];

	// Update value labels
/*	if (mColorModel == WDColorModelHSB)
	{
		component0Value_.text =
		[NSString stringWithFormat:@"%d°", (int) round(color.hue * 360)];
		component1Value_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.saturation * 100)];
		component2Value_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.brightness * 100)];
		alphaValue_.text =
		[NSString stringWithFormat:@"%d%%", (int) round(color.alpha * 100)];
	}
	else*/
	if (mColorModel == WDColorModelHSB)
	{
		component0Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.lch_L)];
		component1Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.lch_C)];
		component2Value_.text =
		[NSString stringWithFormat:@"%d", (int) round(color.lch_H)];
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
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateViewWithColorModel:(WDColorModel)model
{
/*	if (model == WDColorModelHSB)
	{
		component0Name_.text = @"H";
		component1Name_.text = @"S";
		component2Name_.text = @"B";

		[mColorModelButton setTitle:@"HSB" forState:UIControlStateNormal];
	}
	else*/
	if (model == WDColorModelHSB)
	{
		component0Name_.text = @"L";
		component1Name_.text = @"C";
		component2Name_.text = @"H";

		[mColorModelButton setTitle:@"Lab" forState:UIControlStateNormal];
	}
	else
	{
		component0Name_.text = @"R";
		component1Name_.text = @"G";
		component2Name_.text = @"B";

		[mColorModelButton setTitle:@"RGB" forState:UIControlStateNormal];
	}

	[self updateViewWithColor:
	[[self color] colorWithColorType:model]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColorModel:(WDColorModel)model
{
	if (mColorModel != model)
	{
		mColorModel = model;
		[self updateViewWithColorModel:model];

		[[NSUserDefaults standardUserDefaults]
		setInteger:mColorModel forKey:WDColorModelDefault];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) color
{ return mColor ? mColor : (mColor = [self colorFromGUI]); }

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{
	if (mColor != color)
	{
		mColor = color;
		[self updateViewWithColor:color];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) colorFromGUI
{
	CGFloat cmp[4] = {
		[mSlider0 floatValue],
		[mSlider1 floatValue],
		[mSlider2 floatValue],
		[mSlider3 floatValue] };

	return
	[WDColor colorWithType:mColorModel components:cmp];
/*
	mColorModel == WDColorModelHSB ?
	[WDColor colorWithHSBA:cmp]:
	[WDColor colorWithRGBA:cmp];
*/
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) switchColorModel:(id)sender
{
	[self setColorModel:
	mColorModel == WDColorModelHSB ?
	WDColorModelRGB : WDColorModelHSB];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColor:(id)sender
{
	// Allow interface update
	[self setColor:(sender != mSlider3) ? [self colorFromGUI]:
	[[self color] colorWithAlphaComponent:[sender floatValue]]];
	mTracking = YES;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustColorFinal:(id)sender
{
	//
	[self adjustColor:sender];
	mTracking = NO;

	[[UIApplication sharedApplication]
	sendAction:self.action to:self.target from:self forEvent:nil];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
