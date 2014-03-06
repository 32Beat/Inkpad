//
//  UIImage+Additions.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIImage+Additions.h"
#import "WDUtilities.h"
#import "UIImage+Resize.h"

@implementation UIImage (WDAdditions)

+ (UIImage *) checkerBoardPattern
{
	static UIImage *gPattern = nil;
	if (gPattern == nil)
	{ gPattern = [self _checkerBoardPattern]; }
	return gPattern;
}

+ (UIImage *) _checkerBoardPattern
{
	CGRect R = { 0.0, 0.0, 16.0, 16.0 };
	UIGraphicsBeginImageContext(R.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	UIColor *lightColor =
	[UIColor colorWithWhite:0.9 alpha:1.0];

	CGContextSetFillColorWithColor(ctx, lightColor.CGColor);
	CGContextFillRect(ctx, R);

	UIColor *darkColor =
	[UIColor colorWithWhite:0.7 alpha:1.0];

	CGContextSetFillColorWithColor(ctx, darkColor.CGColor);
	R.size.width *= 0.5;
	R.size.height *= 0.5;
	CGContextFillRect(ctx, R);
	R.origin.x += R.size.width;
	R.origin.y += R.size.height;
	CGContextFillRect(ctx, R);

	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}


- (void) drawToFillRect:(CGRect)bounds
{
	float   wScale = CGRectGetWidth(bounds) / self.size.width;
	float   hScale = CGRectGetHeight(bounds) / self.size.height;
	float   scale = MAX(wScale, hScale);
	float   hOffset = 0.0f, vOffset = 0.0f;
	
	CGRect  rect = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), self.size.width * scale, self.size.height * scale);
	
	if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
		hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
		hOffset /= -2;
	} 
	
	if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
		vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
		vOffset /= -2;
	}
	
	rect = CGRectOffset(rect, hOffset, vOffset);
	
	[self drawInRect:rect];
}

- (UIImage *) rotatedImage:(int)rotation
{
	CGSize size = self.size;
	CGSize rotatedSize = (rotation % 2 == 1) ? CGSizeMake(size.height, size.width) : size;
	
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (rotation == 1) {
		CGContextTranslateCTM(ctx, size.height, 0.0f);
	} else if (rotation == 2) {
		CGContextTranslateCTM(ctx, size.width, size.height);
	} else if (rotation == 3) {
		CGContextTranslateCTM(ctx, 0.0f, size.width);
	}
	
	CGContextRotateCTM(ctx, (M_PI / 2.0f) * rotation);
	
	[self drawAtPoint:CGPointZero];
	
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}

- (UIImage *) downsampleWithMaxDimension:(float)constraint
{
	CGSize newSize, size = self.size;
	
	if (size.width <= constraint &&
		size.height <= constraint &&
		self.imageOrientation == UIImageOrientationUp)
		{ return self; }
	
	if (size.width > size.height) {
		newSize.height = size.height / size.width * constraint;
		newSize.width = constraint;
	} else {
		newSize.width = size.width / size.height * constraint;
		newSize.height = constraint;
	}
	
	newSize = WDRoundSize(newSize);

	return [self resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
}

- (UIImage *) JPEGify:(float)compressionFactor
{
	NSData * jpegData = UIImageJPEGRepresentation(self, compressionFactor);
	return [UIImage imageWithData:jpegData];
}

@end
