////////////////////////////////////////////////////////////////////////////////
/*
	WDElement.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "WDDrawing.h"
#import "WDXMLElement.h"
#import "WDUtilities.h"

#if TARGET_OS_IPHONE
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#else 
#import <OpenGL/gl.h>
#endif

////////////////////////////////////////////////////////////////////////////////
/*
	WDElement
	---------
	Base class for all drawable objects in a document
	
	Manages the size, position, and rotation of drawable objects, 
	as well as its stylable properties. Default behavior will 
	draw a rectangular frame in correct position and orientation with 
	fill properties applied to its interior, and stroke properties 
	applied to its border.
	
	Contains granular drawing drill-down with several hooks to allow 
	for easy customization.
*/
////////////////////////////////////////////////////////////////////////////////
/*
	WDEditMode
	----------
	Indicates the current edit mode of an object
	
	The behavior and representation of objects may change depending 
	on the editing mode. To indicate frame editing, the object will 
	be drawn with a frame that includes circular controlpoints. 
	Frame editing allows the object to be resized, repositioned, and rotated. 

	Content editing will generally draw controlpoints for content, e.g.
	beziercurve controls, and style editing will draw controlpoints for style. 
	
	If required, editingmode options can be combined into a bitmask.
*/

typedef enum
{
	eWDEditModeLocked 	= (-1),
	eWDEditModeNone 	= 0,
	eWDEditModeFrame 	= (1<<0),
	eWDEditModeContent 	= (1<<1),
	eWDEditModeStyle 	= (1<<2),
	eWDEditModeText 	= (1<<3)
}
WDEditMode;

////////////////////////////////////////////////////////////////////////////////
/*
	ElementOwner
	------------
	Protocol for an element container
	An element owner should be able to act as a kind of delegate for
	element state changes, e.g. accumulate undo and update areas.
	
	It should also be able to report back renderAreas, so the core
	drawing controller can request update areas through a bottom-up chain
*/
@protocol WDElementOwner
- (void)element:(WDElement*)element willChangePropertyForKey:(id)propertyKey;
- (void)element:(WDElement*)element didChangePropertyForKey:(id)propertyKey;

- (CGRect) resultAreaForRect:(CGRect)sourceRect;
@end

////////////////////////////////////////////////////////////////////////////////


typedef enum {
	WDAlignLeft,
	WDAlignCenter,
	WDAlignRight,
	WDAlignTop,
	WDAlignMiddle,
	WDAlignBottom
} WDAlignment;

typedef enum {
	WDColorAdjustStroke = 1 << 0,
	WDColorAdjustFill   = 1 << 1,
	WDColorAdjustShadow = 1 << 2
} WDColorAdjustmentScope;

@class WDGroup;
@class WDLayer;
@class WDPickResult;
@class WDPropertyManager;
@class WDShadow;
@class WDXMLElement;

#import "WDStyleContainer.h"

////////////////////////////////////////////////////////////////////////////////

@interface WDElement : NSObject <NSCoding, NSCopying, WDStyleContainerDelegate>
{
	// Only need one owner reference
	__weak id<WDElementOwner> mOwner;

	// Fundamental properties
	CGSize mSize;
	CGPoint mPosition;
	CGFloat mRotation;

	// Context properties
	WDStyleContainer *mStyleOptions;


	// Active state vars
	WDEditMode mEditMode;

	// Cached info
	CGAffineTransform mTransform;
	CGRect mFrameBounds;
	CGRect mStyleBounds;

	NSInteger mTransparency;
	
	WDQuad mFrame;
	CGPathRef mFramePath;
}

// "There can be only one!"
@property (nonatomic, weak) id<WDElementOwner> owner;

// Fundamental properties
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat rotation;

// Context properties
@property (nonatomic, strong) WDStyleContainer *styleOptions;

/*
	styleProperties
		blendStyleProperties
			blendMode
			blendOpacity
		shadowStyleProperties
			shadowActive
			shadowColor
			shadowAngle
			shadowOffset (distance)
			shadowBlur
		strokeStyleProperties
			strokeActive
			strokeColor
			strokeLineWidth
			strokeLineCap
			strokeLineJoin
			strokeMiterLimit
			strokeDashOptions
				dashActive
				dashPattern
		fillStyleProperties
			fillActive
			fillType
			fillColor
			...
		textStyleProperties
*/

/*
	No undo manager,
	No drawing 
	
	An element is fundamentally stupid and should preferably have 
	no understanding of environment other than an owner reference 
	to report changes.
	
	owner is technically no different than a delegate and should respond to:
	
		[owner element:self willChangeProperty:propertyKey];
		[owner element:self didChangeProperty:propertyKey];

	And likewise, layer should report back to its owner (drawing):
	
		[owner layer:self willChangeElement:element];
		[owner layer:self didChangeElement:element];
	
	WDDrawing can make all necessary arrangements for undo and updates.

	A group should pass these messages on to its owner:
		[groupOwner element:initialElement willChangeProperty:propertyKey];

	One additional call helps rendering updates while at the same time
	synchronizing with styles:
	
		[owner renderAreaForRect:(CGRect)];
		
		? [owner renderAreaForArea:(WDQuad)???]
*/

// Owner references for convenience
@property (nonatomic, weak) WDLayer *layer; // layer
@property (nonatomic, weak) WDGroup *group;  // pointer to parent group, if any


@property (nonatomic, strong) WDShadow *shadow;
@property (nonatomic, strong) WDShadow *initialShadow;
@property (weak, nonatomic, readonly) NSUndoManager *undoManager;
@property (weak, nonatomic, readonly) WDDrawing *drawing;
@property (weak, nonatomic, readonly) NSSet *inspectableProperties;


- (id) initWithSize:(CGSize)size;
- (id) initWithFrame:(CGRect)frame;

- (void) encodeWithCoder:(NSCoder *)coder;
- (void) decodeWithCoder:(NSCoder *)coder;
- (void) decodeWithCoder0:(NSCoder *)coder;


- (void) willChangePropertyForKey:(id)key;
- (void) didChangePropertyForKey:(id)key;
- (void) saveState;
- (void) resetState:(WDElement *)srcElement;
- (void) copyPropertiesFrom:(WDElement *)srcElement;

////////////////////////////////////////////////////////////////////////////////
/*
	intersectsRect
		frameIntersectsRect
		contentIntersectsRect
			strokeIntersectsRect
			fillIntersectsRect
				containsPoint:WDCenterOfRect

*/

- (BOOL) containsPoint:(CGPoint)P;
- (BOOL) intersectsRect:(CGRect)R;
- (BOOL) frameIntersectsRect:(CGRect)R;
- (BOOL) contentIntersectsRect:(CGRect)R;

////////////////////////////////////////////////////////////////////////////////






- (id) findContentControlsInRect:(CGRect)R;


- (void) cacheDirtyBounds;
- (void) postDirtyBoundsChange;

- (void) tossCachedColorAdjustmentData;
- (void) restoreCachedColorAdjustmentData;
- (void) registerUndoWithCachedColorAdjustmentData;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark EditMode
////////////////////////////////////////////////////////////////////////////////

- (WDEditMode) editMode;
- (void) setEditMode:(WDEditMode)mode;
- (void) increaseEditMode;

- (void) setEditModeLocked;
- (void) setEditModeNone;
- (void) setEditModeFrame;
- (void) setEditModeContent;
- (void) setEditModeStyle;
- (void) setEditModeText;

- (BOOL) isEditingLocked;
- (BOOL) isEditingNone;
- (BOOL) isEditingFrame;
- (BOOL) isEditingContent;
- (BOOL) isEditingStyle;
- (BOOL) isEditingText;

- (BOOL) isLocked;
- (BOOL) isEditable;
- (BOOL) canEditMode:(WDEditMode)mode;
- (BOOL) canEditFrame;
- (BOOL) canEditContent;
- (BOOL) canEditStyle;
- (BOOL) canEditText;

- (BOOL) hasFrameControls;
- (BOOL) hasContentControls;
- (BOOL) hasStyleControls;
- (BOOL) hasTextControls;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

- (CGSize) size;
- (void) setSize:(CGSize)size;
- (CGPoint) position;
- (void) setPosition:(CGPoint)point;
- (CGFloat) rotation;
- (void) setRotation:(CGFloat)rotation;

- (void) flushCache;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Styling
////////////////////////////////////////////////////////////////////////////////

- (WDFrameOptions *) frameOptions;
- (void) setFrameOptions:(WDFrameOptions *)options;

- (WDBlendOptions *)blendOptions;
- (void) setBlendOptions:(WDBlendOptions *)options;
- (WDShadowOptions *)shadowOptions;
- (void) setShadowOptions:(WDShadowOptions *)options;
- (WDStrokeOptions *)strokeOptions;
- (void) setStrokeOptions:(WDStrokeOptions *)options;
- (WDFillOptions *)fillOptions;
- (void) setFillOptions:(WDFillOptions *)options;

- (CGRect) resultAreaForRect:(CGRect)R;

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

//- (WDQuad) frame;
//- (void) setFrame:(WDQuad)frame;


- (CGRect) bounds;

- (CGRect) frameBounds;
- (CGRect) computeFrameBounds;
- (CGRect) styleBounds;
- (CGRect) computeStyleBounds;
- (CGRect) renderBounds;
- (CGRect) computeRenderBounds;

- (void) flushBounds;



- (CGSize) sourceSize;
- (CGRect) sourceRect;
- (CGAffineTransform) sourceTransform;
- (CGAffineTransform) computeSourceTransform;

- (CGFloat) resizeScale;

- (void) setTransform:(CGAffineTransform)T;
- (void) setTransform:(CGAffineTransform)T sourceRect:(CGRect)sourceRect;





- (CGRect) subselectionBounds;
- (void) clearSubselection;

////////////////////////////////////////////////////////////////////////////////

- (void) setFrameRect:(CGRect)frame;

- (CGPathRef) framePath;
- (WDQuad) frameQuad;
- (CGPoint) frameCenter;

//- (id) frameControlWithIndex:(NSInteger)n;
//- (id) findFrameControlForRect:(CGRect)touchR;

- (NSInteger) findFrameControlIndexForRect:(CGRect)touchR;
- (CGPoint) frameControlPointAtIndex:(NSInteger)n;


- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)d;
- (void) applyRotation:(CGFloat)r;

- (NSSet *) transform:(CGAffineTransform)transform;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Rendering
////////////////////////////////////////////////////////////////////////////////

- (void) renderOutline:(const WDRenderContext *)renderContext;
- (void) renderContent:(const WDRenderContext *)renderContext;
	- (void) prepareContext:(const WDRenderContext *)renderContext;
		- (void) renderFill:(const WDRenderContext *)renderContext;
			- (void) prepareFillOptions:(const WDRenderContext *)renderContext;
			- (void) drawFill:(const WDRenderContext *)renderContext;
		- (void) renderStroke:(const WDRenderContext *)renderContext;
			- (void) prepareStrokeOptions:(const WDRenderContext *)renderContext;
			- (void) drawStroke:(const WDRenderContext *)renderContext;
	- (void) restoreContext:(const WDRenderContext *)renderContext;

////////////////////////////////////////////////////////////////////////////////
- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale;
- (void) restoreCGContext:(CGContextRef)context;
- (BOOL) needsTransparencyLayer;
- (void) beginTransparencyLayer:(CGContextRef)context;
- (void) endTransparencyLayer:(CGContextRef)context;

// OLD
- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData;
- (void) outlineInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData;

////////////////////////////////////////////////////////////////////////////////



// OpenGL-based selection rendering
- (void) glDrawWithTransform:(CGAffineTransform)T;
- (void) glDrawWithTransform:(CGAffineTransform)T options:(long)options;

- (void) glDrawFrameWithTransform:(CGAffineTransform)T;
- (void) glDrawFrameControlsWithTransform:(CGAffineTransform)T;

- (void) glDrawContentWithTransform:(CGAffineTransform)T;
- (void) glDrawContentControlsWithTransform:(CGAffineTransform)T;

- (void) glDrawStyleWithTransform:(CGAffineTransform)T;
- (void) glDrawStyleControlsWithTransform:(CGAffineTransform)T;

////////////////////////////////////////////////////////////////////////////////



- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect;
- (void) drawOpenGLAnchorAtPoint:(CGPoint)pt transform:(CGAffineTransform)transform selected:(BOOL)selected;

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform
							viewTransform:(CGAffineTransform)viewTransform;
- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform;

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;
- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform;
- (void) drawGradientControlsWithViewTransform:(CGAffineTransform)transform;
- (void) drawTextPathControlsWithViewTransform:(CGAffineTransform)viewTransform viewScale:(float)viewScale;






- (void) adjustColor:(WDColor * (^)(WDColor *color))adjustment scope:(WDColorAdjustmentScope)scope;

- (NSSet *) alignToRect:(CGRect)rect alignment:(WDAlignment)align;

- (WDPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags;
- (WDPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags;

- (void) addBlendablesToArray:(NSMutableArray *)array;
- (void) addElementsToArray:(NSMutableArray *)array;

- (WDXMLElement *) SVGElement;
- (void) addSVGOpacityAndShadowAttributes:(WDXMLElement *)element;

- (BOOL) canMaskElements;
- (BOOL) hasEditableText;
- (BOOL) canPlaceText;
- (BOOL) isErasable;
- (BOOL) canAdjustColor;

// inspection
- (void) setValue:(id)value
	forProperty:(NSString *)property
	propertyManager:(WDPropertyManager *)propertyManager;
- (id) valueForProperty:(NSString *)property;


- (NSSet *) inspectableProperties;
- (BOOL) canInspectProperty:(NSString *)property;
- (void) propertyChanged:(NSString *)property;
- (void) propertiesChanged:(NSSet *)property;
- (id) pathPainterAtPoint:(CGPoint)pt;
- (BOOL) hasFill;

- (BOOL) needsToSaveGState:(float)scale;

@end

extern NSString *WDElementChanged;
extern NSString *WDPropertyChangedNotification;
extern NSString *WDPropertiesChangedNotification;

extern NSString *WDPropertyKey;
extern NSString *WDPropertiesKey;
extern NSString *WDTransformKey;
extern NSString *WDFillKey;
extern NSString *WDFillTransformKey;
extern NSString *WDStrokeKey;

extern NSString *WDTextKey;
extern NSString *WDFontNameKey;
extern NSString *WDFontSizeKey;
