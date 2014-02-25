//
//  WDScaleTool.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDScaleTool.h"
#import "WDUtilities.h"

#define INVERTED_CONSTRAIN YES

@implementation WDScaleTool

- (NSString *) iconName
{
	return @"scale.png";
}

- (CGAffineTransform) computeTransform:(CGPoint)pt pivot:(CGPoint)pivot constrain:(WDToolFlags)flags
{
	BOOL constrain =
	((flags & WDToolShiftKey) || (flags & WDToolSecondaryTouch)) ? YES : NO;
	
	if (INVERTED_CONSTRAIN)\
	{ constrain = !constrain; }

//	if (contrain == YES)
	{
		CGFloat srcD = WDDistance(pivot, self.initialEvent.location);
		CGFloat dstD = WDDistance(pivot, pt);
		if ((srcD != 0.0) && (dstD != 0.0))
		{
			CGFloat s = dstD / srcD;
			CGAffineTransform T = CGAffineTransformIdentity;
			T = CGAffineTransformTranslate(T, +pivot.x, +pivot.y);
			T = CGAffineTransformScale(T, s, s);
			T = CGAffineTransformTranslate(T, -pivot.x, -pivot.y);
			return T;
		}
	}

/*
	TODO: decide on resizing strategy
	currently scaling is converted to resize, but object may be rotated...
	also flipping currently f*cks up Shape rebuilding
*/

	return CGAffineTransformIdentity;
}

@end
