////////////////////////////////////////////////////////////////////////////////
/*
	WDColorIndicator.h
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
@interface WDColorIndicator : UIView // TODO: change to CALayer

@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) BOOL showsAlpha;

+ (WDColorIndicator *) colorIndicator;

@end
////////////////////////////////////////////////////////////////////////////////

