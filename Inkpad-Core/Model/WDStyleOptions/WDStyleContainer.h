////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleContainer.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "WDFrameOptions.h"
#import "WDBlendOptions.h"
#import "WDShadowOptions.h"
#import "WDStrokeOptions.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleContainer
	----------------
	Controller object for style options

	- Order is important
	
	- Generally itemOptions are to be considered immutable units, 
	they will be copied when set.

*/
////////////////////////////////////////////////////////////////////////////////

@protocol WDStyleContainerDelegate
- (void) styleContainer:(id)container willSetOptionsForKey:(id)key;
- (void) styleContainer:(id)container didSetOptionsForKey:(id)key;
@end

////////////////////////////////////////////////////////////////////////////////
@interface WDStyleContainer : NSObject
{
	__weak id<WDStyleContainerDelegate> mDelegate;

	id mFrameOptions;
	id mBlendOptions;
	id mShadowOptions;
	id mStrokeOptions;

	id mContainer;
}

- (id) initWithDelegate:(id<WDStyleContainerDelegate>)delegate;
- (void) decodeWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;

- (void) copyPropertiesFrom:(WDStyleContainer *)srcOptions;

- (id) frameOptions;
- (void) setFrameOptions:(id)options;

- (id) blendOptions;
- (void) setBlendOptions:(id)options;

- (id) shadowOptions;
- (void) setShadowOptions:(id)options;

- (id) strokeOptions;
- (void) setStrokeOptions:(id)options;

- (CGRect) resultAreaForRect:(CGRect)sourceRect;

// 
- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale;
- (BOOL) needsTransparencyLayer;

@end
////////////////////////////////////////////////////////////////////////////////




