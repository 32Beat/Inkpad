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
		[mLabel setText:[mShape paramName]];
		[mSlider setValue:[mShape paramValue]];

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
		if (!mTracking)
		{ [mShape prepareSetParamValue]; }

		[mShape setParamValue:[mSlider value]];

		mTracking = [mSlider isTracking];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////










