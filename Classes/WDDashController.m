////////////////////////////////////////////////////////////////////////////////
/*
	WDDashController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDDashController.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDDashController
////////////////////////////////////////////////////////////////////////////////

- (id) init
{ return [self initWithNibName:@"DashOptions" bundle:nil]; }

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.opaque = NO;
	self.view.backgroundColor = nil;

	[self prepareControlTitles];
	[self prepareControlActions];
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareControlTitles
{
	mSlider0.titleLabel.text = NSLocalizedString(@"Dash", @"Dash");
	mSlider1.titleLabel.text = NSLocalizedString(@"Gap", @"Gap");
	mSlider2.titleLabel.text = NSLocalizedString(@"Dash", @"Dash");
	mSlider3.titleLabel.text = NSLocalizedString(@"Gap", @"Gap");
}

////////////////////////////////////////////////////////////////////////////////
/*
	Technically, we are only interested in UIControlEventValueChanged, 
	but we will need dragging someday to implement continuous sliders 
	or update interface...
*/

- (void) prepareControlActions
{
	[mSwitch addTarget:self action:@selector(toggleOptions:)
		forControlEvents:UIControlEventValueChanged];

	[self setSliderAction:@selector(adjustOptions:)
		forControlEvents:
			UIControlEventTouchDragInside |
			UIControlEventTouchDragOutside];

	[self setSliderAction:@selector(adjustOptionsFinal:)
		forControlEvents:UIControlEventValueChanged];
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

- (void) updateViewWithOptions:(WDDashOptions *)options
{
	[mSwitch setOn:[options active]];
	[mSlider0 setValue:[options dash0]];
	[mSlider1 setValue:[options gap0]];
	[mSlider2 setValue:[options dash1]];
	[mSlider3 setValue:[options gap1]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDashOptions:(WDDashOptions *)options
{
	[self updateViewWithOptions:options];
}

////////////////////////////////////////////////////////////////////////////////

- (WDDashOptions *) dashOptions
{
	WDDashOptions *dashOptions = [WDDashOptions new];

	[dashOptions setActive:[mSwitch isOn]];
	[dashOptions setPattern:@[
		@([mSlider0 value]),
		@([mSlider1 value]),
		@([mSlider2 value]),
		@([mSlider3 value])]];

	return dashOptions;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) toggleOptions:(id)sender
{
	[[UIApplication sharedApplication]
	sendAction:_action to:_target from:self forEvent:nil];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustOptions:(id)sender
{
	_tracking = YES;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustOptionsFinal:(id)sender
{
	[self adjustOptions:sender];
	_tracking = NO;

	[[UIApplication sharedApplication]
	sendAction:_action to:_target from:self forEvent:nil];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
