//
//  WDShadowController.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDDrawingController;

#import "WDColorController.h"
#import "WDAnglePicker.h"
#import "WDSparkSlider.h"
#import "WDBlendOptionsController.h"


@interface WDShadowController : UIViewController
<WDBlendOptionsControllerDelegate>
{
	WDColorController       *colorController_;
	IBOutlet UISwitch       *shadowSwitch_;
	IBOutlet WDAnglePicker  *angle_;
	IBOutlet WDSparkSlider  *offset_;
	IBOutlet WDSparkSlider  *radius_;

	WDBlendOptionsController *mBlendOptionsController;

	BOOL mDidAdjust;
}

@property (nonatomic, weak) WDDrawingController *drawingController;

- (IBAction) toggleShadow:(id)sender;

@end
