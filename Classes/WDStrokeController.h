//
//  WDStrokeController.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDDrawingController;
#import "WDColorController.h"
#import "WDDashController.h"

@class WDLineAttributePicker;
@class WDSparkSlider;
@class WDStrokeStyle;

typedef enum {
	kStrokeNone,
	kStrokeColor,
} WDStrokeMode;

@interface WDStrokeController : UIViewController
{
	UISegmentedControl              *modeSegment_;


	WDColorController               *mColorController;
	IBOutlet UILabel 				*mColorPickerView;


	IBOutlet UISlider               *widthSlider_;
	IBOutlet UILabel                *widthLabel_;
	IBOutlet WDLineAttributePicker  *capPicker_;
	IBOutlet WDLineAttributePicker  *joinPicker_;
	
	IBOutlet UIButton               *increment;
	IBOutlet UIButton               *decrement;


	WDDashController 				*mDashController;
	IBOutlet UILabel 				*mDashOptionsView;

	IBOutlet UIButton               *arrowButton_;

	WDStrokeMode                    mode_;

	BOOL mDidAdjust;
}

@property (nonatomic, weak) WDDrawingController *drawingController;

- (IBAction) increment:(id)sender;
- (IBAction) decrement:(id)sender;
- (IBAction) takeStrokeWidthFrom:(id)sender;
- (IBAction) takeFinalStrokeWidthFrom:(id)sender;
- (IBAction) showArrowheads:(id)sender;

@end
