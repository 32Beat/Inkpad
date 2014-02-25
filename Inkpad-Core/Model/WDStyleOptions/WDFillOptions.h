////////////////////////////////////////////////////////////////////////////////
/*
	WDFillOptions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStyleOptions.h"
#import "WDColor.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDFillOptions
	---------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDFillOptionsKey;
extern NSString *const WDFillActiveKey;
extern NSString *const WDFillColorKey;
extern NSString *const WDFillRuleKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDFillOptions : WDStyleOptions
{
	BOOL 		mActive;
	WDColor 	*mColor;
	int 		mFillRule;
}

@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) int fillRule;

- (BOOL) visible;

@end
////////////////////////////////////////////////////////////////////////////////





