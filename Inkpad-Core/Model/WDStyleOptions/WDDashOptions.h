////////////////////////////////////////////////////////////////////////////////
/*
	WDDashOptions.h
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
	WDDashOptions
	---------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDDashOptionsKey;
extern NSString *const WDDashActiveKey;
extern NSString *const WDDashPatternKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDDashOptions : WDStyleOptions
{
	BOOL 		mActive;
	CGFloat 	mPhase;
	NSArray 	*mPattern;
}

@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, strong) NSArray *pattern;

- (BOOL) visible;
- (CGFloat) dash0;
- (CGFloat) gap0;
- (CGFloat) dash1;
- (CGFloat) gap1;

- (id) optionsWithScale:(float)scale;

@end
////////////////////////////////////////////////////////////////////////////////





