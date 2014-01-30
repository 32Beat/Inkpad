//
//  WDBezierNode.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDPickResult.h"

#import <UIKit/UIKit.h>


typedef enum
{
	WDReflect,
	WDIndependent,
	WDReflectIndependent
}
WDBezierNodeReflectionMode;

typedef enum {
    kWDBezierNodeRenderOpen,
    kWDBezierNodeRenderClosed,
    kWDBezierNodeRenderSelected
} WDBezierNodeRenderMode;

@interface WDBezierNode : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	// Model
	CGPoint 	anchorPoint_;
	CGPoint 	outPoint_;
	CGPoint 	inPoint_;

	// Internal
	BOOL 		selected_;
	long 		state_;
}

@property (nonatomic, readonly) CGPoint inPoint;
@property (nonatomic, readonly) CGPoint anchorPoint;
@property (nonatomic, readonly) CGPoint outPoint;

@property (nonatomic, readonly) WDBezierNodeReflectionMode reflectionMode;

@property (nonatomic, readonly) BOOL hasInPoint;
@property (nonatomic, readonly) BOOL hasOutPoint;
@property (nonatomic, readonly) BOOL isCorner;

// some helper state... not strictly part of the model, but makes many operations simpler
@property (nonatomic, assign) BOOL selected;

// Deprecated
+ (WDBezierNode *) bezierNodeWithInPoint:(CGPoint)A
							anchorPoint:(CGPoint)B
							outPoint:(CGPoint)C;


+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint;
+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint
									outPoint:(CGPoint)outPoint;
+ (WDBezierNode *) bezierNodeWithAnchorPoint:(CGPoint)anchorPoint
									outPoint:(CGPoint)outPoint
									 inPoint:(CGPoint)inPoint;

- (id) initWithAnchorPoint:(CGPoint)anchorPoint;
- (id) initWithAnchorPoint:(CGPoint)anchorPoint
				  outPoint:(CGPoint)outPoint;
- (id) initWithAnchorPoint:(CGPoint)anchorPoint
				  outPoint:(CGPoint)outPoint
				   inPoint:(CGPoint)inPoint;

- (WDBezierNode *) copyWithTransform:(CGAffineTransform)transform;
- (WDBezierNode *) copyWithNewOutPoint:(CGPoint)P;
- (WDBezierNode *) copyWithNewInPoint:(CGPoint)P;

- (WDBezierNode *) chopHandles;
- (WDBezierNode *) chopOutHandle;
- (WDBezierNode *) chopInHandle;


- (WDBezierNode *) setInPoint:(CGPoint)pt reflectionMode:(WDBezierNodeReflectionMode)reflectionMode;
- (WDBezierNode *) moveControlHandle:(WDPickResultType)pointToTransform toPoint:(CGPoint)pt reflectionMode:(WDBezierNodeReflectionMode)reflectionMode;

- (WDBezierNode *) flippedNode;

- (void) getAnchorPoint:(CGPoint *)anchorPoint
				outPoint:(CGPoint *)outPoint
				inPoint:(CGPoint *)inPoint
				selected:(BOOL *)selected;

@end

@interface WDBezierNode (GLRendering)
- (void) drawGLWithViewTransform:(CGAffineTransform)transform color:(UIColor *)color mode:(WDBezierNodeRenderMode)mode;
@end

