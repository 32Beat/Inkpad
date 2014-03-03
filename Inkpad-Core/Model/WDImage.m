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
/*
	isVisible
	---------
	Overwrite since image visibility depends solely on blendOptions
*/

- (BOOL) isVisible
{ return self.blendOptions.visible; }

////////////////////////////////////////////////////////////////////////////////
/*
	renderFill
	----------
	Overwrite to render image over background fill.
	All properties remain in effect. This means the image will be
	blended into the background fill and the strokeoptions will be 
	rendered as frame.
*/

- (void) renderFill:(const WDRenderContext *)renderContext
{
	// Allow super to draw background
	[super renderFill:renderContext];

	// Blit image over background
	[self drawImage:renderContext];
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawImage:(const WDRenderContext *)renderContext
{
	// Fetch appropriate image
	UIImage *image = (renderContext->flags & WDRenderThumbnail) ?
	imageData_.thumbnailImage : imageData_.image;

	CGContextRef contextRef = renderContext->contextRef;
	
	CGContextSaveGState(contextRef);

	// Let CTM solve position, rotation
	CGContextConcatCTM(contextRef, self.sourceTransform);
	// DrawImage requires CoreGraphics coordinates
	CGContextScaleCTM(contextRef, 1, -1);

	// Let DrawImage solve scale
	CGSize dstSize = self.size;
	CGRect dstRect = { { -0.5*dstSize.width, -0.5*dstSize.height}, dstSize };
	CGContextDrawImage(contextRef, dstRect, image.CGImage);

	CGContextRestoreGState(contextRef);
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
}

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




