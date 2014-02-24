//
//  WDShadowWell.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDShadowWell.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDShadowWell
////////////////////////////////////////////////////////////////////////////////

- (void) setBlendOptions:(WDBlendOptions *)options
{
	if (_blendOptions != options)
	{
		_blendOptions = options;
		[self setNeedsDisplay];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setShadowOptions:(WDShadowOptions *)options
{
	if (_shadowOptions != options)
	{
		_shadowOptions = options;
		[self setNeedsDisplay];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(CGRect)rect
{
	CGContextRef    ctx = UIGraphicsGetCurrentContext();
	CGRect          bounds = [self bounds];
	
	if (_barButtonItem) {
		int inset = ceil((CGRectGetHeight(bounds) - CGRectGetWidth(bounds)) / 2);
		bounds = CGRectInset(bounds, 0, inset);
	}
	
	WDDrawCheckersInRect(ctx, bounds, 7);
	
	CGContextSaveGState(ctx);

	if (_blendOptions != nil)
	{ CGContextSetAlpha(ctx, _blendOptions.opacity); }
	
	if (_shadowOptions.visible)
	{
		float x = cos(_shadowOptions.angle) * 3;
		float y = sin(_shadowOptions.angle) * 3;
		
		CGContextSetShadowWithColor(ctx, CGSizeMake(x,y), 2, _shadowOptions.color.CGColor);
	}
	
	[[UIColor whiteColor] set];
	CGContextSetLineWidth(ctx, 6);
	CGContextStrokeEllipseInRect(ctx, CGRectInset(bounds, 7, 7));
	
	CGContextRestoreGState(ctx);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
