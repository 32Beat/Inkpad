////////////////////////////////////////////////////////////////////////////////
/*
	WDShapeOptionsController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
@class WDShape;
@protocol WDShapeOptionsViewProtocol
- (void) setShape:(id)shape;
@end

////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeOptions
{
	WDShapeOptionsNone = 0,
	WDShapeOptionsDefault,
	WDShapeOptionsCustom
}
WDShapeOption;

////////////////////////////////////////////////////////////////////////////////
@interface WDShapeOptionsController : NSObject
{
	__strong WDShape *mShape;

	IBOutlet UIView *mView;
	IBOutlet UILabel *mLabel;
	IBOutlet UISlider *mSlider;

	BOOL mTracking;
}

+ (id) shapeControllerWithShape:(WDShape *)shape;

- (id<WDShapeOptionsViewProtocol>) view;

- (IBAction) adjustValue:(id)sender;

@end
////////////////////////////////////////////////////////////////////////////////





