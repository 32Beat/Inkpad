////////////////////////////////////////////////////////////////////////////////
/*
	WDRenderOptions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "WDBlendOptions.h"
#import "WDShadowOptions.h"

////////////////////////////////////////////////////////////////////////////////
/*
	Order is important, 

*/
////////////////////////////////////////////////////////////////////////////////

@protocol WDRenderOptionsDelegate
- (void) renderOptions:(id)options willSetOptionsForKey:(id)key;
- (void) renderOptions:(id)options didSetOptionsForKey:(id)key;
@end

////////////////////////////////////////////////////////////////////////////////
@interface WDRenderOptions : NSObject
{
	__weak id mDelegate;

	id mContainer;

	id mBlendOptions;
	id mShadowOptions;
}

- (id) initWithDelegate:(id<WDRenderOptionsDelegate>)delegate;

- (void) decodeWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;

- (id) blendOptions;
- (void) setBlendOptions:(id)options;

- (id) shadowOptions;
- (void) setShadowOptions:(id)options;

- (CGRect) resultAreaForRect:(CGRect)sourceRect;
- (void) prepareCGContext:(CGContextRef)context;

@end
////////////////////////////////////////////////////////////////////////////////




