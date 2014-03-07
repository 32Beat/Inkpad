////////////////////////////////////////////////////////////////////////////////
/*
	WDColorIndicator.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////


#import "WDColorIndicator.h"


////////////////////////////////////////////////////////////////////////////////
@implementation WDColorIndicator
////////////////////////////////////////////////////////////////////////////////
/*
	colorIndicator
	--------------
	Create colorIndicator view
	
	We will use an even sized rectangle, so image can be rendered sharply
	when fit on pixelborders. This allows easy translation of value/position, 
	since 0.0 and 1.0 can simply fall exactly on trackbounds.
*/

+ (WDColorIndicator *) colorIndicator
{ return [[WDColorIndicator alloc] initWithFrame:CGRectMake(0, 0, 24, 24)]; }

////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self != nil)
	{
		self.opaque = NO;

		self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0f;
		self.layer.borderWidth = 3;
		self.layer.borderColor = self.defaultBorderColor;
		self.layer.backgroundColor = self.defaultBackgroundColor;

		self.layer.shadowRadius = 1;
		self.layer.shadowOffset = CGSizeMake(0, 0);
		self.layer.shadowOpacity = 0.5f;

		self.layer.delegate = self;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////
/*
	defaultBackgroundColor
	----------------------
	Pattern color for black&white triangle backing
*/
- (CGColorRef) defaultBackgroundColor
{
	static UIColor *gPattern = nil;
	if (gPattern == nil)
	{
		CGRect R = self.bounds;

		UIGraphicsBeginImageContextWithOptions
		(R.size, NO, [UIScreen mainScreen].scale);
		CGContextRef ctx = UIGraphicsGetCurrentContext();

		// Keep drawing away from edge or it will influence shadow
		CGContextAddEllipseInRect(ctx, CGRectInset(R, 1, 1));
		CGContextClip(ctx);

		// Fill entirely with light color
		UIColor *lightColor =
		[UIColor colorWithWhite:0.9 alpha:1.0];

		CGContextSetFillColorWithColor(ctx, lightColor.CGColor);
		CGContextFillRect(ctx, R);

		// Adjust to 45degr angle
		CGContextRotateCTM(ctx, 0.25*M_PI);
		R.size.width *= 2;

		// Fill half the circle with black at 45degr angle
		UIColor *darkColor =
		[UIColor colorWithWhite:0.0 alpha:1.0];

		CGContextSetFillColorWithColor(ctx, darkColor.CGColor);
		CGContextFillRect(ctx, R);

		// Save as pattern image
		gPattern = [UIColor colorWithPatternImage:
		UIGraphicsGetImageFromCurrentImageContext()];

		UIGraphicsEndImageContext();
	}

	return gPattern.CGColor;
}


////////////////////////////////////////////////////////////////////////////////
/*
	defaultBorderColor
	------------------
	Slightly shaded layerborder so white color looks better
*/

- (CGColorRef) defaultBorderColor
{
	static UIColor *gColor = nil;
	if (gColor == nil)
	{ gColor = [[UIColor alloc] initWithWhite:0.95 alpha:1.0]; }
	return gColor.CGColor;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{
	if (self.showsAlpha == NO)
	{ color = [color colorWithAlphaComponent:1.0]; }

	_color = color;

	// Force layer redraw
	[self.layer setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////
// Layer delegate processing
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	if (self.color != nil)
	{
		CGRect bounds = CGRectInset(self.bounds, 1, 1);
		CGContextSetFillColorWithColor(ctx, self.color.CGColor);
		CGContextAddEllipseInRect(ctx, bounds);
		CGContextFillPath(ctx);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{ return NO; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


