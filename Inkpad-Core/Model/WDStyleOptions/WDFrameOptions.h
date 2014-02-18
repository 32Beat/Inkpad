////////////////////////////////////////////////////////////////////////////////
/*
	WDFrameOptions.h
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
	WDFrameOptions
	--------------
*/
////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDFrameOptionsKey;
extern NSString *const WDFrameSizeKey;
extern NSString *const WDFramePositionKey;
extern NSString *const WDFrameRotationKey;

////////////////////////////////////////////////////////////////////////////////
@interface WDFrameOptions : NSObject
{
	CGSize mSize;
	CGPoint mPosition;
	CGFloat mRotation;
}

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat rotation;

+ (id) frameOptionsWithFrame:(CGRect)frame;

@end
////////////////////////////////////////////////////////////////////////////////





