//
//  WDImage.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#if !TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "NSCoderAdditions.h"
#endif

#import "UIColor_Additions.h"
#import "WDBezierSegment.h"
#import "WDColor.h"
#import "WDDrawing.h"
#import "WDGLUtilities.h"
#import "WDImage.h"
#import "WDImageData.h"
#import "WDLayer.h"
#import "WDPickResult.h"
#import "WDShadow.h"
#import "WDSVGHelper.h"
#import "WDUtilities.h"

NSString *WDImageDataKey = @"WDImageDataKey";

////////////////////////////////////////////////////////////////////////////////
@implementation WDImage
////////////////////////////////////////////////////////////////////////////////

@synthesize imageData = imageData_;

////////////////////////////////////////////////////////////////////////////////

+ (WDImage *) imageWithUIImage:(UIImage *)image inDrawing:(WDDrawing *)drawing
{
	return [[WDImage alloc] initWithUIImage:image inDrawing:drawing];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithUIImage:(UIImage *)image inDrawing:(WDDrawing *)drawing
{
	self = [super initWithSize:[image size]];
	if (self != nil)
	{
		imageData_ = [drawing imageDataForUIImage:image];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDImage *)src
{
	[super copyPropertiesFrom:src];
	self->imageData_ = [src->imageData_ copy];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:imageData_ forKey:WDImageDataKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	[super decodeWithCoder:coder];
	imageData_ = [coder decodeObjectForKey:WDImageDataKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder0:(NSCoder *)coder
{
	// Decode old blend and shadow
	[super decodeWithCoder0:coder];

	// Fetch imagedata
	imageData_ = [coder decodeObjectForKey:WDImageDataKey];

	// Apply transform
	if ([coder containsValueForKey:WDTransformKey])
	{
		CGAffineTransform T =
		[coder decodeCGAffineTransformForKey:WDTransformKey];

		// Convert transform to size, position, rotation
		[self setTransform:T sourceRect:imageData_.naturalBounds];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) useTrackedImageData
{
	if (self.layer.drawing) {
		// make sure our imagedata is registered with the document and not duplicated
		WDImageData *tracked = [self.layer.drawing trackedImageData:imageData_];
		if (tracked != imageData_) {
			imageData_ = tracked;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setLayer:(WDLayer *)layer
{
	[super setLayer:layer];
	[self useTrackedImageData];
}

////////////////////////////////////////////////////////////////////////////////

- (CGSize) sourceSize
{ return imageData_.image.size; }

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) computeSourceTransform
{
	CGAffineTransform T = [super computeSourceTransform];

	CGSize size = [self size];
	CGFloat sx = size.width / [self sourceSize].width;
	CGFloat sy = size.height / [self sourceSize].height;

	T = CGAffineTransformScale(T, sx, -sy);

	return T;
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) shadowScale
{
	// For unscaled shadow
//	return 1.0;

	CGSize size = [self size];
	CGFloat sx = size.width / [self sourceSize].width;
	CGFloat sy = size.height / [self sourceSize].height;
	return MAX(sx, sy);
}

////////////////////////////////////////////////////////////////////////////////

- (WDShadowOptions *)scaledShadowOptions
{
	return [[self shadowOptions] optionsWithScale:[self shadowScale]];
}

////////////////////////////////////////////////////////////////////////////////
/*
	Overwrite because we apply transform to style
	(default behavior doesn't currently apply transform to style)

	Transform is not applied to shadow which is scaled but not rotated
*/
- (CGRect) computeStyleBounds
{
	CGRect R = [self sourceRect];

	if (self.strokeOptions != nil)
	{ R = [self.strokeOptions resultAreaForRect:R]; }

	R = CGRectApplyAffineTransform(R, [self sourceTransform]);

	if (self.shadowOptions != nil)
	{ R = [self.scaledShadowOptions resultAreaForRect:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////
/*
	renderOutline will draw crossmarked rectangle by default, 
	so we only overwrite renderContent
*/

- (void) renderContent:(const WDRenderContext *)renderContext
{
	// Fetch CGContextRef
	CGContextRef ctx = renderContext->contextRef;
	// Shadow ignores the CTM, so needs separate scaling
	CGFloat scale = renderContext->contextScale*[self shadowScale];

	// Prepare context (may include transparencyLayer)
	[self prepareCGContext:ctx scale:scale];

	// Adjust CTM so everything scales according to frame scale
	CGContextConcatCTM(ctx, [self sourceTransform]);

	// Fetch appropriate image
	UIImage *image = (renderContext->flags & WDRenderThumbnail) ?
	imageData_.thumbnailImage : imageData_.image;

	// CTM is set, so destinationRect = sourceRect
	CGContextDrawImage(ctx, [self sourceRect], [image CGImage]);

	// Draw border if required
	if ([self strokeOptions].visible)
	{
		CGContextAddRect(ctx, [self sourceRect]);
		CGContextStrokePath(ctx);
	}

	// Restore context (may include endTransparencyLayer)
	[self restoreCGContext:ctx];
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	// Shadow ignores the CTM, so needs separate scaling
	CGFloat scale = metaData.scale*[self shadowScale];
	[self prepareCGContext:ctx scale:scale];

	// Adjust CTM so everything scales according to frame scale
	CGContextConcatCTM(ctx, [self sourceTransform]);

	// Fetch appropriate image
	UIImage *image = (metaData.flags & WDRenderThumbnail) ?
	imageData_.thumbnailImage : imageData_.image;

	// CTM is set, so destinationRect = sourceRect
	CGContextDrawImage(ctx, [self sourceRect], [image CGImage]);

	// Draw border if required
	if ([self strokeOptions].visible)
	{
		CGContextAddRect(ctx, [self sourceRect]);
		CGContextStrokePath(ctx);
	}

	[self restoreCGContext:ctx];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustTransform:(CGAffineTransform)T
{
	// Record current state for undo
	[self saveState];

	[self willChangePropertyForKey:WDFrameOptionsKey];

/*
	If we ever want to support numeric transformations,
	we need to limit our transforms to normal rotation, scale, and move.
	
	They currently are, attempt breaking it down.
*/
	// Test for rotation
	if ((T.b != 0.0)||(T.c != 0.0))
	{
		double a = WDGetRotationFromTransform(T);
		double degrees = WDDegreesFromRadians(a);
		[self setRotation:mRotation + degrees];
	}
	else
	// Test for scale
	if ((T.a != 1.0)||(T.d != 1.0))
	{
		CGSize size = mSize;
		CGSize scale = WDGetScaleFromTransform(T);
		size.width *= scale.width;
		size.height *= scale.height;
		[self setSize:size];
	}

	// Always move
	CGPoint P = mPosition;
	P = CGPointApplyAffineTransform(P, T);
	[self setPosition:P];

	[self didChangePropertyForKey:WDFrameOptionsKey];
}

////////////////////////////////////////////////////////////////////////////////


- (NSSet *) transform:(CGAffineTransform)transform
{
	[self adjustTransform:transform];
	return nil;
}

/*
- (WDPickResult *) hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
	WDPickResult        *result = [WDPickResult pickResult];
	CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
	
	if (!CGRectIntersectsRect(pointRect, [self bounds])) {
		return result;
	}
	
	if ((flags & kWDSnapNodes) || (flags & kWDSnapEdges)) {
		result = WDSnapToRectangle([self naturalBounds], &transform_, point, viewScale, flags);
		if (result.snapped) {
			result.element = self;
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
*/

- (WDPickResult *) snappedPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
	WDPickResult        *result = [WDPickResult pickResult];
	CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
	
	if (!CGRectIntersectsRect(pointRect, [self bounds])) {
		return result;
	}
	
	if ((flags & kWDSnapNodes) || (flags & kWDSnapEdges)) {
		result = WDSnapToRectangle([self sourceRect], &mTransform, point, viewScale, flags);
		if (result.snapped) {
			result.element = self;
			return result;
		}
	}
	
	return result;
}

- (id) pathPainterAtPoint:(CGPoint)pt
{
	if (!WDQuadContainsPoint([self frameQuad], pt)) {
		return nil;
	}

	CGAffineTransform transform = CGAffineTransformInvert(mTransform);
	pt = CGPointApplyAffineTransform(pt, transform);

	CGImageRef imageRef = imageData_.image.CGImage;
	CGImageRef tinyRef = CGImageCreateWithImageInRect(imageRef, CGRectMake(pt.x, pt.y, 1, 1));
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	UInt8 rawData[4] = {255, 255, 255, 255}; // draw over a white background
	CGContextRef context = CGBitmapContextCreate(rawData, 1, 1, 8, 4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), tinyRef);
	
	CGContextRelease(context);
	CGImageRelease(tinyRef);
	
	CGFloat red   = rawData[0] / 255.0f;
	CGFloat green = rawData[1] / 255.0f;
	CGFloat blue  = rawData[2] / 255.0f;
	
	return [WDColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

- (WDXMLElement *) SVGElement
{
	NSString *unique = [[WDSVGHelper sharedSVGHelper] imageIDForDigest:imageData_.digest];
	WDXMLElement *image = [WDXMLElement elementWithName:@"use"];
	
	[self addSVGOpacityAndShadowAttributes:image];
	
	[image setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", unique]];
	[image setAttribute:@"transform" value:WDSVGStringForCGAffineTransform([self sourceTransform])];
	
	return image;
}

- (BOOL) needsTransparencyLayer:(float)scale
{
	return NO;
}

@end
