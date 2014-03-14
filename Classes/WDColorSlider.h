////////////////////////////////////////////////////////////////////////////////
/*
	WDColorSlider.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import "WDColor.h"

////////////////////////////////////////////////////////////////////////////////
@interface WDColorSlider : UIControl

@property (nonatomic, strong) id color;
@property (nonatomic, readonly) float floatValue;

// Options
@property (nonatomic, assign) int componentIndex;
@property (nonatomic, assign) BOOL showsAlpha;
@property (nonatomic, assign) BOOL dynamicTrackGradient;
@property (nonatomic, assign) BOOL dynamicIndicatorColor;

- (void) setTrackGradient:(NSArray *)colors;

@end
////////////////////////////////////////////////////////////////////////////////


