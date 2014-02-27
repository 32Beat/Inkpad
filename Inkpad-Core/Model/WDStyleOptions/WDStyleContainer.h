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
#import "WDFillOptions.h"

#import "WDDrawing.h"

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
	id mFillOptions;

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

- (id) fillOptions;
- (void) setFillOptions:(id)options;

/* 
	When resizing an object, its properties may be scaled as well. 
	Properties only allow symmetric scaling. If asymmetric scaling
	is required, then caller is responsible for conversion.
	
	Note: shadow properties do not render according to CTM
*/
- (void) applyScale:(CGFloat)scale;



- (CGRect) resultAreaForRect:(CGRect)sourceRect;

// Prepare global options for context (blend + shadow)
- (void) prepareContext:(const WDRenderContext *)renderContext;
- (void) prepareCGContext:(CGContextRef)context
			scale:(CGFloat)scale
			flipped:(BOOL)flipped;
// NOTE: scale&flipped currently needed for shadows

- (BOOL) needsTransparencyLayer;

@end
////////////////////////////////////////////////////////////////////////////////




