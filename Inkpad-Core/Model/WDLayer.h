//
//  WDLayer.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WDDrawing.h"

#import "WDElement.h"
@class WDXMLElement;

@protocol WDLayerOwner
- (void)layer:(WDLayer*)element willChangeElement:(WDElement *)element;
- (void)layer:(WDLayer*)element didChangeElement:(WDElement *)element;
@end



@interface WDLayer : NSObject <NSCoding, NSCopying, WDElementOwner>
{
	NSArray *mRefreshRects;
}

@property (nonatomic, readonly) NSMutableArray *elements;
@property (nonatomic, strong) WDColor *highlightColor;
@property (nonatomic, weak) WDDrawing *drawing;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) float opacity;
@property (nonatomic, readonly) BOOL editable;
//@property (nonatomic, readonly) CGRect styleBounds;
//@property (nonatomic, readonly) CGRect renderedBounds;
@property (weak, nonatomic, readonly) UIImage *thumbnail;
@property (nonatomic, readonly) BOOL isSuppressingNotifications;

+ (WDLayer *) layer;

- (id) initWithElements:(NSMutableArray *)elements;

- (CGRect) resultArea;
- (CGRect) resultAreaForElement:(WDElement *)element;

- (void) _renderInContext:(const WDRenderContext *)renderContext;
//- (void) renderInContext:(CGContextRef)ctx clipRect:(CGRect)clip metaData:(WDRenderingMetaData)metaData;

- (void) addObject:(id)obj;
- (void) addObjects:(NSArray *)objects;
- (void) removeObject:(id)obj;
- (void) insertObject:(WDElement *)element above:(WDElement *)above;

- (void) addElementsToArray:(NSMutableArray *)elements;

- (void) sendBackward:(NSSet *)elements;
- (void) sendToBack:(NSArray *)sortedElements;
- (void) bringForward:(NSSet *)sortedElements;
- (void) bringToFront:(NSArray *)sortedElements;

- (WDElement *) findContent:(CGRect)touchR;

- (void) invalidateThumbnail;

// draw the layer contents scaled to fit within bounds
- (UIImage *) previewInRect:(CGRect)bounds;

- (void) toggleLocked;
- (void) toggleVisibility;

- (WDXMLElement *) SVGElement;

@end

// notifications
extern NSString *WDLayerVisibilityChanged;
extern NSString *WDLayerLockedStatusChanged;
extern NSString *WDLayerOpacityChanged;
extern NSString *WDLayerContentsChangedNotification;
extern NSString *WDLayerThumbnailChangedNotification;
extern NSString *WDLayerNameChanged;


