////////////////////////////////////////////////////////////////////////////////
/*
	WDFillController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import "WDPathPainter.h"

@class WDColorController;
@class WDDrawingController;
@class WDGradientController;

typedef enum
{
	kFillNone,
	kFillColor,
	kFillGradient
}
WDFillMode;

@interface WDFillController : UIViewController
{
	UISegmentedControl      *modeSegment_;
	WDColorController       *colorController_;
	
	WDGradientController    *gradientController_;
	WDFillMode              fillMode_;
	id<WDPathPainter>       fill_;

	BOOL mDidAdjust;
}

@property (nonatomic, weak) WDDrawingController *drawingController;
@end
