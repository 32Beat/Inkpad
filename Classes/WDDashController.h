////////////////////////////////////////////////////////////////////////////////
/*
	WDDashController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import "WDDashOptions.h"
#import "WDSparkSlider.h"

////////////////////////////////////////////////////////////////////////////////
@interface WDDashController : UIViewController
{
	IBOutlet UISwitch               *mSwitch;
	IBOutlet WDSparkSlider          *mSlider0;
	IBOutlet WDSparkSlider          *mSlider1;
	IBOutlet WDSparkSlider          *mSlider2;
	IBOutlet WDSparkSlider          *mSlider3;
}

@property (nonatomic, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

- (void) setDashOptions:(WDDashOptions *)dashOptions;
- (WDDashOptions *)dashOptions;

@end
////////////////////////////////////////////////////////////////////////////////



