////////////////////////////////////////////////////////////////////////////////
/*
	WDShapeOptionsController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShapeOptionsController.h"
#import "WDShape.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDShapeOptionsController
////////////////////////////////////////////////////////////////////////////////

+ (id) shapeControllerWithShape:(WDShape *)shape
{ return [[self alloc] initWithShape:shape]; }

////////////////////////////////////////////////////////////////////////////////

- (id) initWithShape:(WDShape *)shape
{
	self = [super init];
	if (self != nil)
	{
		mShape = shape;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	mSlider = nil;
	mView = nil;
	mShape = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

- (id) view
{
	if (mView == nil)
	{ [self loadView]; }
	return mView;
}

////////////////////////////////////////////////////////////////////////////////

- (void) loadView
{
	if ([mShape shapeTypeOptions] == WDShapeOptionsCustom)
		[self loadCustomView];
	else
	if ([mShape shapeTypeOptions] == WDShapeOptionsDefault)
		[self loadDefaultView];
}

////////////////////////////////////////////////////////////////////////////////

- (void) loadCustomView
{
	NSString *typeName = NSStringFromClass([mShape class]);
	NSString *nibName = [typeName stringByAppendingString:@"Options"];

	[[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
	if (mView != nil)
	{
		[[self view] setShape:mShape];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) loadDefaultView
{
	[[NSBundle mainBundle] loadNibNamed:@"WDShapeOptions" owner:self options:nil];
	if (mView != nil)
	{
		// No paramName is okay
		if ([mShape respondsToSelector:@selector(paramName)])
		{ [mLabel setText:[mShape paramName]]; }

		// No paramValue is okay, but slider won't reflect current state
		if ([mShape respondsToSelector:@selector(paramValue)])
		{ [mSlider setValue:[mShape paramValue]]; }

		[mSlider addTarget:self
		action:@selector(adjustValue:)
		forControlEvents:UIControlEventValueChanged];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustValue:(id)sender
{
	// TODO: Use sender isTracking for local undo
	if (sender == mSlider)
	{
		[mShape setParamValue:[mSlider value] withUndo:!mTracking];

		mTracking = [mSlider isTracking];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////










