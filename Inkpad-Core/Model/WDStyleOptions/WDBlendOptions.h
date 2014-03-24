////////////////////////////////////////////////////////////////////////////////
/*
	WDBlendOptions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStyleOptions.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDBlendOptions
	--------------
	
	dev note: make shadow options part of blendoptions, 
	create BlendSwatch
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDBlendOptionsKey;
extern NSString *const WDBlendModeKey;
extern NSString *const WDBlendOpacityKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDBlendOptions : WDStyleOptions
{
	CGBlendMode mMode;
	CGFloat mOpacity;
}

@property (nonatomic, assign) CGBlendMode mode;
@property (nonatomic, assign) CGFloat opacity;

- (BOOL) visible;
- (BOOL) transparent;

@end
////////////////////////////////////////////////////////////////////////////////





