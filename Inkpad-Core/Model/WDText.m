////////////////////////////////////////////////////////////////////////////////
/*
	WDText.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#if !TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "NSCoderAdditions.h"
#endif

#import <CoreText/CoreText.h>
#import "NSString+Additions.h"
#import "UIColor_Additions.h"
#import "WDBezierSegment.h"
#import "WDColor.h"
#import "WDDrawing.h"
#import "WDFillTransform.h"
#import "WDFontManager.h"
#import "WDGLUtilities.h"
#import "WDGradient.h"
#import "WDInspectableProperties.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDPropertyManager.h"
#import "WDSVGHelper.h"
#import "WDText.h"
#import "WDUtilities.h"

#define kMinWidth 20
#define kDiamondSize 7

NSString *WDWidthKey = @"WDWidthKey";
NSString *WDAlignmentKey = @"WDAlignmentKey";

@interface WDText (Private)
- (void) invalidate;
- (void) invalidatePreservingAttributedString:(BOOL)flag;
@end

////////////////////////////////////////////////////////////////////////////////
@implementation WDText
////////////////////////////////////////////////////////////////////////////////

@synthesize text = text_;

@synthesize fontName = fontName_;
@synthesize fontSize = fontSize_;
@synthesize transform = transform_;
@synthesize alignment = alignment_;
@synthesize attributedString;

////////////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
//	[coder encodeFloat:width_ forKey:WDWidthKey];
	[coder encodeCGAffineTransform:transform_ forKey:WDTransformKey];
	[coder encodeObject:text_ forKey:WDTextKey];
	[coder encodeObject:fontName_ forKey:WDFontNameKey];
	[coder encodeFloat:fontSize_ forKey:WDFontSizeKey];
	[coder encodeInt32:alignment_ forKey:WDAlignmentKey];
}

////////////////////////////////////////////////////////////////////////////////

// NSTextAlignmentToCTTextAlignment

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDTextKey])
	{ text_ = [coder decodeObjectForKey:WDTextKey]; }

	if ([coder containsValueForKey:WDAlignmentKey])
	{ alignment_ = [coder decodeInt32ForKey:WDAlignmentKey]; }

	if ([coder containsValueForKey:WDFontNameKey])
	{ fontName_ = [coder decodeObjectForKey:WDFontNameKey]; }

	if ([coder containsValueForKey:WDFontSizeKey])
	{ fontSize_ = [coder decodeFloatForKey:WDFontSizeKey]; }

	if (![[WDFontManager sharedInstance] validFont:fontName_])
	{ fontName_ = @"Helvetica"; }

	[super decodeWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder0:(NSCoder *)coder
{
	[super decodeWithCoder0:coder];

	if ([coder containsValueForKey:WDTextKey])
	{ text_ = [coder decodeObjectForKey:WDTextKey]; }

	if ([coder containsValueForKey:WDAlignmentKey])
	{ alignment_ = NSTextAlignmentToCTTextAlignment
		([coder decodeInt32ForKey:WDAlignmentKey]); }

	if ([coder containsValueForKey:WDFontNameKey])
	{ fontName_ = [coder decodeObjectForKey:WDFontNameKey]; }

	if ([coder containsValueForKey:WDFontSizeKey])
	{ fontSize_ = [coder decodeFloatForKey:WDFontSizeKey]; }

	if (![[WDFontManager sharedInstance] validFont:fontName_])
	{ fontName_ = @"Helvetica"; }

	if ([coder containsValueForKey:WDWidthKey])
	{ self.width = [coder decodeFloatForKey:WDWidthKey]; }

	if ([coder containsValueForKey:WDTransformKey])
	{
		transform_ = [coder decodeCGAffineTransformForKey:WDTransformKey];
//		[self setTransform:transform sourceRect:?];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDText *)srcText
{
	[super copyPropertiesFrom:srcText];

	self->text_ = srcText->text_;
//	self->width_ = srcText->width_;

	self->fontName_ = srcText->fontName_;
	self->fontSize_ = srcText->fontSize_;

	self->alignment_ = srcText->alignment_;
	self->transform_ = srcText->transform_;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setText:(NSString *)text
{
	if (![text_ isEqualToString:text])
	{
		[self willChangePropertyForKey:WDTextKey];
		text_ = text;
		[self flushCache];
		[self didChangePropertyForKey:WDTextKey];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) width
{ return self.size.width; }

- (void) setWidth:(CGFloat)width
{
	CGSize size = [self suggestedSizeForWidth:width];
	if (size.width < width)
	{ size.width = width; }
	[self setSize:size];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setAlignment:(CTTextAlignment)alignment
{
	if (alignment_ != alignment)
	{
		alignment_ = alignment;
		[self flushCache];
	}
}

////////////////////////////////////////////////////////////////////////////////


+ (float) minimumWidth
{
	return kMinWidth;
}

- (CTFontRef) fontRef
{
	if (fontRef_ == nil)
	{
		fontRef_ = [[WDFontManager sharedInstance]
		newFontRefForFont:fontName_ withSize:fontSize_ provideDefault:YES];
	}
	
	return fontRef_;
}

/*
- (CGRect) naturalBounds
{
	if (fontName_)
	{
		CGSize size = [self suggestedSize];
		CGFloat fontHeight = CTFontGetLeading(self.fontRef);
		CGFloat H = MAX(fontHeight, size.height + 1);

		naturalBounds_ = CGRectMake(-0.5*width_, -0.5*H, width_, H);
	}

	return naturalBounds_;
}
*/

- (CGSize) suggestedSize
{ return [self suggestedSizeForWidth:self.width]; }

- (CGSize) suggestedSizeForWidth:(CGFloat)width
{
	CTFramesetterRef framesetter =
	CTFramesetterCreateWithAttributedString((CFAttributedStringRef) self.attributedString);

	// compute size
	CFRange fitRange;
	CGSize suggestedSize =
	CTFramesetterSuggestFrameSizeWithConstraints
	(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(width, CGFLOAT_MAX), &fitRange);

	// clean up
	CFRelease(framesetter);

	return suggestedSize;
}

////////////////////////////////////////////////////////////////////////////////

- (CTFrameRef) createFrameSetterFrame
{
	CTFrameRef frameRef = nil;

	CGPathRef path = CGPathCreateWithRect(self.sourceRect, nil);
	if (path != nil)
	{
		frameRef = [self createFrameSetterFrameWithPath:path];

		CFRelease(path);
	}

	return frameRef;
}

////////////////////////////////////////////////////////////////////////////////

- (CTFrameRef) createFrameSetterFrameWithPath:(CGPathRef)path
{
	CTFrameRef frameRef = nil;

	CTFramesetterRef frameSetter =
	CTFramesetterCreateWithAttributedString
	((CFAttributedStringRef)self.attributedString);

	if (frameSetter != nil)
	{
		frameRef = CTFramesetterCreateFrame
		(frameSetter, CFRangeMake(0, 0), path, NULL);
		CFRelease(frameSetter);
	}

	return frameRef;
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushCache
{
	[super flushCache];

	if (mTextPath != nil)
	{ CGPathRelease(mTextPath); }
	mTextPath = nil;

	attributedString = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) textPath
{ return mTextPath ? mTextPath : (mTextPath = [self createTextPath]); }

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createTextPath
{
	CGMutablePathRef textPath = CGPathCreateMutable();

	CTFrameRef frame = [self createFrameSetterFrame];

	NSArray *lines = (NSArray *) CTFrameGetLines(frame);
	CGPoint origins[lines.count];
	CTFrameGetLineOrigins(frame, CFRangeMake(0, lines.count), origins);
	
	for (int i = 0; i < lines.count; i++)
	{
		CGPoint lineOrigin = {
			CGRectGetMinX(self.sourceRect) + origins[i].x,
			CGRectGetMaxY(self.sourceRect) - origins[i].y};

		CTLineRef lineRef = (__bridge CTLineRef) lines[i]; 
		NSArray *glyphRuns = (NSArray *) CTLineGetGlyphRuns(lineRef);
		
		for (int n = 0; n < glyphRuns.count; n++)
		{
			CTRunRef glyphRun = (__bridge CTRunRef) glyphRuns[n];
			CFIndex glyphCount = CTRunGetGlyphCount(glyphRun);
			
			CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(glyphRun), kCTFontAttributeName);
			
			CGGlyph glyphIndex[glyphCount];
			CGPoint glyphPosition[glyphCount];
			CTRunGetGlyphs(glyphRun, CFRangeMake(0, 0), glyphIndex);
			CTRunGetPositions(glyphRun, CFRangeMake(0,0), glyphPosition);
			
			for (int t = 0; t < glyphCount; t++)
			{
				CGPoint position = WDAddPoints(lineOrigin, glyphPosition[t]);
				
				CGAffineTransform tX =
				{ 1, 0, 0, -1, position.x, position.y };

				tX = CGAffineTransformConcat(tX, self.sourceTransform);

				CGPathRef glyphPath = CTFontCreatePathForGlyph(runFont, glyphIndex[t], &tX);
				if (glyphPath != nil)
				{
					CGPathAddPath(textPath, nil, glyphPath);

					CGPathRelease(glyphPath);
				}
			}
		}
	}
	
	CFRelease(frame);

	return textPath;
}

////////////////////////////////////////////////////////////////////////////////


- (void) layout
{
}






- (CGRect) computeStyleBounds
{
	return CGPathGetPathBoundingBox(self.textPath);
}

- (CGRect) controlBounds
{
	CGRect bbox = self.bounds;
	
	if (self.fillTransform) {
		bbox = WDGrowRectToPoint(bbox, self.fillTransform.transformedStart);
		bbox = WDGrowRectToPoint(bbox, self.fillTransform.transformedEnd);
	}
	
	return bbox;
}

- (CGMutablePathRef) pathRef
{
/*
	if (!pathRef_) {
		pathRef_ = CGPathCreateMutable();
		CGPathAddRect(pathRef_, &mTransform, self.naturalBounds);
	}
	
	return pathRef_;
*/
	return CGPathCreateMutableCopy(self.framePath);
}

- (void) dealloc
{
	if (pathRef_) {
		CGPathRelease(pathRef_);
		pathRef_ = NULL;
	}
	
	if (fontRef_) {
		CFRelease(fontRef_);
		fontRef_ = NULL;
	}
}

- (BOOL) containsPoint:(CGPoint)pt
{
	return CGPathContainsPoint(self.pathRef, NULL, pt, 0);
}


- (void) drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode
{
	[self drawTextInContext:ctx drawingMode:mode didClip:NULL];
}

- (void) drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode didClip:(BOOL *)didClip
{
	CGContextAddPath(ctx, self.textPath);
	CGContextStrokePath(ctx);
/*
	[self layout];

	for (id pathRef in glyphs_) {
		CGPathRef glyphPath = (__bridge CGPathRef) pathRef;
		
		if (mode == kCGTextStroke) {
			CGPathRef sansQuadratics = WDCreateCubicPathFromQuadraticPath(glyphPath);
			CGContextAddPath(ctx, sansQuadratics);
			CGPathRelease(sansQuadratics);
			
			// stroke each glyph immediately for better performance
			CGContextSaveGState(ctx);
			CGContextStrokePath(ctx);
			CGContextRestoreGState(ctx);
		} else {
			CGContextAddPath(ctx, glyphPath);
		}
	}

	if (mode == kCGTextClip && !CGContextIsPathEmpty(ctx)) {
		if (didClip) {
			*didClip = YES; 
		}
		CGContextClip(ctx);
	}

	if (mode == kCGTextFill) {
		CGContextFillPath(ctx);
	}
*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderOutline:(const WDRenderContext *)renderContext
{
	CGContextRef ctx = renderContext->contextRef;

	CGContextAddPath(ctx, self.pathRef);
	CGContextStrokePath(ctx);

	CGContextAddPath(ctx, self.textPath);
	CGContextStrokePath(ctx);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) resultPath
{ return self.textPath; }



- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	UIGraphicsPushContext(ctx);
	
	if (metaData.flags & WDRenderOutline) {
		CGContextAddPath(ctx, self.pathRef);
		CGContextStrokePath(ctx);
		
		[self drawTextInContext:ctx drawingMode:kCGTextFill];
	} else if ([self.strokeStyle willRender] || self.fill || self.maskedElements) {
		[self beginTransparencyLayer:ctx];
		
		if (self.fill) {
			CGContextSaveGState(ctx);
			[self.fill paintText:self inContext:ctx];
			CGContextRestoreGState(ctx);
		}
		
		if (self.maskedElements) {
			BOOL didClip = NO;
			
			CGContextSaveGState(ctx);
			// clip to the mask boundary
			[self drawTextInContext:ctx drawingMode:kCGTextClip didClip:&didClip];
			
			if (didClip) {
				// draw all the elements inside the mask
				for (WDElement *element in self.maskedElements) {
					[element renderInContext:ctx metaData:metaData];
				}
			}
			
			CGContextRestoreGState(ctx);
		}
		
		if ([self.strokeStyle willRender]) {
			[self.strokeStyle applyInContext:ctx];
			[self drawTextInContext:ctx drawingMode:kCGTextStroke];
		}
		
		[self endTransparencyLayer:ctx];
	}
	
	UIGraphicsPopContext();
}

- (BOOL) hasEditableText
{
	return YES;
}

/*
	We could possibly do without canEditText...
*/
- (BOOL) canEditContent
{ return YES; }



- (void) cacheOriginalText
{
	cachedText_ = [self.text copy];
}

- (void) registerUndoWithCachedText
{
	if ([cachedText_ isEqualToString:text_]) {
		return;
	}
	
	[[self.undoManager prepareWithInvocationTarget:self] setText:cachedText_];
	cachedText_ = nil;
}

- (void) cacheTransformAndWidth
{
	[self cacheDirtyBounds];
	cachedTransform_ = transform_;
	//cachedWidth_ = width_;
	
	cachingWidth_ = YES;
}

- (void) registerUndoWithCachedTransformAndWidth
{
	[(WDText *)[self.undoManager prepareWithInvocationTarget:self] setTransform:cachedTransform_];
	[(WDText *)[self.undoManager prepareWithInvocationTarget:self] setWidth:cachedWidth_];
	
	[self postDirtyBoundsChange];
	
	cachingWidth_ = NO;
}



- (void) setFontNameQuiet:(NSString *)fontName
{
	fontName_ = fontName;
	
	if (fontRef_) {
		CFRelease(fontRef_);
		fontRef_ = NULL;
	}
}

- (void) setFontName:(NSString *)fontName
{
	[self cacheDirtyBounds];
	
	[[self.undoManager prepareWithInvocationTarget:self] setFontName:fontName_];

	[self setFontNameQuiet:fontName];
	
	[self invalidate];
	
	[self propertiesChanged:[NSSet setWithObjects:WDFontNameProperty, nil]];
}

- (void) setFontSizeQuiet:(float)size
{
	fontSize_ = size;
	
	if (fontRef_) {
		CFRelease(fontRef_);
		fontRef_ = NULL;
	}
}

- (void) setFontSize:(float)size
{
	[self cacheDirtyBounds];
	
	[(WDText *)[self.undoManager prepareWithInvocationTarget:self] setFontSize:fontSize_];

	[self setFontSizeQuiet:size];
	
	[self invalidate];
	
	[self propertiesChanged:[NSSet setWithObjects:WDFontSizeProperty, nil]];
}


- (NSSet *) inspectableProperties
{
	static NSMutableSet *inspectableProperties = nil;
	
	if (!inspectableProperties) {
		inspectableProperties = [NSMutableSet setWithObjects:WDFontNameProperty, WDFontSizeProperty, WDTextAlignmentProperty, nil];
		[inspectableProperties unionSet:[super inspectableProperties]];
	}
	
	return inspectableProperties;
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager 
{
	if (![[self inspectableProperties] containsObject:property]) {
		// we don't care about this property, let's bail
		return [super setValue:value forProperty:property propertyManager:propertyManager];
	}
	
	if ([property isEqualToString:WDFontNameProperty]) {
		[self setFontName:value];
	} else if ([property isEqualToString:WDFontSizeProperty]) {
		[self setFontSize:[value intValue]];
	} else if ([property isEqualToString:WDTextAlignmentProperty]) {
		[self setAlignment:[value intValue]];
	} else {
		[super setValue:value forProperty:property propertyManager:propertyManager];
	}
}

- (id) valueForProperty:(NSString *)property
{
	if (![[self inspectableProperties] containsObject:property]) {
		// we don't care about this property, let's bail
		return [super valueForProperty:property];
	}
	
	if ([property isEqualToString:WDFontNameProperty]) {
		return fontName_;
	} else if ([property isEqualToString:WDFontSizeProperty]) {
		return @(fontSize_);
	} else if ([property isEqualToString:WDTextAlignmentProperty]) {
		return @(alignment_);
	} else {
		return [super valueForProperty:property];
	}
	
	return nil;
}

- (void) setTransform:(CGAffineTransform)transform
{
	transform_ = transform;
}


- (NSSet *) transform:(CGAffineTransform)transform
{
	[super transform:transform];
	self.transform = CGAffineTransformConcat(transform_, transform);
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) frameControlPointAtIndex:(NSInteger)n
{
	WDQuad Q = [self frameQuad];

	if (n == 0)
	{ return WDCenterOfLine(Q.P[3],Q.P[0]); }
	if (n == 1)
	{ return WDCenterOfLine(Q.P[1],Q.P[2]); }

	return (CGPoint){ INFINITY, INFINITY };
}

////////////////////////////////////////////////////////////////////////////////

- (id) frameControlWithIndex:(NSInteger)n
{
	WDQuad Q = [self frameQuad];

	if (n == 0)
	{ return [NSValue valueWithCGPoint:WDCenterOfLine(Q.P[3],Q.P[0])]; }
	if (n == 1)
	{ return [NSValue valueWithCGPoint:WDCenterOfLine(Q.P[1],Q.P[2])]; }

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)delta
{
	CGPoint P0 = [self frameControlPointAtIndex:n];
	CGPoint P1 = WDAddPoints(P0, delta);

	CGPoint C = self.position;
	CGPoint D0 = WDSubtractPoints(P0,C);
	CGPoint D1 = WDSubtractPoints(P1,C);

	CGFloat a0 = atan2(D0.y, D0.x);
	CGFloat a1 = atan2(D1.y, D1.x);
	CGFloat da = a1 - a0;

	[self willChangePropertyForKey:WDFrameOptionsKey];

	[self setWidth:2*WDDistance(P1, C)];
	[self _applyRotation:180.0*da/M_PI];

	[self didChangePropertyForKey:WDFrameOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////

/*
- (void) adjustFrameControlWithIndex:(NSInteger)n delta:(CGPoint)d
{
	CGPoint P0 = [self frameControlPointAtIndex:n];
	CGPoint P1 = WDAddPoints(P0, d);
	CGPoint C = [self frameCenter];

	CGPoint d0 = WDSubtractPoints(P0,C);
	CGPoint d1 = WDSubtractPoints(P1,C);

	CGFloat a0 = atan2(d0.y, d0.x);
	CGFloat a1 = atan2(d1.y, d1.x);
	CGFloat da = a1-a0;

	CGAffineTransform T = transform_;
	T = CGAffineTransformConcat(T, CGAffineTransformMakeTranslation(-C.x, -C.y));
	T = CGAffineTransformConcat(T, CGAffineTransformMakeRotation(da));
	T = CGAffineTransformConcat(T, CGAffineTransformMakeTranslation(+C.x, +C.y));

	[self setTransform:T];

	CGFloat D = WDDistance(P1, C);
	[self setWidth:2*D];
}
*/
////////////////////////////////////////////////////////////////////////////////

- (void) glDrawFrameControlsWithTransform:(CGAffineTransform)T
{
	WDQuad Q = [self frameQuad];

	CGPoint P0 = WDCenterOfLine(Q.P[3],Q.P[0]);
	CGPoint P1 = WDCenterOfLine(Q.P[1],Q.P[2]);

	P0 = CGPointApplyAffineTransform(P0, T);
	P1 = CGPointApplyAffineTransform(P1, T);

	WDGLFillCircleMarker(P0);
	WDGLFillCircleMarker(P1);
}

////////////////////////////////////////////////////////////////////////////////

- (void) glDrawContentWithTransform:(CGAffineTransform)T
{
	WDGLRenderCGPathRef(self.textPath, &T);
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawOpenGLTextOutlinesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
}


- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
	if (CGRectIntersectsRect(self.bounds, visibleRect)) {
		[self drawOpenGLHighlightWithTransform:CGAffineTransformIdentity viewTransform:viewTransform];
		[self drawOpenGLTextOutlinesWithTransform:CGAffineTransformIdentity viewTransform:viewTransform];
	}
}

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
	CGAffineTransform   tX;
	CGPoint             ul, ur, lr, ll;
	CGRect              naturalBounds = self.naturalBounds;
	
	tX = CGAffineTransformConcat(transform_, transform);
	tX = CGAffineTransformConcat(tX, viewTransform);
	
	ul = CGPointZero;
	ur = CGPointMake(CGRectGetWidth(naturalBounds), 0);
	lr = CGPointMake(CGRectGetWidth(naturalBounds), CGRectGetHeight(naturalBounds));
	ll = CGPointMake(0, CGRectGetHeight(naturalBounds));
	
	ul = CGPointApplyAffineTransform(ul, tX);
	ur = CGPointApplyAffineTransform(ur, tX);
	lr = CGPointApplyAffineTransform(lr, tX);
	ll = CGPointApplyAffineTransform(ll, tX);
	
	// draw outline
	[self.layer.highlightColor glSet];
	
	WDGLStrokeLine(ul, ur);
	WDGLStrokeLine(ur, lr);
	WDGLStrokeLine(lr, ll);
	WDGLStrokeLine(ll, ul);
	
	if (!CGAffineTransformIsIdentity(transform) || cachingWidth_) {
		[self drawOpenGLTextOutlinesWithTransform:transform viewTransform:viewTransform];
	}
}

- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
	CGPoint left, right;
	
	left = CGPointMake(0, CGRectGetHeight(self.naturalBounds) / 2);
	right = CGPointMake(self.width, CGRectGetHeight(self.naturalBounds) / 2);
	
	left = CGPointApplyAffineTransform(left, transform_);
	right = CGPointApplyAffineTransform(right, transform_);
	
	[self drawOpenGLAnchorAtPoint:left transform:transform selected:YES];
	[self drawOpenGLAnchorAtPoint:right transform:transform selected:YES];
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
	CGPoint left, right;
	
	left = CGPointMake(0, CGRectGetHeight(self.naturalBounds) / 2);
	right = CGPointMake(self.width, CGRectGetHeight(self.naturalBounds) / 2);
	
	left = CGPointApplyAffineTransform(left, transform_);
	right = CGPointApplyAffineTransform(right, transform_);
	
	[self drawOpenGLAnchorAtPoint:left transform:viewTransform selected:NO];
	[self drawOpenGLAnchorAtPoint:right transform:viewTransform selected:NO];
}

- (WDPickResult *) snapEdges:(CGPoint)point viewScale:(float)viewScale
{
	WDPickResult        *result = [WDPickResult pickResult];
	WDBezierSegment     segment;
	CGPoint             corner[4];
	CGPoint             nearest;
	CGRect              naturalBounds = self.naturalBounds;
	
	corner[0] = CGPointZero;
	corner[1] = CGPointMake(CGRectGetWidth(naturalBounds), 0);
	corner[2] = CGPointMake(CGRectGetWidth(naturalBounds), CGRectGetHeight(naturalBounds));
	corner[3] = CGPointMake(0, CGRectGetHeight(naturalBounds));

	for (int i = 0; i < 4; i++) {
		segment.a_ = segment.out_ = CGPointApplyAffineTransform(corner[i], transform_);
		segment.b_ = segment.in_ = CGPointApplyAffineTransform(corner[(i+1) % 4], transform_);
		
		if (WDBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
			result.element = self;
			result.type = kWDEdge;
			result.snappedPoint = nearest;
			
			return result;
		}
	}
	
	return result;
}

- (WDPickResult *) hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
	WDPickResult        *result = [WDPickResult pickResult];
	CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
	float               distance, minDistance = MAXFLOAT;
	float               tolerance = kNodeSelectionTolerance / viewScale;
	
	if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
		return result;
	}
	
	if (flags & kWDSnapNodes) {
		CGPoint left, right;
		
		// check gradient control handles first (if any)
		distance = WDDistance([self.fillTransform transformedStart], point);
		if (distance < MIN(tolerance, minDistance)) {
			result.type = kWDFillStartPoint;
			minDistance = distance;
		}
		
		distance = WDDistance([self.fillTransform transformedEnd], point);
		if (distance < MIN(tolerance, minDistance)) {
			result.type = kWDFillEndPoint;
			minDistance = distance;
		}
			
		
		left = CGPointMake(0, CGRectGetHeight(self.naturalBounds) / 2);
		right = CGPointMake(self.width, CGRectGetHeight(self.naturalBounds) / 2);
		
		left = CGPointApplyAffineTransform(left, transform_);
		right = CGPointApplyAffineTransform(right, transform_);
		
		
		distance = WDDistance(left, point);
		if (distance < MIN(tolerance, minDistance)) {
			result.element = self;
			result.type = kWDLeftTextKnob;
		}
		
		distance = WDDistance(right, point);
		if (distance < MIN(tolerance, minDistance)) {
			result.element = self;
			result.type = kWDRightTextKnob;
		}
		
		if (result.type != kWDEther) {
			result.element = self;
			return result;
		}
	}
	
	if (flags & kWDSnapEdges) {
		result = [self snapEdges:point viewScale:viewScale];
		
		if (result.snapped) {
			return result;
		}
	}
	
	if (flags & kWDSnapFills) {
		if (CGPathContainsPoint(self.pathRef, NULL, point, true)) {
			result.element = self;
			result.type = kWDObjectFill;
			return result;
		}
	}
	
	return result;
}

- (void) moveHandle:(NSUInteger)handle toPoint:(CGPoint)pt
{
	CGPoint             left = CGPointMake(0, CGRectGetHeight(self.naturalBounds) / 2);
	CGPoint             right = CGPointMake(self.width, CGRectGetHeight(self.naturalBounds) / 2);
	CGAffineTransform   invert = CGAffineTransformInvert(transform_);
	CGPoint             mappedPoint = CGPointApplyAffineTransform(pt, invert);
	BOOL                accepted = NO;
	float               newWidth;
	
	if (handle == kWDRightTextKnob) {
		newWidth = mappedPoint.x - left.x;
		if (newWidth >= kMinWidth) {
			self.width = newWidth;
			accepted = YES;
		}
	} else if (handle == kWDLeftTextKnob) {
		newWidth = right.x - mappedPoint.x;
		
		if (newWidth >= kMinWidth) {
			CGAffineTransform shift = CGAffineTransformMakeTranslation(self.width - newWidth, 0);
			transform_ = CGAffineTransformConcat(shift, transform_);
			self.width = newWidth;
			accepted = YES;
		}
	}
	
	if (accepted) {
		attributedString = nil;
		
		CGPathRelease(pathRef_);
		pathRef_ = NULL;
	}
}

- (NSAttributedString *) attributedString
{
	if (!text_ || !fontName_) {
		return nil;
	}
	
	if (!attributedString) {
		CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
		
		CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), (CFStringRef)text_);    
		CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)text_)), kCTFontAttributeName, [self fontRef]);
		
		// paint with the foreground color
		CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)text_)), kCTForegroundColorFromContextAttributeName, kCFBooleanTrue);
		
		CTTextAlignment alignment;
		
		switch (alignment_) {
			case NSTextAlignmentLeft: alignment = kCTLeftTextAlignment; break;
			case NSTextAlignmentRight: alignment = kCTRightTextAlignment; break;
			case NSTextAlignmentCenter: alignment = kCTCenterTextAlignment; break;
			default: alignment = kCTLeftTextAlignment; break;
		}
		
		CTParagraphStyleSetting settings[] = {
			{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment}
		};
		CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(settings[0]));
		CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)attrString)), kCTParagraphStyleAttributeName, paragraphStyle);    
		CFRelease(paragraphStyle);
		
		attributedString = (NSAttributedString *) CFBridgingRelease(attrString);
	}
	
	return attributedString;
}

- (void) addSVGFillAttributes:(WDXMLElement *)element
{
	if ([self.fill isKindOfClass:[WDGradient class]]) {
		WDGradient *gradient = (WDGradient *)self.fill;
		NSString *uniqueID = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:(gradient.type == kWDRadialGradient ? @"RadialGradient" : @"LinearGradient")];
		
		WDFillTransform *fillTransform = [self.fillTransform transform:CGAffineTransformInvert(self.transform)];
		[[WDSVGHelper sharedSVGHelper] addDefinition:[gradient SVGElementWithID:uniqueID fillTransform:fillTransform]];
		
		[element setAttribute:@"fill" value:[NSString stringWithFormat:@"url(#%@)", uniqueID]];
	} else {
		[super addSVGFillAttributes:element];
	}
}

- (void) appendTextSVG:(WDXMLElement *)text
{
	/* generate the path for the text */
	CGMutablePathRef path = CGPathCreateMutable();
	CGRect bounds = self.naturalBounds;
	CGPathAddRect(path, NULL, bounds);
	
	/* draw the text */
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) self.attributedString);
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
	CFRelease(framesetter);
	CFRelease(path);
	
	NSArray *lines = (NSArray *) CTFrameGetLines(frame);
	CGPoint origins[lines.count];
	CTFrameGetLineOrigins(frame, CFRangeMake(0, lines.count), origins);
	
	for (int i = 0; i < lines.count; i++) {
		CTLineRef lineRef = (__bridge CTLineRef) lines[i]; 
		CGFloat lineWidth = CTLineGetTypographicBounds(lineRef, NULL, NULL, NULL);
		
		CFRange range = CTLineGetStringRange(lineRef);
		NSString *substring = [[text_ substringWithRange:NSMakeRange(range.location, range.length)] stringByEscapingEntities];
		
		WDXMLElement *tspan = [WDXMLElement elementWithName:@"tspan"];
		switch (alignment_) {
			case NSTextAlignmentLeft:
				[tspan setAttribute:@"x" floatValue:origins[i].x];
				break;
			case NSTextAlignmentCenter:
				[tspan setAttribute:@"x" floatValue:origins[i].x + lineWidth / 2.f];
				break;
			case NSTextAlignmentRight:
				[tspan setAttribute:@"x" floatValue:origins[i].x + lineWidth];
				break;
			default:
				[tspan setAttribute:@"x" floatValue:origins[i].x];
				break;
				
		}
		[tspan setAttribute:@"y" floatValue:CGRectGetHeight(bounds) - origins[i].y];
		[tspan setAttribute:@"textLength" floatValue:lineWidth];
		[tspan setValue:substring];
		[text addChild:tspan];
	}
	
	CFRelease(frame);
}

- (WDXMLElement *) SVGElement
{
	WDXMLElement *text = [WDXMLElement elementWithName:@"text"];
	[self appendTextSVG:text];
	
	[self addSVGFillAndStrokeAttributes:text];
	[self addSVGOpacityAndShadowAttributes:text];                
	[text setAttribute:@"transform" value:WDSVGStringForCGAffineTransform(transform_)];
	[text setAttribute:@"font-family" value:[NSString stringWithFormat:@"'%@'", fontName_]];
	[text setAttribute:@"font-size" floatValue:fontSize_];
	switch (alignment_) {
		case NSTextAlignmentLeft:
			[text setAttribute:@"text-anchor" value:@"start"];
			break;
		case NSTextAlignmentCenter:
			[text setAttribute:@"text-anchor" value:@"middle"];
			break;
		case NSTextAlignmentRight:
			[text setAttribute:@"text-anchor" value:@"end"];
			break;
		default:
			[text setAttribute:@"text-anchor" value:@"start"];
			break;
	}
	[text setAttribute:@"x" floatValue:self.naturalBounds.origin.x];
	[text setAttribute:@"y" floatValue:self.naturalBounds.origin.y];

	[text setAttribute:@"inkpad:text" value:[self.text stringByEscapingEntitiesAndWhitespace]];
	
	if (self.maskedElements && [self.maskedElements count] > 0) {
		// Produces an element such as:
		// <defs>
		//   <text id="TextN"><tspan>...</tspan></text>
		// </defs>
		// <g opacity="..." inkpad:shadowColor="..." inkpad:mask="#TextN">
		//   <use xlink:href="#TextN" fill="..."/>
		//   <clipPath id="ClipPathN">
		//     <use xlink:href="#TextN" overflow="visible"/>
		//   </clipPath>
		//   <g clip-path="url(#ClipPathN)">
		//     <!-- clipped elements -->
		//   </g>
		//   <use xlink:href="#TextN" stroke="..."/>
		// </g>
		NSString        *uniqueMask = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"Text"];
		NSString        *uniqueClip = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"ClipPath"];
		
		[text setAttribute:@"id" value:uniqueMask];
		[[WDSVGHelper sharedSVGHelper] addDefinition:text];
		
		WDXMLElement *group = [WDXMLElement elementWithName:@"g"];
		[group setAttribute:@"inkpad:mask" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
		[self addSVGOpacityAndShadowAttributes:group];
		
		if (self.fill) {
			// add a path for the fill
			WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
			[use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
			[self addSVGFillAttributes:use];
			[group addChild:use];
		}
		
		WDXMLElement *clipPath = [WDXMLElement elementWithName:@"clipPath"];
		[clipPath setAttribute:@"id" value:uniqueClip];
		
		WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
		[use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
		[use setAttribute:@"overflow" value:@"visible"];
		[clipPath addChild:use];
		[group addChild:clipPath];
		
		WDXMLElement *elements = [WDXMLElement elementWithName:@"g"];
		[elements setAttribute:@"clip-path" value:[NSString stringWithFormat:@"url(#%@)", uniqueClip]];
		
		for (WDElement *element in self.maskedElements) {
			[elements addChild:[element SVGElement]];
		}
		[group addChild:elements];
		
		if (self.strokeStyle) {
			// add a path for the stroke
			WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
			[use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
			[use setAttribute:@"fill" value:@"none"];
			[self.strokeStyle addSVGAttributes:use];
			[group addChild:use];
		}
		
		return group;
	} else {
		return text;
	}
}

- (NSArray *) outlines
{
	NSMutableArray *paths = [NSMutableArray array];
	
	[self layout];
	
	for (id pathRef in glyphs_) {
		CGPathRef glyphPath = (__bridge CGPathRef) pathRef;
		[paths addObject:[WDAbstractPath pathWithCGPathRef:glyphPath]];
	}
	
	return paths;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




