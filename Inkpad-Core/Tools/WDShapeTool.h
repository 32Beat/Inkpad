//
//  WDShapeTool.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDTool.h"

typedef enum WDShapeMode
{
	WDShapeModeRectangle = 0,
	WDShapeModeOval,
	WDShapeModeStar,
	WDShapeModePolygon,
	WDShapeModeLine,
	WDShapeModeSpiral
}
WDShapeMode;



@interface WDShapeTool : WDTool {
    WDShapeMode                 shapeMode_;
    
#if TARGET_OS_IPHONE
    IBOutlet UIView     *optionsView_;
    IBOutlet UILabel    *optionsTitle_;
    IBOutlet UILabel    *optionsValue_;
    IBOutlet UISlider   *optionsSlider_;
    IBOutlet UIButton   *increment_;
    IBOutlet UIButton   *decrement_;
#endif
    
    // polygon support
    int                 numPolygonPoints_;
    
    // rect support
    float               rectCornerRadius_;
    
    // star support
    int                 numStarPoints_;
    float               starInnerRadiusRatio_;
    float               lastStarRadius_;
    
    // spiral support
    int                 decay_;
}

@property (nonatomic, assign) WDShapeMode shapeMode;

+ (id) tools;
+ (id) rectangleTool;
+ (id) ovalTool;
+ (id) starTool;
+ (id) polygonTool;
+ (id) lineTool;
+ (id) spiralTool;

+ (id) shapeToolWithMode:(WDShapeMode)mode;
- (id) initWithMode:(WDShapeMode)mode;

- (IBAction) increment:(id)sender;
- (IBAction) decrement:(id)sender;
- (IBAction) takeFinalSliderValueFrom:(id)sender;
- (IBAction) takeSliderValueFrom:(id)sender;

@end
