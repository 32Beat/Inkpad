////////////////////////////////////////////////////////////////////////////////
/*
	WDElement.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "UIColor_Additions.h"
#import "WDColor.h"
#import "WDDrawing.h"
#import "WDElement.h"
#import "WDGLUtilities.h"
#import "WDGroup.h"
#import "WDInspectableProperties.h"
#import "WDLayer.h"
#import "WDPickResult.h"
#import "WDPropertyManager.h"
#import "WDShadow.h"
#import "WDSVGHelper.h"
#import "WDUtilities.h"
#import "WDStyleOptions.h"
#import "WDBlendOptions.h"
#import "WDShadowOptions.h"
#import "WDStrokeOptions.h"


////////////////////////////////////////////////////////////////////////////////

static int WDElementMasterVersion = 1;
static NSString *WDElementMasterVersionKey = @"WDElementMasterVersion";

static NSString *WDElementNameKey = @"WDElementName";
static NSString *WDElementVersionKey = @"WDElementVersion";
static NSString *WDElementSizeKey = @"WDElementSize";
static NSString *WDElementPositionKey = @"WDElementPosition";
static NSString *WDElementRotationKey = @"WDElementRotation";

////////////////////////////////////////////////////////////////////////////////


NSString *WDElementChanged = @"WDElementChanged";
NSString *WDPropertyChangedNotification = @"WDPropertyChangedNotification";
NSString *WDPropertiesChangedNotification = @"WDPropertiesChangedNotification";
NSString *WDPropertyKey = @"WDPropertyKey";
NSString *WDPropertiesKey = @"WDPropertiesKey";

//NSString *WDBlendModeKey = @"WDBlendModeKey";
NSString *WDGroupKey = @"WDGroupKey";
NSString *WDLayerKey = @"WDLayerKey";
NSString *WDTransformKey = @"WDTransformKey";
NSString *WDFillKey = @"WDFillKey";
NSString *WDFillTransformKey = @"WDFillTransformKey";
NSString *WDStrokeKey = @"WDStrokeKey";

NSString *WDTextKey = @"WDTextKey";
NSString *WDFontNameKey = @"WDFontNameKey";
NSString *WDFontSizeKey = @"WDFontSizeKey";

NSString *WDObjectOpacityKey = @"WDOpacityKey";
NSString *WDShadowKey = @"WDShadowKey";

#define kAnchorRadius 4

@implementation WDElement

@synthesize size = mSize;
@synthesize position = mPosition;
@synthesize rotation = mRotation;

@synthesize styleOptions = mStyleOptions;
@synthesize owner = mOwner;

@synthesize layer = layer_;
@synthesize group = group_;
//@synthesize opacity = opacity_;
//@synthesize blendMode = blendMode_;
@synthesize shadow = shadow_;
@synthesize initialShadow = initialShadow_;

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	// Cleanup low level constructs
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithSize:(CGSize)size
{
	self = [super init];
	if (self != nil)
	{
		mSize = size;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame
{
	self = [self initWithSize:frame.size];
	if (self != nil)
	{
		mPosition = WDCenterOfRect(frame);
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{       
	WDElement *element = [[[self class] allocWithZone:zone] init];
	if (element != nil)
	{ [element copyPropertiesFrom:self]; }

	return element;
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDElement *)srcElement
{
	[self setSize:[srcElement size]];
	[self setPosition:[srcElement position]];
	[self setRotation:[srcElement rotation]];

	[[self styleOptions] copyPropertiesFrom:[srcElement styleOptions]];
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) elementName
{ return NSStringFromClass([self class]); }

- (NSInteger) elementVersion
{ return 0; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Encoding
////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:WDElementMasterVersion forKey:WDElementMasterVersionKey];

	[self encodeTypeWithCoder:coder];
	[self encodeSizeWithCoder:coder];
	[self encodePositionWithCoder:coder];
	[self encodeRotationWithCoder:coder];

	[self encodeStyleOptionsWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeTypeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[self elementName] forKey:WDElementNameKey];
	[coder encodeInteger:[self elementVersion] forKey:WDElementVersionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeSizeWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGSize(mSize);
	[coder encodeObject:str forKey:WDElementSizeKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodePositionWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGPoint(mPosition);
	[coder encodeObject:str forKey:WDElementPositionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeRotationWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGFloat(mRotation);
	[coder encodeObject:str forKey:WDElementRotationKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeStyleOptionsWithCoder:(NSCoder *)coder
{
	[[self styleOptions] encodeWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Decoding
////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{
		mSize = (CGSize){ 2.0, 2.0 };
		mPosition = (CGPoint){ 0.0, 0.0 };
		mRotation = 0.0;

		NSInteger version =
		[coder decodeIntegerForKey:WDElementMasterVersionKey];

		if (version == 0)
			[self decodeWithCoder0:coder];
		else
			[self decodeWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	[self decodeSizeWithCoder:coder];
	[self decodePositionWithCoder:coder];
	[self decodeRotationWithCoder:coder];
	[self decodeStyleOptionsWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeSizeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDElementSizeKey])
	{
		NSString *str = [coder decodeObjectForKey:WDElementSizeKey];
		if (str != nil) { mSize = CGSizeFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodePositionWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDElementPositionKey])
	{
		NSString *str = [coder decodeObjectForKey:WDElementPositionKey];
		if (str != nil) { mPosition = CGPointFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeRotationWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDElementRotationKey])
	{
		NSString *str = [coder decodeObjectForKey:WDElementRotationKey];
		if (str != nil) { mRotation = CGFloatFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeStyleOptionsWithCoder:(NSCoder *)coder
{
	[[self styleOptions] decodeWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder0:(NSCoder *)coder
{
	/*
		We don't have an owner yet, 
		so updates are not propagated up the command chain
	*/

	if ([coder containsValueForKey:WDBlendModeKey]||
		[coder containsValueForKey:WDObjectOpacityKey])
	{
		WDBlendOptions *blendOptions = [WDBlendOptions new];

		if ([coder containsValueForKey:WDBlendModeKey])
			[blendOptions setMode:
			[coder decodeIntForKey:WDBlendModeKey]];

		if ([coder containsValueForKey:WDObjectOpacityKey])
			[blendOptions setOpacity:
			[coder decodeFloatForKey:WDObjectOpacityKey]];

		[[self styleOptions] setBlendOptions:blendOptions];
	}

	if ([coder containsValueForKey:WDShadowKey])
	{
		WDShadow *shadow = [coder decodeObjectForKey:WDShadowKey];
		if (shadow != nil)
		{
			WDColor *color = [shadow color];
			float radius = [shadow radius];
			float offset = [shadow offset];
			float angle = [shadow angle];

			WDShadowOptions *dstShadow = [WDShadowOptions new];
			[dstShadow setColor:color];
			[dstShadow setAngle:angle];
			[dstShadow setOffset:offset];
			[dstShadow setBlur:radius];
			[[self styleOptions] setShadowOptions:dstShadow];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// Remove
- (NSUndoManager *) undoManager
{
	return self.layer.drawing.undoManager;
}

- (WDDrawing *) drawing
{
	return self.layer.drawing;
}

- (void) setGroup:(WDGroup *)group
{
	if (group == group_) {
		return;
	}
	
	[[self.undoManager prepareWithInvocationTarget:self] setGroup:group_];
	group_ = group;
}

- (WDShadow *) __shadowForStyleBounds
{
	return self.shadow;
}

////////////////////////////////////////////////////////////////////////////////
/*
	Send these so drawing can properly update view
*/

- (void) willChangePropertyForKey:(id)key
{ [mOwner element:self willChangePropertyForKey:key]; }

- (void) didChangePropertyForKey:(id)key
{ [mOwner element:self didChangePropertyForKey:key]; }

////////////////////////////////////////////////////////////////////////////////
/*
	If element = WDGroup or WDCompoundPath we might receive these, 
	pass up the chain
*/

- (void)element:(WDElement*)element willChangePropertyForKey:(id)key
{ [mOwner element:element willChangePropertyForKey:key]; }

- (void)element:(WDElement*)element didChangePropertyForKey:(id)key
{ [mOwner element:element didChangePropertyForKey:key]; }

////////////////////////////////////////////////////////////////////////////////
/*
	TODO: move up in object chain or implement proper hierarchy
*/
- (void) saveState
{
	// Record current properties for undo
	[[self.undoManager prepareWithInvocationTarget:self]
	resetState:[self copy]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) resetState:(WDElement *)srcElement
{
	if (srcElement != nil)
	{
		// Save state for redo
		[self saveState];

		// Store update areas
		[self willChangePropertyForKey:nil];

		// Copy properties from srcElement
		[self copyPropertiesFrom:srcElement];

		// Notify drawingcontroller
		[self didChangePropertyForKey:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

- (CGSize) size
{ return mSize; }

- (void) setSize:(CGSize)size
{
	if ((mSize.width != size.width) ||
		(mSize.height != size.height))
	{
		mSize = size;
		[self flushCache];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) position
{ return mPosition; }

- (void) setPosition:(CGPoint)point
{
	if ((mPosition.x != point.x) ||
		(mPosition.y != point.y))
	{
		mPosition = point;
		[self flushCache];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) rotation
{ return mRotation; }

- (void) setRotation:(CGFloat)rotation
{
	if (mRotation != rotation)
	{
		mRotation = rotation;
		[self flushCache];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushCache
{
	// Reset transform
	mTransform.a = 0.0;
	mTransform.b = 0.0;
	mTransform.c = 0.0;
	mTransform.d = 0.0;

	// Reset dependencies
	mFrame = WDQuadNull;
	if (mFramePath != nil)
	{ CGPathRelease(mFramePath); }
	mFramePath = nil;

	[self flushBounds];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Style Options
////////////////////////////////////////////////////////////////////////////////

- (WDStyleContainer *) styleOptions
{
	return mStyleOptions ? mStyleOptions :
	(mStyleOptions = [[WDStyleContainer alloc] initWithDelegate:self]);
}

////////////////////////////////////////////////////////////////////////////////

- (void) styleContainer:(id)container willSetOptionsForKey:(id)key
{
	[self willChangePropertyForKey:key];
}

- (void) styleContainer:(id)container didSetOptionsForKey:(id)key;
{
	[self flushCache];
	[self didChangePropertyForKey:key];
}

////////////////////////////////////////////////////////////////////////////////

- (id) frameOptions
{ return [[self styleOptions] frameOptions]; }

- (void) setFrameOptions:(WDFrameOptions *)frameOptions
{ [[self styleOptions] setFrameOptions:frameOptions]; }

////////////////////////////////////////////////////////////////////////////////

- (id) blendOptions
{ return [[self styleOptions] blendOptions]; }

- (void) setBlendOptions:(WDBlendOptions *)blendOptions
{ [[self styleOptions] setBlendOptions:blendOptions]; }

////////////////////////////////////////////////////////////////////////////////

- (id) shadowOptions
{ return [[self styleOptions] shadowOptions]; }

- (void) setShadowOptions:(WDShadowOptions *)shadowOptions
{ [[self styleOptions] setShadowOptions:shadowOptions]; }

////////////////////////////////////////////////////////////////////////////////

- (id) strokeOptions
{ return [[self styleOptions] strokeOptions]; }

- (void) setStrokeOptions:(WDStrokeOptions *)strokeOptions
{ [[self styleOptions] setStrokeOptions:strokeOptions]; }

////////////////////////////////////////////////////////////////////////////////
/*
	Element may be owner of elements, such as WDGroup/WDCompoundPath

*/

- (CGRect) resultAreaForRect:(CGRect)R
{
	if (mStyleOptions != nil)
	{ R = [mStyleOptions resultAreaForRect:R]; }

	if (mOwner != nil)
	{ R = [mOwner resultAreaForRect:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale
{
	[[self styleOptions] prepareCGContext:context scale:scale];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Frame Editing
////////////////////////////////////////////////////////////////////////////////

- (CGSize) sourceSize
{ return [self size]; }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceRect
{
	CGSize srcSize = [self sourceSize];
	return (CGRect){{-0.5*srcSize.width, -0.5*srcSize.height}, srcSize };
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) sourceTransform
{
	return
	mTransform.a != 0.0 ||
	mTransform.b != 0.0 ||
	mTransform.c != 0.0 ||
	mTransform.d != 0.0 ?
	mTransform : (mTransform = [self computeSourceTransform]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) computeSourceTransform
{
	CGPoint P = [self position];
	CGFloat r = [self rotation];

	CGAffineTransform T =
	{ 1.0, 0.0, 0.0, 1.0, P.x, P.y};

	if (r != 0.0)
	{
		CGFloat angle = r * M_PI / 180.0;
		T.a = cos(angle);
		T.b = sin(angle);
		T.c = -T.b;
		T.d = +T.a;
	}

	return T;
}

////////////////////////////////////////////////////////////////////////////////
/*
	setTransform
	------------
	Set size, position, rotation based on transform
	
	Used to convert previous version transforms to new properties.
*/
- (void) setTransform:(CGAffineTransform)T
{ [self setTransform:T sourceRect:[self sourceRect]]; }

- (void) setTransform:(CGAffineTransform)T sourceRect:(CGRect)sourceRect
{
	// Compute quad for sourceRect + transform
	WDQuad F = WDQuadWithRect(sourceRect, T);

	// Compute midpoints of quadlines (@2x)
	CGPoint X1 = WDAddPoints(F.P[0], F.P[3]);
	CGPoint X2 = WDAddPoints(F.P[1], F.P[2]);

	CGPoint Y1 = WDAddPoints(F.P[0], F.P[1]);
	CGPoint Y2 = WDAddPoints(F.P[2], F.P[3]);

	// Set size based on average width/height
	[self setSize:(CGSize){
		0.5 * WDDistance(X1, X2),
		0.5 * WDDistance(Y1, Y2)}];

	// Position element at center of quad
	CGPoint C = WDQuadGetCenter(F);
	[self setPosition:C];

	// Compute rotation
	CGPoint P = WDSubtractPoints(X2, X1);
	[self setRotation:WDDegreesFromRadians(atan2(P.y, P.x))];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFrameRect:(CGRect)frame
{
	[self setSize:frame.size];
	[self setPosition:WDCenterOfRect(frame)];
}

////////////////////////////////////////////////////////////////////////////////

- (WDQuad) frameQuad
{
	return WDQuadIsNull(mFrame)==NO ? mFrame :
	(mFrame = WDQuadWithRect([self sourceRect], [self sourceTransform]));
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) framePath
{
	return mFramePath != nil ? mFramePath :
	(mFramePath = WDQuadCreateCGPath([self frameQuad]));
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) frameCenter
{ return WDQuadGetCenter([self frameQuad]); }

////////////////////////////////////////////////////////////////////////////////
/*
- (id) frameControlWithIndex:(NSInteger)n
{
	WDQuad Q = [self frameQuad];
	return ((0<=n)&&(n<=3)) ?
	[NSValue valueWithCGPoint:Q.corners[n]] : nil;
}

////////////////////////////////////////////////////////////////////////////////

- (id) findFrameControlForRect:(CGRect)touchR
{
	for (NSInteger n=0; n!=4; n++)
	{
		id frameControl = [self frameControlWithIndex:n];
		if (frameControl != nil)
		{
			CGPoint P = [frameControl CGPointValue];
			if (CGRectContainsPoint(touchR, P))
			{ return frameControl; }
		}
	}

	return nil;
}
*/
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) findFrameControlIndexForRect:(CGRect)touchR
{
	for (NSInteger n=0; n!=4; n++)
	{
		CGPoint P = [self frameControlPointAtIndex:n];
		if (CGRectContainsPoint(touchR, P))
		{ return n; }
	}

	return -1;
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) frameControlPointAtIndex:(NSInteger)n
{
	WDQuad Q = [self frameQuad];
	return ((0<=n)&&(n<=3)) ?
	Q.P[n] : (CGPoint){ INFINITY, INFINITY };
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)delta
{
	CGPoint P0 = [self frameControlPointAtIndex:n];
	CGPoint P1 = WDAddPoints(P0, delta);

	CGPoint C = mPosition;
	CGPoint D0 = WDSubtractPoints(P0,C);
	CGPoint D1 = WDSubtractPoints(P1,C);

	CGFloat a0 = atan2(D0.y, D0.x);
	CGFloat a1 = atan2(D1.y, D1.x);
	CGFloat da = a1 - a0;

	CGFloat d0 = WDDistance(P0, C);
	CGFloat d1 = WDDistance(P1, C);
	CGFloat d = d0 != 0.0 && d1 != 0.0 ? d1 / d0 : 1.0;

	[self willChangePropertyForKey:WDFrameOptionsKey];

	[self setSize:WDScaleSize(mSize, d, d)];
	[self setRotation:mRotation + 180.0*da/M_PI];

	[self didChangePropertyForKey:WDFrameOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////
/*
	TODO: change environment to degrees
	Environment currently works in radians, 
	but users don't do radians, so we shouldn't store radians in order to 
	prevent rounding issues
*/
- (void) applyRotation:(CGFloat)r
{
	CGFloat degrees = WDDegreesFromRadians(r);
	[self willChangePropertyForKey:WDFrameOptionsKey];
	[self setRotation:mRotation+degrees];
	[self didChangePropertyForKey:WDFrameOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) applyTransform:(CGAffineTransform)transform
{
	
}

- (NSSet *) transform:(CGAffineTransform)transform
{ [self applyTransform:transform]; return nil; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Bounds
////////////////////////////////////////////////////////////////////////////////
/*
	Levels of bounds:
	1. sourceRect = size of source centered around origin
	2. frameBounds = bounding box of transformed source
	3. styleBounds = render area of all local style elements
	4. renderBounds = render area of all local and recursive owner style elements
*/

- (void) glDrawBoundsWithViewTransform:(CGAffineTransform)viewTransform
{
#ifdef WD_DEBUG
	GLfloat clr[4];
	glGetFloatv(GL_CURRENT_COLOR, clr);

	glColor4f(0.0, 0.0, 1.0, .9);
	CGRect R = [self frameBounds];
	R = CGRectApplyAffineTransform(R, viewTransform);
	WDGLStrokeRect(R);

	glColor4f(0.0, 0.5, 0.0, .9);
	R = [self styleBounds];
	R = CGRectApplyAffineTransform(R, viewTransform);
	WDGLStrokeRect(R);

	glColor4f(1.0, 0.0, 0.0, .9);
	R = [self renderBounds];
	R = CGRectApplyAffineTransform(R, viewTransform);
	WDGLStrokeRect(R);

	glColor4f(clr[0], clr[1], clr[2], clr[3]);

#endif
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return [self sourceRect]; }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) frameBounds
{
	if (CGRectIsEmpty(mFrameBounds))
	{ mFrameBounds = [self computeFrameBounds]; }
	return mFrameBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeFrameBounds
{ return CGRectApplyAffineTransform([self sourceRect], [self sourceTransform]); }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) styleBounds
{
	if (CGRectIsEmpty(mStyleBounds))
	{ mStyleBounds = [self computeStyleBounds]; }
	return mStyleBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeStyleBounds
{
	CGRect R = [self frameBounds];
	if (self.styleOptions != nil)
	{ R = [self.styleOptions resultAreaForRect:R]; }
	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) renderBounds
{
	// Can not cache this, since we don't know changes in owners
	return [self computeRenderBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeRenderBounds
{
	CGRect R = [self styleBounds];
	if (mOwner != nil)
	{ R = [mOwner resultAreaForRect:R]; }
	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushBounds
{
	mFrameBounds = CGRectNull;
	mStyleBounds = CGRectNull;
}

////////////////////////////////////////////////////////////////////////////////

- (void) cacheDirtyBounds
{
	//dirtyBounds_ = [self renderBounds];

	// We are appearantly going to affect bounds
	[self flushBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (void) postDirtyBoundsChange
{
	if (!self.drawing) {
		return;
	}

	// the layer should dirty its thumbnail
	[self.layer invalidateThumbnail];

//	CGRect sourceArea = dirtyBounds_;
	CGRect resultArea = [self renderBounds];
	CGRect sourceArea = resultArea;

	if (CGRectEqualToRect(sourceArea, resultArea))
	{
		NSDictionary *userInfo = @{@"rect":
		[NSValue valueWithCGRect:resultArea]};
		[[NSNotificationCenter defaultCenter]
		postNotificationName:WDElementChanged object:self.drawing userInfo:userInfo];
	}
/*
	else
	{
		NSArray *rects = @[
		[NSValue valueWithCGRect:dirtyBounds_],
		[NSValue valueWithCGRect:resultArea]];

		NSDictionary *userInfo = @{@"rects": rects};
		[[NSNotificationCenter defaultCenter]
		postNotificationName:WDElementChanged object:self.drawing userInfo:userInfo];
	}

	dirtyBounds_ = CGRectNull;
*/
}


- (CGRect) subselectionBounds
{
	return [self bounds];
}

- (void) clearSubselection
{
}

- (BOOL) containsPoint:(CGPoint)pt
{
	return CGRectContainsPoint([self bounds], pt);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark 
#pragma mark 

- (BOOL) intersectsRect:(CGRect)R
{
	return
	[self frameIntersectsRect:R]||
	[self contentIntersectsRect:R];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) frameIntersectsRect:(CGRect)R
{
	return WDQuadIntersectsRect([self frameQuad], R);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) contentIntersectsRect:(CGRect)R
{
	return WDQuadContainsPoint([self frameQuad], WDCenterOfRect(R));
}

////////////////////////////////////////////////////////////////////////////////


- (id) findContentControlsInRect:(CGRect)touchR
{
	return nil;
}

#pragma mark RenderInContext
- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
}

- (void) addHighlightInContext:(CGContextRef)ctx
{
}

- (void) tossCachedColorAdjustmentData
{
	self.initialShadow = nil;
}

- (void) restoreCachedColorAdjustmentData
{
	if (!self.initialShadow) {
		return;
	}
	
	self.shadow = self.initialShadow;
	self.initialShadow = nil;
}

- (void) registerUndoWithCachedColorAdjustmentData
{
	if (!self.initialShadow) {
		return;
	}
	
	[(WDElement *)[self.undoManager prepareWithInvocationTarget:self] setShadow:self.initialShadow];
	self.initialShadow = nil;
}

- (void) adjustColor:(WDColor * (^)(WDColor *color))adjustment scope:(WDColorAdjustmentScope)scope
{
	if (self.shadow && scope & WDColorAdjustShadow) {
		if (!self.initialShadow) {
			self.initialShadow = self.shadow;
		}
		self.shadow = [self.initialShadow adjustColor:adjustment];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Edit Mode
////////////////////////////////////////////////////////////////////////////////

- (WDEditMode) editMode
{ return mEditMode; }

////////////////////////////////////////////////////////////////////////////////

- (void) setEditMode:(WDEditMode)mode
{
	if (mEditMode != mode)
	{
		mEditMode = mode;
		//[self postDirtyBoundsChange];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setEditModeLocked
{ [self setEditMode:eWDEditModeLocked]; }

- (void) setEditModeNone
{ [self setEditMode:eWDEditModeNone]; }

- (void) setEditModeFrame
{ [self setEditMode:eWDEditModeFrame]; }

- (void) setEditModeContent
{ [self setEditMode:eWDEditModeContent]; }

- (void) setEditModeStyle
{ [self setEditMode:eWDEditModeStyle]; }

- (void) setEditModeText
{ [self setEditMode:eWDEditModeText]; }

////////////////////////////////////////////////////////////////////////////////

- (void) increaseEditMode
{
	[self setEditMode:[self nextEditMode]];
}

////////////////////////////////////////////////////////////////////////////////

- (WDEditMode) nextEditMode
{
	WDEditMode mode = mEditMode;

	if (mode == eWDEditModeNone)
	{ return eWDEditModeFrame; }

	if (mode > eWDEditModeNone)
	{
		while ((mode <<= 1) <= eWDEditModeText)
		{
			if([self canEditMode:mode])
			{ return mode; }
		}

		mode = eWDEditModeFrame;
	}

	return mode;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void) lockEditing
{ mEditMode = eWDEditModeLocked; }

- (BOOL) isLocked
{ return mEditMode < 0; }

- (BOOL) isEditable
{ return ![self isLocked]; }

- (BOOL) isEditingLocked
{ return mEditMode < 0; }

- (BOOL) isEditingNone
{ return mEditMode == eWDEditModeNone; }

- (BOOL) isEditingFrame
{ return mEditMode & eWDEditModeFrame; }

- (BOOL) isEditingContent
{ return mEditMode & eWDEditModeContent; }

- (BOOL) isEditingStyle
{ return mEditMode & eWDEditModeStyle; }

- (BOOL) isEditingText
{ return mEditMode & eWDEditModeText; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (BOOL) canEditMode:(WDEditMode)mode
{
	switch(mode)
	{
		case eWDEditModeLocked:
		case eWDEditModeNone:
		return YES;

		case eWDEditModeFrame:
		return [self canEditFrame];

		case eWDEditModeContent:
		return [self canEditContent];

		case eWDEditModeStyle:
		return [self canEditStyle];

		case eWDEditModeText:
		return [self canEditText];
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) canEdit
{ return ![self isLocked]; }

- (BOOL) canEditFrame
{ return YES; }

- (BOOL) canEditContent
{ return NO; }

- (BOOL) canEditStyle
{ return NO; }

- (BOOL) canEditText
{ return NO; }

////////////////////////////////////////////////////////////////////////////////

- (BOOL) hasFrameControls
{ return YES; }

- (BOOL) hasContentControls
{ return NO; }

- (BOOL) hasStyleControls
{ return NO; }

- (BOOL) hasTextControls
{ return NO; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL Rendering
////////////////////////////////////////////////////////////////////////////////

- (void) glDrawWithTransform:(CGAffineTransform)T
{ [self glDrawWithTransform:T options:[self editMode]]; }

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawWithTransform:(CGAffineTransform)T options:(long)options
{
	[self glDrawBoundsWithViewTransform:T];

	[self glDrawContentWithTransform:T];
	[self glDrawFrameWithTransform:T];

	if (options & eWDEditModeContent)
	{ [self glDrawContentControlsWithTransform:T]; }
	
	if (options & eWDEditModeFrame)
	{ [self glDrawFrameControlsWithTransform:T]; }

	if (options & eWDEditModeStyle)
	{ [self glDrawStyleControlsWithTransform:T]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawFrameWithTransform:(CGAffineTransform)T
{
	WDGLDrawQuadStroke([self frameQuad], &T);
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawFrameControlsWithTransform:(CGAffineTransform)T
{
	WDGLDrawQuadMarkers([self frameQuad], &T);
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawContentWithTransform:(CGAffineTransform)T
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawContentControlsWithTransform:(CGAffineTransform)T
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawStyleWithTransform:(CGAffineTransform)T
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawStyleControlsWithTransform:(CGAffineTransform)T
{
}

////////////////////////////////////////////////////////////////////////////////


- (void) drawOpenGLAnchorAtPoint:(CGPoint)pt transform:(CGAffineTransform)transform selected:(BOOL)selected
{
	CGPoint P = CGPointApplyAffineTransform(pt, transform);

	if (!selected) {
		glColor4f(1, 1, 1, 1);
		WDGLFillSquareMarker(P);
		[self.layer.highlightColor openGLSet];
		WDGLStrokeSquareMarker(P);
	} else {
		[self.layer.highlightColor openGLSet];
		WDGLFillSquareMarker(P);
	}
}

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
	if (CGRectIntersectsRect(self.bounds, visibleRect)) {
		[self drawOpenGLHighlightWithTransform:viewTransform];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform
							viewTransform:(CGAffineTransform)viewTransform
{
	[self drawOpenGLHighlightWithTransform:
	CGAffineTransformConcat(transform, viewTransform)];

	[self glDrawBoundsWithViewTransform:viewTransform];
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform
{
	CGRect B = [self bounds];
	B = CGRectApplyAffineTransform(B, transform);

	[self.layer.highlightColor openGLSet];
	WDGLStrokeRect(B);
}

////////////////////////////////////////////////////////////////////////////////




- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
}

- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
	CGRect B = [self bounds];
	CGPoint L = { CGRectGetMinX(B), CGRectGetMidY(B) };
	CGPoint R = { CGRectGetMaxX(B), CGRectGetMidY(B) };

//	L = CGPointApplyAffineTransform(L, viewTransform);
//	R = CGPointApplyAffineTransform(R, viewTransform);

	[self drawOpenGLAnchorAtPoint:L transform:transform selected:NO];
	[self drawOpenGLAnchorAtPoint:R transform:transform selected:NO];
}

- (void) drawGradientControlsWithViewTransform:(CGAffineTransform)transform
{
}

- (void) drawTextPathControlsWithViewTransform:(CGAffineTransform)viewTransform viewScale:(float)viewScale
{
}



- (NSSet *) alignToRect:(CGRect)rect alignment:(WDAlignment)align
{
	CGRect              bounds = [self bounds];
	CGAffineTransform	translate = CGAffineTransformIdentity;
	CGPoint             center = WDCenterOfRect(bounds);
	
	CGPoint             topLeft = rect.origin;
	CGPoint             rectCenter = WDCenterOfRect(rect);
	CGPoint             bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	
	switch(align) {
		case WDAlignLeft:
			translate = CGAffineTransformMakeTranslation(topLeft.x - CGRectGetMinX(bounds), 0.0f);
			break;
		case WDAlignCenter:
			translate = CGAffineTransformMakeTranslation(rectCenter.x - center.x, 0.0f);
			break;
		case WDAlignRight:
			translate = CGAffineTransformMakeTranslation(bottomRight.x - CGRectGetMaxX(bounds), 0.0f);
			break;
		case WDAlignTop:
			translate = CGAffineTransformMakeTranslation(0.0f, topLeft.y - CGRectGetMinY(bounds));  
			break;
		case WDAlignMiddle:
			translate = CGAffineTransformMakeTranslation(0.0f, rectCenter.y - center.y);
			break;
		case WDAlignBottom:          
			translate = CGAffineTransformMakeTranslation(0.0f, bottomRight.y - CGRectGetMaxY(bounds));
			break;
	}
	
	[self transform:translate];
	
	return nil;
}

- (WDPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
	return [WDPickResult pickResult];
}

- (WDPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
	return [WDPickResult pickResult];
}

- (void) addElementsToArray:(NSMutableArray *)array
{
	[array addObject:self];
}

- (void) addBlendablesToArray:(NSMutableArray *)array
{
}

- (WDXMLElement *) SVGElement
{
	// must be overriden by concrete subclasses
	return nil;
}

- (void) addSVGOpacityAndShadowAttributes:(WDXMLElement *)element
{
	WDBlendOptions *blendOptions = [[self styleOptions] blendOptions];

	[element setAttribute:@"opacity" floatValue:blendOptions.opacity];
	[element setAttribute:@"inkpad:blendMode"
	value:[[WDSVGHelper sharedSVGHelper] displayNameForBlendMode:blendOptions.mode]];

	[(initialShadow_ ?: shadow_) addSVGAttributes:element];
}

- (NSSet *) changedShadowPropertiesFrom:(WDShadow *)from to:(WDShadow *)to
{
	NSMutableSet *changedProperties = [NSMutableSet set];
	
	if ((!from && to) || (!to && from)) {
		[changedProperties addObject:WDShadowVisibleProperty];
	}
	
	if (![from.color isEqual:to.color]) {
		[changedProperties addObject:WDShadowColorProperty];
	}
	if (from.angle != to.angle) {
		[changedProperties addObject:WDShadowAngleProperty];
	}
	if (from.offset != to.offset) {
		[changedProperties addObject:WDShadowOffsetProperty];
	}
	if (from.radius != to.radius) {
		[changedProperties addObject:WDShadowRadiusProperty];
	}
	
	return changedProperties;
}

- (void) setShadow:(WDShadow *)shadow
{
	if ([shadow_ isEqual:shadow]) {
		return;
	}
	
	[self cacheDirtyBounds];
	
	[(WDElement *)[self.undoManager prepareWithInvocationTarget:self] setShadow:shadow_];
	
	NSSet *changedProperties = [self changedShadowPropertiesFrom:shadow_ to:shadow];
	
	shadow_ = shadow;
	
	[self postDirtyBoundsChange];
	[self propertiesChanged:changedProperties];
}

- (CGFloat) opacity
{ return [[self blendOptions] opacity]; }

- (void) setOpacity:(float)opacity
{
	WDBlendOptions *options = [[self blendOptions] copy];
	[options setOpacity:opacity];
	[self setBlendOptions:options];
}
/*
- (void) setBlendMode:(CGBlendMode)blendMode
{
	if (blendMode == blendMode_) {
		return;
	}
	
	[self cacheDirtyBounds];
	
	[[self.undoManager prepareWithInvocationTarget:self] setBlendMode:blendMode_];
	
	blendMode_ = blendMode;
	
	[self postDirtyBoundsChange];
	[self propertyChanged:WDBlendModeProperty];
}
*/
- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager
{
	if (!value) {
		return;
	}

	if (property == WDShadowOptionsKey)
	{
		[self setShadowOptions:value];
		return;
	}
	//[self saveState];

	WDBlendOptions *blendOptions = [self blendOptions];

	if ([property isEqualToString:WDBlendModeProperty])
	{
		[blendOptions setMode:[value intValue]];
		[self setBlendOptions:blendOptions];
	}
	else
	if ([property isEqualToString:WDOpacityProperty])
	{
		[blendOptions setOpacity:[value floatValue]];
		[self setBlendOptions:blendOptions];
	}

	/* 
		We should never get individual properties here!
	*/
	WDShadowOptions *shadow = self.shadowOptions;
	if (shadow == nil)
	{ shadow = [propertyManager defaultShadowOptions]; }

	if ([property isEqualToString:WDShadowVisibleProperty])
	{
		[shadow setActive:[value boolValue]];
		[self setShadowOptions:shadow];
	}
	else
	if ([property isEqualToString:WDShadowColorProperty])
	{
		[shadow setColor:value];
		[self setShadowOptions:shadow];
	}
	else
	if ([property isEqualToString:WDShadowOffsetProperty]) \
	{
		[shadow setOffset:[value floatValue]];
		[self setShadowOptions:shadow];
	}
	else
	if ([property isEqualToString:WDShadowAngleProperty]) \
	{
		[shadow setAngle:[value floatValue]];
		[self setShadowOptions:shadow];
	}
	else
	if ([property isEqualToString:WDShadowRadiusProperty]) \
	{
		[shadow setBlur:[value floatValue]];
		[self setShadowOptions:shadow];
	}


	WDStrokeOptions *stroke = [self strokeOptions];
	if (stroke == nil)
	{ stroke = [propertyManager defaultStrokeOptions]; }

	if ([property isEqualToString:WDStrokeVisibleProperty]) \
	{
		[stroke setActive:[value boolValue]];
		[self setStrokeOptions:stroke];
	}
	else
	if ([property isEqualToString:WDStrokeColorProperty]) \
	{
		[stroke setColor:value];
		[self setStrokeOptions:stroke];
	}
	else
	if ([property isEqualToString:WDStrokeWidthProperty]) \
	{
		[stroke setLineWidth:[value floatValue]];
		[self setStrokeOptions:stroke];
	}
}




- (id) valueForProperty:(NSString *)property
{
	if (property == WDBlendOptionsKey)
		return [self blendOptions];
	else
	if (property == WDShadowOptionsKey)
		return [self shadowOptions];
	else
	if (property == WDStrokeOptionsKey)
		return [self strokeOptions];
	else
	if ([property isEqualToString:WDOpacityProperty]) {
		return @([[self blendOptions] opacity]);
	} else if ([property isEqualToString:WDBlendModeProperty]) {
		return @([[self blendOptions] mode]);
	} else if ([property isEqualToString:WDShadowVisibleProperty]) {
		return @(self.shadowOptions.active);
	} else if (self.shadowOptions)
	{
		WDShadowOptions *shadowOptions = [self shadowOptions];

		if ([property isEqualToString:WDShadowColorProperty]) {
			return shadowOptions.color;
		} else if ([property isEqualToString:WDShadowOffsetProperty]) {
			return @(shadowOptions.offset);
		} else if ([property isEqualToString:WDShadowRadiusProperty]) {
			return @(shadowOptions.blur);
		} else if ([property isEqualToString:WDShadowAngleProperty]) {
			return @(shadowOptions.angle);
		}
	}
	
	return nil;
}

- (NSSet *) inspectableProperties
{
	return [NSSet setWithObjects:
		WDBlendOptionsKey,
		WDShadowOptionsKey,
		WDStrokeOptionsKey,
		nil];
}

- (BOOL) canInspectProperty:(NSString *)property
{
	return [[self inspectableProperties] containsObject:property];
}

- (void) propertiesChanged:(NSSet *)properties
{   
	if (self.drawing) {
		NSDictionary *userInfo = @{WDPropertiesKey: properties};
		[[NSNotificationCenter defaultCenter] postNotificationName:WDPropertiesChangedNotification object:self.drawing userInfo:userInfo];
	}
}

- (void) propertyChanged:(NSString *)property
{
	if (self.drawing) {
		NSDictionary *userInfo = @{WDPropertyKey: property};
		[[NSNotificationCenter defaultCenter] postNotificationName:WDPropertyChangedNotification object:self.drawing userInfo:userInfo];
	}
}

- (id) pathPainterAtPoint:(CGPoint)pt
{
	return [self valueForProperty:WDFillProperty];
}

- (BOOL) hasFill
{
	return ![[self valueForProperty:WDFillProperty] isEqual:[NSNull null]];
}

- (BOOL) canMaskElements
{
	return NO;
}

- (BOOL) hasEditableText
{
	return NO;
}

- (BOOL) canPlaceText
{
	return NO;
}

- (BOOL) isErasable
{
	return NO;
}

- (BOOL) canAdjustColor
{
	return self.shadow ? YES : NO;
}

- (BOOL) needsToSaveGState:(float)scale
{
	if (self.blendOptions.opacity != 1) {
		return YES;
	}
	
	if (shadow_ && scale <= 3) {
		return YES;
	}
	
	if (self.blendOptions.mode != kCGBlendModeNormal) {
		return YES;
	}
	
	return NO;
}

- (BOOL) needsTransparencyLayer:(float)scale
{
	return [self needsToSaveGState:scale];
}

- (void) beginTransparencyLayer:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	if (![self needsToSaveGState:metaData.scale]) {
		return;
	}
	
	CGContextSaveGState(ctx);
/*
	[self.blendOptions prepareCGContext:ctx scale:metaData.scale];

	if (shadow_ && metaData.scale <= 3) {
		[shadow_ applyInContext:ctx metaData:metaData];
	}
*/
	if ([self needsTransparencyLayer:metaData.scale])
	{
		/*
			We need render bounds,
			otherwise shadow might become corrupted 
			during editing of lower elements.
		*/
//		CGContextBeginTransparencyLayer(ctx, NULL);
		CGRect B = CGContextGetClipBoundingBox(ctx);
		CGRect R = [self renderBounds];
		R = CGRectIntersection(R, B);
		CGContextBeginTransparencyLayerWithRect(ctx, R, NULL);
	}
}

- (void) endTransparencyLayer:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	if (![self needsToSaveGState:metaData.scale]) {
		return;
	}
	
	if ([self needsTransparencyLayer:metaData.scale]) {
		CGContextEndTransparencyLayer(ctx);
	}
	
	CGContextRestoreGState(ctx);
}

@end
