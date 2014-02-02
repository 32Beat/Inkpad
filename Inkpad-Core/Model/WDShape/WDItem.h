////////////////////////////////////////////////////////////////////////////////
/*
	WDItem.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
/*
	Design proposition:

	WDItem
	WDStylableItem = WDItem with WDStyle entry

		#import "WDStyle.h"
			#import "WDFillStyle.h"
			#import "WDStrokeStyle.h"
			#import "WDShadowStyle.h"
			#import "WDBlendStyle.h"

	
		All items produce at least a bounds path = (rectangle with transform applied)
		
		This can always be styled, even for e.g. image objects
		WDStyle can be a dictionary containing only relevant style elements
		
		WDStylableItem styleBounds = [mStyleInfo expandRenderArea:[self bounds]]
		
	WDShape = WDStylableItem with contentsPath
	WDPath = WDStylableItem with WDItems as nodes
	
	WDShape convertToPath loses the ability to adjust contents by parameters,
	but keeps the ability to adjust stylable properties
*/

////////////////////////////////////////////////////////////////////////////////

@protocol WDItemManager
- (void) itemWillAdjust:(id)item;
- (void) itemDidAdjust:(id)item;
@end

////////////////////////////////////////////////////////////////////////////////
@interface WDItem : NSObject <NSCoding, NSCopying>
{
	// Model
	CGSize mSize;
	CGAffineTransform mTransform;

	id mContent; // ? NSArray / WDItem

	// Cache
	CGRect mFrameBounds;
	CGPathRef mFramePath;

	// Owner
	__weak id<WDItemManager> mItemManager;
}

@property (nonatomic, weak) id<WDItemManager> itemManager;


+ (id) itemWithFrame:(CGRect)frame;
- (id) initWithFrame:(CGRect)frame;

- (void) setFrame:(CGRect)frame;
- (void) setPosition:(CGPoint)P;
- (void) setSize:(CGSize)size;

- (CGRect) sourceRect;
// sourceRect = combination of size & anchorpoint,
// always includes {0,0}, usually at center

- (CGPathRef) framePath;
// framePath = sourceRect + transform

- (CGRect) frameBounds;
// frameBounds = bounding box of sourceRect + transform



- (void) flushCache;
// subclasses should call this to invalidate frame parameters

@end
////////////////////////////////////////////////////////////////////////////////




