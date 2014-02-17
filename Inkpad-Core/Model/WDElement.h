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

#import "WDStyleOptions.h"

/*
	ElementOwner
	------------
	Protocol for an element container
	An element owner should be able to act as a kind of delegate for
	element state changes, e.g. accumulate undo and update areas.
	
	It should also be able to report back renderAreas, so the core
	drawing controller can request update areas through a bottom-up chain
*/
@protocol ElementOwner
- (void)element:(WDElement*)element willChangeProperty:(id)propertyKey;
- (void)element:(WDElement*)element didChangeProperty:(id)propertyKey;

- (CGRect) renderAreaForRect:(CGRect)sourceRect;
@end

////////////////////////////////////////////////////////////////////////////////

@interface WDElement : NSObject <NSCoding, NSCopying, WDStyleOptionsDelegate>
{
	// Model properties
	CGSize mSize;
	CGPoint mPosition;
	CGFloat mRotation;

	WDStyleOptions *mStyleOptions;

	// Active state vars
	WDEditMode mEditMode;
	__weak id<ElementOwner> mOwner;

	// Cached info
	CGAffineTransform mTransform;
	
	WDQuad mFrame;
	CGPathRef mFramePath;

	CGRect mFrameBounds;
	CGRect mStyleBounds;
	CGRect mShadowBounds;
	CGRect mRenderBounds;

	CGRect dirtyBounds_;
}

// Fundamental properties
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat rotation;

// Context properties
@property (nonatomic, strong) WDStyleOptions *styleOptions;

// "There can be only one!"
@property (nonatomic, weak) id owner;


//- (WDStyleOptions *) blendStyleOptions;
//- (WDStyleOptions *) strokeStyleOptions;

/*
	styleProperties
		blendStyleProperties
			blendMode
			blendOpacity
		shadowStyleProperties
		fillStyleProperties
		strokeStyleProperties
		textStyleProperties


	while element is generic, we could technically consider it 
	as always stylable:
	
	path = framepath
	
	drawing order: 
	1. draw fill
	2. draw content
	3. draw stroke (as border)

{ [[self styleOptions] valueForKey:WDBlendStyleOptionsKey]; }
{ [[self styleOptions] valueForKey:WDStrokeStyleOptionsKey]; }
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
	
	
	Styles
	
	Add WDStyleProperties object as a wrapper around dictionary which 
	accommodates computations: 
	
		[[WDStyleProperties styleWithProperties:dictionary]
			renderAreaForRect:(CGRect)sourceRect];
		
		derived objects:
		[[WDShadowStyle styleWithProperties:dictionary] renderAreaForRect:];
		[[WDStrokeStyle styleWithProperties:dictionary] renderAreaForRect:];

		[WDStrokeStyle renderAreaWithProperties:props sourceRect:R];
		[WDStrokeStyle renderAreaWithProperties:props sourcePath:path];

		[WDStrokeStyle applyProperties:props toContext:cgcontext];
		
	de facto:
	WD...Style acts as controller object for specific styledictionary, 
	may use an internal mutable dictionary, returns a fixed dictionary 
	with a copy of values. Values can be get/set normally.
	
	An element does not have WD...Style objects internally, just dictionaries
	
	style = [WDStrokeStyle styleWithProperties:dictionary];
	[style setStrokeWidth:1.0];
	newProperties = [style properties];
	
	//
	[properties setValue:[NSValue valueWithCGFloat:1.0] 
		forKey:WDPropertyStrokeStyleLineWidthKey];
	
	[element setValue: forKey:]
	
	
	

	[style setValue:forKey:]
	{
		if (![mProperties isKindOfClass:[NSMutableDictionary class]])
		{ mProperties = [mProperties mutableCopy]; }
		[mProperties setValue:forKey:];
	}
	
	[strokeStyle setLineWidth:]
	{
		[self setValue:[NSValue valueWithCGFloat:lineWidth] 
		forKey:WDPropertyStrokeStyleLineWidthKey];
	}

*/


// Owner references for convenience
@property (nonatomic, weak) WDLayer *layer; // layer
@property (nonatomic, weak) WDGroup *group;  // pointer to parent group, if any

@property (nonatomic, assign) float opacity;
@property (nonatomic, assign) CGBlendMode blendMode;
@property (nonatomic, strong) WDShadow *shadow;
@property (nonatomic, strong) WDShadow *initialShadow;
@property (weak, nonatomic, readonly) NSUndoManager *undoManager;
@property (weak, nonatomic, readonly) WDDrawing *drawing;
@property (weak, nonatomic, readonly) NSSet *inspectableProperties;

- (void) awakeFromEncoding;

- (void) saveState;
- (void) resetState:(WDElement *)srcElement;
- (void) takePropertiesFrom:(WDElement *)srcElement;

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
- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData;

- (void) tossCachedColorAdjustmentData;
- (void) restoreCachedColorAdjustmentData;
- (void) registerUndoWithCachedColorAdjustmentData;

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

- (CGSize) sourceSize;
- (CGRect) sourceRect;
- (CGAffineTransform) sourceTransform;
- (CGAffineTransform) computeSourceTransform;

- (void) setTransform:(CGAffineTransform)T;
- (void) setTransform:(CGAffineTransform)T sourceRect:(CGRect)sourceRect;



- (CGRect) bounds;
- (CGRect) styleBounds;
- (CGRect) computeStyleBounds;
- (CGRect) shadowBounds;
- (CGRect) computeShadowBounds;
- (CGRect) renderBounds;
- (CGRect) computeRenderBounds;

- (CGRect) expandRenderArea:(CGRect)R;

- (void) invalidateBounds;
- (void) invalidateStyleBounds;
- (void) invalidateShadowBounds;


- (CGRect) subselectionBounds;
- (void) clearSubselection;

////////////////////////////////////////////////////////////////////////////////

- (WDQuad) frameQuad;
- (CGPoint) frameCenter;

//- (id) frameControlWithIndex:(NSInteger)n;
//- (id) findFrameControlForRect:(CGRect)touchR;
- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)d;

- (NSInteger) findFrameControlIndexForRect:(CGRect)touchR;
- (CGPoint) frameControlPointAtIndex:(NSInteger)n;

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context;


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



- (NSSet *) transform:(CGAffineTransform)transform;



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
- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager;
- (id) valueForProperty:(NSString *)property;
- (NSSet *) inspectableProperties;
- (BOOL) canInspectProperty:(NSString *)property;
- (void) propertyChanged:(NSString *)property;
- (void) propertiesChanged:(NSSet *)property;
- (id) pathPainterAtPoint:(CGPoint)pt;
- (BOOL) hasFill;

- (BOOL) needsToSaveGState:(float)scale;
- (BOOL) needsTransparencyLayer:(float)scale;

- (void) beginTransparencyLayer:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData;
- (void) endTransparencyLayer:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData;

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
