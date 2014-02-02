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
#import "WDShape.h"

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

	IBOutlet id mView;
	IBOutlet id mSlider;
}

+ (id) shapeControllerWithShape:(WDShape *)shape;
- (id) initWithShape:(WDShape *)shape;

- (id) view;

- (IBAction) adjustValue:(id)sender;

@end
////////////////////////////////////////////////////////////////////////////////





