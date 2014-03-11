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
			UIControlEventTouchDown |
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
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) updateViewWithColor:(WDColor *)color
{
	color = [color colorWithColorType:mColorModel];

	// Update value labels
	if (color.type == WDColorModelLCH)
	{
		[mSlider0 setColor:color];
		[mSlider1 setColor:color];
		[mSlider2 setColor:color];
		[self updateValuesWithLCH:color];
	}
	else
	if (color.type == WDColorModelLab)
	{
		[mSlider0 setColor:color];
		[mSlider1 setColor:color];
		[mSlider2 setColor:color];
		[self updateValuesWithLab:color];
	}
	else
	if (color.type == WDColorModelHSB)
	{
		[mSlider0 setColor:[WDColor colorWithH:color.hsb_H S:100.0 B:100.0]];
		[mSlider1 setColor:color];
		[mSlider2 setColor:color];
		[self updateValuesWithHSB:color];
	}
	else
	{
		[mSlider0 setColor:color];
		[mSlider1 setColor:color];
		[mSlider2 setColor:color];
		[self updateValuesWithRGB:color];
	}

	[mSlider3 setColor:color];
	alphaValue_.text =
	[NSString stringWithFormat:@"%d%%", (int)round(color.alpha * 100)];

	// Update colorwell
	[mColorWell setPainter:color];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateValuesWithLCH:(WDColor *)color
{
	component0Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(color.lch_L)];
	component1Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(color.lch_C)];
	component2Value_.text =
	[NSString stringWithFormat:@"%d°", (int)round(color.lch_H)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateValuesWithLab:(WDColor *)color
{
	component0Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(color.lab_L)];
	component1Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(color.lab_a)];
	component2Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(color.lab_b)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateValuesWithHSB:(WDColor *)color
{
	component0Value_.text =
	[NSString stringWithFormat:@"%d°", (int)round(color.hsb_H)];
	component1Value_.text =
	[NSString stringWithFormat:@"%d%%", (int)round(color.hsb_S)];
	component2Value_.text =
	[NSString stringWithFormat:@"%d%%", (int)round(color.hsb_B)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateValuesWithRGB:(WDColor *)color
{
	component0Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(255*color.rgb_R)];
	component1Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(255*color.rgb_G)];
	component2Value_.text =
	[NSString stringWithFormat:@"%d", (int)round(255*color.rgb_B)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) updateViewWithColorModel:(WDColorModel)model
{
	// setTrackGradient will undo dynamicTrack 
	[mSlider0 setDynamicTrackGradient:YES];
	[mSlider2 setDynamicTrackGradient:YES];

	if (model == WDColorModelLCH)
	{
		[mSlider2 setTrackGradient:[WDColor hueGradientLCH]];

		component0Name_.text = @"L";
		component1Name_.text = @"C";
		component2Name_.text = @"H";

		[mColorModelButton setTitle:@"LCH" forState:UIControlStateNormal];
	}
	else
	if (model == WDColorModelLab)
	{
		component0Name_.text = @"L";
		component1Name_.text = @"a";
		component2Name_.text = @"b";

		[mColorModelButton setTitle:@"Lab" forState:UIControlStateNormal];
	}
	else
	if (model == WDColorModelHSB)
	{
		[mSlider0 setTrackGradient:[WDColor hueGradientHSB]];
		
		component0Name_.text = @"H";
		component1Name_.text = @"S";
		component2Name_.text = @"B";

		[mColorModelButton setTitle:@"HSB" forState:UIControlStateNormal];
	}
	else
	{
		component0Name_.text = @"R";
		component1Name_.text = @"G";
		component2Name_.text = @"B";

		[mColorModelButton setTitle:@"RGB" forState:UIControlStateNormal];
	}

	[self updateViewWithColor:self.color];
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
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) switchColorModel:(id)sender
{
	WDColorModel model = mColorModel;

	if (model == WDColorModelRGB)
		model = WDColorModelHSB;
	else
	if (model == WDColorModelHSB)
		model = WDColorModelLab;
	else
	if (model == WDColorModelLab)
		model = WDColorModelLCH;
	else
	if (model == WDColorModelLCH)
		model = WDColorModelRGB;

	[self setColorModel:model];
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
