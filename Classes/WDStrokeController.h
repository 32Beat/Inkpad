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
	IBOutlet UISlider               *widthSlider_;
	IBOutlet UILabel                *widthLabel_;
	IBOutlet WDLineAttributePicker  *capPicker_;
	IBOutlet WDLineAttributePicker  *joinPicker_;
	
	IBOutlet UIButton               *increment;
	IBOutlet UIButton               *decrement;

	IBOutlet UILabel 				*mColorPickerView;
	IBOutlet UILabel 				*mDashOptionsView;

	IBOutlet UIButton               *arrowButton_;
	
	UISegmentedControl              *modeSegment_;
	WDColorController               *mColorController;
	WDDashController 				*mDashController;
	
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
