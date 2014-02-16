////////////////////////////////////////////////////////////////////////////////
/*
	WDBlendOptions.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShadowOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

NSString *const WDShadowOptionsKey = @"WDShadowOptions";
NSString *const WDShadowColorKey = @"WDShadowColor";
NSString *const WDShadowOffsetKey = @"WDShadowOffset";
NSString *const WDShadowBlurKey = @"WDShadowBlur";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDShadowOptions
////////////////////////////////////////////////////////////////////////////////

- (void) applyInContext:(CGContextRef)context
{
	if (context != nil)
	{
		CGContextSetShadowWithColor(context,
			[self shadowOffset],
			[self shadowBlur],
			[self shadowColor].CGColor);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGSize) shadowOffset
{ return [[self valueForKey:WDShadowOffsetKey] CGSizeValue]; }

- (void) setShadowOffset:(CGSize)offset
{ [self setValue:[NSValue valueWithCGSize:offset] forKey:WDShadowOffsetKey]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) shadowBlur
{ return [[self valueForKey:WDShadowBlurKey] doubleValue]; }

- (void) setShadowBlur:(CGFloat)blurRadius
{ [self setValue:NSNumberFromCGFloat(blurRadius) forKey:WDShadowBlurKey]; }

////////////////////////////////////////////////////////////////////////////////

- (UIColor *) shadowColor
{ return [self valueForKey:WDShadowColorKey]; }

- (void) setShadowColor:(UIColor *)color
{ [self setValue:color forKey:WDShadowColorKey]; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



