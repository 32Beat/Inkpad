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

#import "UIColor+Additions.h"
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


@synthesize layer = layer_;
@synthesize group = group_;
@synthesize opacity = opacity_;
@synthesize blendMode = blendMode_;
@synthesize shadow = shadow_;
@synthesize initialShadow = initialShadow_;

- (void)__encodeWithCoder:(NSCoder *)coder
{
	[coder encodeConditionalObject:layer_ forKey:WDLayerKey];
	
	if (group_) {
		[coder encodeConditionalObject:group_ forKey:WDGroupKey];
	}
	
	if (shadow_) {
		// If there's an initial shadow, we should save that. The user hasn't committed to the color shift yet.
		WDShadow *shadowToSave = initialShadow_ ? initialShadow_ : shadow_;
		[coder encodeObject:shadowToSave forKey:WDShadowKey];
	}
	
	if (opacity_ != 1.0f) {
		[coder encodeFloat:opacity_ forKey:WDObjectOpacityKey];
	}
	
	if (blendMode_ != kCGBlendModeNormal) {
		[coder encodeInt:blendMode_ forKey:WDBlendModeKey];
	}
}

- (id)__initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	layer_ = [coder decodeObjectForKey:WDLayerKey];
	group_ = [coder decodeObjectForKey:WDGroupKey];
	
	shadow_ = [coder decodeObjectForKey:WDShadowKey];
	
	if ([coder containsValueForKey:WDObjectOpacityKey]) {
		opacity_ = [coder decodeFloatForKey:WDObjectOpacityKey];
	} else {
		opacity_ = 1.0f;
	}
	
	blendMode_ = [coder decodeIntForKey:WDBlendModeKey] ?: kCGBlendModeNormal;
	
	return self; 
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	// Cleanup low level constructs
	[self flushCache];
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

- (BOOL) decodeWithCoder:(NSCoder *)coder
{
	[self decodeSizeWithCoder:coder];
	[self decodePositionWithCoder:coder];
	[self decodeRotationWithCoder:coder];

	return YES;
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

- (BOOL) decodeWithCoder0:(NSCoder *)coder
{
	// Decode blendStyleOptions without generating updates

	if ([coder containsValueForKey:WDBlendModeKey]||
		[coder containsValueForKey:WDObjectOpacityKey])
	{
		WDMutableBlendOptions *blendOptions = [WDMutableBlendOptions new];

		if ([coder containsValueForKey:WDBlendModeKey])
			[blendOptions setMode:
			[coder decodeIntForKey:WDBlendModeKey]];

		if ([coder containsValueForKey:WDObjectOpacityKey])
			[blendOptions setOpacity:
			[coder decodeFloatForKey:WDObjectOpacityKey]];

		[[self styleOptions] setStyleOptions:blendOptions];
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

			CGSize shadowOffset = {
				offset * cos(angle),
				offset * sin(angle) };

			WDShadowOptions *dstShadow = [WDShadowOptions new];
			[dstShadow setShadowColor:[color UIColor]];
			[dstShadow setShadowOffset:shadowOffset];
			[dstShadow setShadowBlur:radius];
			[[self styleOptions] setStyleOptions:dstShadow];
		}
	}

	return YES;
}

////////////////////////////////////////////////////////////////////////////////




- (id) init
{
	self = [super init];
	
	if (!self) {
		return nil;
	}

	opacity_ = 1.0f;
	
	return self;
}

- (void) awakeFromEncoding
{
}

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

- (WDShadow *) shadowForStyleBounds
{
	return self.shadow;
}



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
		[self cacheDirtyBounds];

		// Copy properties from srcElement
		[self takePropertiesFrom:srcElement];

		// Notify drawingcontroller
		[self postDirtyBoundsChange];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) takePropertiesFrom:(WDElement *)srcElement
{
	[self setSize:srcElement->mSize];
	[self setPosition:srcElement->mPosition];
	[self setRotation:srcElement->mRotation];
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
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Style Options
////////////////////////////////////////////////////////////////////////////////

- (WDStyleOptions *) styleOptions
{
	return mStyleOptions ? mStyleOptions :
	(mStyleOptions = [[WDStyleOptions alloc] initWithDelegate:self]);
}

////////////////////////////////////////////////////////////////////////////////

- (WDBlendOptions *) blendOptions
{ return [[self styleOptions] valueForKey:WDBlendOptionsKey]; }

- (void) setBlendOptions:(WDBlendOptions *)blendOptions
{
	if (mBlendOptions != blendOptions)
	{
		[mOwner element:self willChangeProperty:WDBlendOptionsKey];
		[[self styleOptions] setStyleOptions:blendOptions];
		[mOwner element:self didChangeProperty:WDBlendOptionsKey];

		mBlendOptions = blendOptions;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (WDShadowOptions *) shadowOptions
{ return [[self styleOptions] valueForKey:WDShadowOptionsKey]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setBlendOpacity:(CGFloat)opacity
{
	WDBlendOptions *blendOptions = [self blendOptions];
	if (blendOptions == nil)
	{ blendOptions = [WDBlendOptions new]; }
	[blendOptions setOpacity:opacity];
	[self setBlendOptions:blendOptions];
}

- (void) setBlendMode:(CGBlendMode)blendMode
{
	[mOwner element:self willChangeProperty:WDBlendModeKey];
	[[self blendOptions] setBlendMode:blendMode];
	[mOwner element:self didChangeProperty:WDBlendModeKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	if (context != nil)
	{
		[[self blendOptions] applyInContext:context];
		[[self shadowOptions] applyInContext:context];
	}
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

- (void) setTransform:(CGAffineTransform)T
{ [self setTransform:T sourceRect:[self sourceRect]]; }

- (void) setTransform:(CGAffineTransform)T sourceRect:(CGRect)sourceRect
{
	WDQuad F = WDQuadWithRect(sourceRect, T);
	CGPoint C = WDQuadGetCenter(F);

	[self setSize:(CGSize){
		0.5*(WDDistance(F.P[0], F.P[1])+WDDistance(F.P[2], F.P[3])),
		0.5*(WDDistance(F.P[0], F.P[3])+WDDistance(F.P[1], F.P[2]))}];
	[self setPosition:C];

	CGPoint P = WDAddPoints(F.P[1], F.P[2]);
	P = WDSubtractPoints(P, C);
	P = WDSubtractPoints(P, C);
	[self setRotation:WDDegreesFromRadians(atan2(P.y, P.x))];
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

	// Store update areas
	[self cacheDirtyBounds];

	[self setSize:WDScaleSize(mSize, d, d)];
	[self setRotation:mRotation + 180.0*da/M_PI];

	// Notify drawingcontroller
	[self postDirtyBoundsChange];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Bounds
////////////////////////////////////////////////////////////////////////////////

- (void) glDrawBoundsWithViewTransform:(CGAffineTransform)viewTransform
{
#ifdef WD_DEBUG
	glColor4f(0.0, 0.0, 1.0, .9);
	CGRect R = [self bounds];
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
#endif
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{ return [self sourceRect]; }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) styleBounds
{
	if (CGRectIsEmpty(mStyleBounds))
	{ mStyleBounds = [self computeStyleBounds]; }
	return mStyleBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeStyleBounds
{ return CGRectApplyAffineTransform([self sourceRect], [self sourceTransform]); }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) shadowBounds
{
	if (CGRectIsEmpty(mShadowBounds))
	{ mShadowBounds = [self computeShadowBounds]; }
	return mShadowBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeShadowBounds
{
	CGRect R = [self styleBounds];
	if (self.shadow != nil)
	{ R = [self.shadow expandRenderArea:R]; }
	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) renderBounds
{
	// Can not cache this, since we don't know changes in owners
	return [self computeRenderBounds];

	if (CGRectIsEmpty(mRenderBounds))
	{ mRenderBounds = [self computeRenderBounds]; }
	return mRenderBounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeRenderBounds
{
	CGRect R = [self shadowBounds];
	if (self.group != nil)
	{ R = [self.group expandRenderArea:R]; }
	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) expandRenderArea:(CGRect)R
{
	if (self.shadow)
	{ R = [self.shadow expandRenderArea:R]; }

	if (self.group)
	{ R = [self.group expandRenderArea:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (void) invalidateBounds
{
	[self invalidateStyleBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (void) invalidateStyleBounds
{
	mStyleBounds = CGRectNull;
	[self invalidateShadowBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (void) invalidateShadowBounds
{
	mShadowBounds = CGRectNull;
	mRenderBounds = CGRectNull;
}

////////////////////////////////////////////////////////////////////////////////

- (void) cacheDirtyBounds
{
	dirtyBounds_ = [self renderBounds];

	// We are appearantly going to affect bounds
	[self invalidateBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (void) postDirtyBoundsChange
{
	if (!self.drawing) {
		return;
	}

	// the layer should dirty its thumbnail
	[self.layer invalidateThumbnail];

	CGRect sourceArea = dirtyBounds_;
	CGRect resultArea = [self renderBounds];

	if (CGRectEqualToRect(sourceArea, resultArea))
	{
		NSDictionary *userInfo = @{@"rect":
		[NSValue valueWithCGRect:resultArea]};
		[[NSNotificationCenter defaultCenter]
		postNotificationName:WDElementChanged object:self.drawing userInfo:userInfo];
	}
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

- (NSSet *) transform:(CGAffineTransform)transform
{
	return nil;
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
		[self postDirtyBoundsChange];
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
	[self glDrawContentWithTransform:T];
	[self glDrawFrameWithTransform:T];

	if (options & eWDEditModeContent)
	{ [self glDrawContentControlsWithTransform:T]; }
	
	if (options & eWDEditModeFrame)
	{ [self glDrawFrameControlsWithTransform:T]; }

	if (options & eWDEditModeStyle)
	{ [self glDrawStyleControlsWithTransform:T]; }

	//[self glDrawBoundsWithViewTransform:T];
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
	[element setAttribute:@"opacity" floatValue:self.opacity];
	if (blendMode_ != kCGBlendModeNormal) {
		[element setAttribute:@"inkpad:blendMode" value:[[WDSVGHelper sharedSVGHelper] displayNameForBlendMode:self.blendMode]];;
	}
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

- (void) setOpacity:(float)opacity
{
	if (opacity == opacity_) {
		return;
	}
	
	[self cacheDirtyBounds];
	
	[[self.undoManager prepareWithInvocationTarget:self] setOpacity:opacity_];
	
	opacity_ = WDClamp(0, 1, opacity);

	[self postDirtyBoundsChange];
	[self propertyChanged:WDOpacityProperty];
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

	WDShadow *shadow = self.shadow;
	
	if ([property isEqualToString:WDOpacityProperty]) {
		self.opacity = [value floatValue];
	} else if ([property isEqualToString:WDBlendModeProperty]) {
		self.blendMode = [value intValue];
	} else if ([property isEqualToString:WDShadowVisibleProperty]) {
		if ([value boolValue] && !shadow) { // shadow enabled
			// shadow turned on and we don't have one so attach the default stroke
			self.shadow = [propertyManager defaultShadow];
		} else if (![value boolValue] && shadow) {
			self.shadow = nil;
		}
	} else if ([[NSSet setWithObjects:WDShadowColorProperty, WDShadowOffsetProperty, WDShadowRadiusProperty, WDShadowAngleProperty, nil] containsObject:property]) {
		if (!shadow) {
			shadow = [propertyManager defaultShadow];
		}
		
		if ([property isEqualToString:WDShadowColorProperty]) {
			self.shadow = [WDShadow shadowWithColor:value radius:shadow.radius offset:shadow.offset angle:shadow.angle];
		} else if ([property isEqualToString:WDShadowOffsetProperty]) {
			self.shadow = [WDShadow shadowWithColor:shadow.color radius:shadow.radius offset:[value floatValue] angle:shadow.angle];
		} else if ([property isEqualToString:WDShadowRadiusProperty]) {
			self.shadow = [WDShadow shadowWithColor:shadow.color radius:[value floatValue] offset:shadow.offset angle:shadow.angle];
		} else if ([property isEqualToString:WDShadowAngleProperty]) {
			self.shadow = [WDShadow shadowWithColor:shadow.color radius:shadow.radius offset:shadow.offset angle:[value floatValue]];
		}
	} 
}

- (id) valueForProperty:(NSString *)property
{
	if ([property isEqualToString:WDOpacityProperty]) {
		return @(opacity_);
	} else if ([property isEqualToString:WDBlendModeProperty]) {
		return @(blendMode_);
	} else if ([property isEqualToString:WDShadowVisibleProperty]) {
		return @((self.shadow) ? YES : NO);
	} else if (self.shadow) {
		if ([property isEqualToString:WDShadowColorProperty]) {
			return self.shadow.color;
		} else if ([property isEqualToString:WDShadowOffsetProperty]) {
			return @(self.shadow.offset);
		} else if ([property isEqualToString:WDShadowRadiusProperty]) {
			return @(self.shadow.radius);
		} else if ([property isEqualToString:WDShadowAngleProperty]) {
			return @(self.shadow.angle);
		}
	}
	
	return nil;
}

- (NSSet *) inspectableProperties
{
	return [NSSet setWithObjects:WDOpacityProperty, WDBlendModeProperty, WDShadowVisibleProperty,
			WDShadowColorProperty, WDShadowAngleProperty, WDShadowRadiusProperty, WDShadowOffsetProperty,
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
	if (opacity_ != 1) {
		return YES;
	}
	
	if (shadow_ && scale <= 3) {
		return YES;
	}
	
	if (blendMode_ != kCGBlendModeNormal) {
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
	
	if (opacity_ != 1) {
		CGContextSetAlpha(ctx, opacity_);
	}

	if (shadow_ && metaData.scale <= 3) {
		[shadow_ applyInContext:ctx metaData:metaData];
	}

	if (blendMode_ != kCGBlendModeNormal) {
		CGContextSetBlendMode(ctx, blendMode_);
	}
	
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

- (id) copyWithZone:(NSZone *)zone
{       
	WDElement *element = [[[self class] allocWithZone:zone] init];
	
	element->shadow_ = [shadow_ copy];
	element->opacity_ = opacity_;
	element->blendMode_ = blendMode_;
	
	return element;
}

@end
