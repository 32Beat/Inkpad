////////////////////////////////////////////////////////////////////////////////
/*
	WDStarShapeOptionsView.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStarShapeOptionsView.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDStarShapeOptionsView
////////////////////////////////////////////////////////////////////////////////

- (void) setShape:(id)shape
{
	mShape = shape;
	[mCountSlider setValue:[shape pointCount]];
	[mRadiusSlider setValue:[shape innerRadius]];

	[self updateLabels];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateLabels
{
	long N = [mShape pointCount];
	[mCountResultLabel setText:
	[NSString stringWithFormat:@"%d",(int)N]];

	float R = [mShape innerRadius];
	[mRadiusResultLabel setText:
	[NSString stringWithFormat:@"%1.2f",R]];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustValue:(id)sender
{
	if (sender == mCountSlider)
	{
		long N = [mCountSlider value];
		[mShape adjustPointCount:N withUndo:!mTracking];
		[self updateLabels];

		mTracking = [mCountSlider isTracking];
	}
	else
	if (sender == mRadiusSlider)
	{
		float R = [mRadiusSlider value];
		[mShape adjustInnerRadius:R withUndo:!mTracking];
		[self updateLabels];

		mTracking = [mRadiusSlider isTracking];
	}
}


////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
