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

#import "WDShape.h"
#import "WDStarShape.h"

////////////////////////////////////////////////////////////////////////////////
@interface WDStarShapeOptionsView : UIView
{
	IBOutlet UISlider *mCountSlider;
	IBOutlet UILabel *mCountSliderLabel;
	IBOutlet UILabel *mCountResultLabel;

	IBOutlet UISlider *mRadiusSlider;
	IBOutlet UILabel *mRadiusSliderLabel;
	IBOutlet UILabel *mRadiusResultLabel;

	BOOL mTracking;

	__weak WDStarShape *mShape;
}

- (void) setShape:(id)shape;

@end
////////////////////////////////////////////////////////////////////////////////
