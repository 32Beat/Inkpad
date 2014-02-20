//
//  UIColor+Additions.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIColor+Additions.h"
#import "WDUtilities.h"
#if TARGET_OS_IPHONE
#import <OpenGLES/ES1/gl.h>
#else
#import <OpenGL/gl.h>
#endif

////////////////////////////////////////////////////////////////////////////////
@implementation UIColor (WDAdditions)
////////////////////////////////////////////////////////////////////////////////

+ (UIColor *) randomColor
{ return [self randomColor:NO]; }

////////////////////////////////////////////////////////////////////////////////

+ (UIColor *) randomColor:(BOOL)includeAlpha
{
	float components[4];
	
	for (int i = 0; i < 4; i++) {
		components[i] = WDRandomFloat();
	}

	float alpha = (includeAlpha ? components[3] : 1.0f);
	alpha = 0.5 + (alpha * 0.5);
	
	return [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:alpha];
}

////////////////////////////////////////////////////////////////////////////////

+ (UIColor *) saturatedRandomColor
{
	return [UIColor colorWithHue:WDRandomFloat() saturation:0.7f brightness:0.75f alpha:1.0];
}

////////////////////////////////////////////////////////////////////////////////

- (UIColor *) opaqueColor
{ return [self colorWithAlphaComponent:1.0]; }

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithRGBA:(const CGFloat *)cmp
{ return [UIColor colorWithRed:cmp[0] green:cmp[1] blue:cmp[2] alpha:cmp[3]]; }

+ (id) colorWithHSBA:(const CGFloat *)cmp
{ return [UIColor colorWithHue:cmp[0] saturation:cmp[1] brightness:cmp[2] alpha:cmp[3]]; }

////////////////////////////////////////////////////////////////////////////////

- (void) getRGBA:(CGFloat *)cmp
{ [self getRed:&cmp[0] green:&cmp[1] blue:&cmp[2] alpha:&cmp[3]]; }

- (void) getHSBA:(CGFloat *)cmp
{ [self getHue:&cmp[0] saturation:&cmp[1] brightness:&cmp[2] alpha:&cmp[3]]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) hue
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getHSBA:cmp];
	return cmp[0];
}

- (CGFloat) saturation
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getHSBA:cmp];
	return cmp[1];
}

- (CGFloat) brightness
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getHSBA:cmp];
	return cmp[2];
}

- (CGFloat) red
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getRGBA:cmp];
	return cmp[0];
}
- (CGFloat) green
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getRGBA:cmp];
	return cmp[1];
}
- (CGFloat) blue
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getRGBA:cmp];
	return cmp[2];
}

- (CGFloat) alpha
{
	CGFloat cmp[4] = { 0.0, 0.0, 0.0, 0.0 };
	[self getRGBA:cmp];
	return cmp[3];
}

////////////////////////////////////////////////////////////////////////////////

- (id) colorByReplacingHue:(CGFloat)hue
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	cmp[0] = fmod(hue, 1.0);
	return [UIColor colorWithHue:cmp[0]
	saturation:cmp[1] brightness:cmp[2] alpha:cmp[3]];
}

////////////////////////////////////////////////////////////////////////////////

- (id) colorByReplacingSaturation:(CGFloat)sat
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	cmp[1] = sat;
	return [UIColor colorWithHue:cmp[0]
	saturation:cmp[1] brightness:cmp[2] alpha:cmp[3]];
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyByReplacingBrightness:(CGFloat)bri
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	cmp[3] = bri;
	return [UIColor colorWithHue:cmp[0]
	saturation:cmp[1] brightness:cmp[2] alpha:cmp[3]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) glSet
{
	CGFloat w, r, g, b, a;

	if ([self getRed:&r green:&g blue:&b alpha:&a])
	{ glColor4f(r, g, b, a); }
	else
	if ([self getWhite:&w alpha:&a])
	{ glColor4f(w, w, w, a); }
	else
	{ glColor4f(0.0, 0.0, 0.0, 1.0); }
}

////////////////////////////////////////////////////////////////////////////////

- (void) openGLSet
{
	CGFloat w, r, g, b, a;
	
	if ([self getRed:&r green:&g blue:&b alpha:&a]) {
		glColor4f(r, g, b, a);
	} else {
		[self getWhite:&w alpha:&a];
		glColor4f(w, w, w, a);
	}
}

@end
