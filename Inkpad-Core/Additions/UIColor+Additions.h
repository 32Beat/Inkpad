////////////////////////////////////////////////////////////////////////////////
/*
	UIColor+Additions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

@interface UIColor (WDAdditions)

+ (UIColor *) randomColor;
+ (UIColor *) randomColor:(BOOL)includeAlpha;
+ (UIColor *) saturatedRandomColor;

- (void) glSet;
- (void) openGLSet;

- (UIColor *) opaqueColor;

+ (id) colorWithRGBA:(const CGFloat *)cmp;
+ (id) colorWithHSBA:(const CGFloat *)cmp;

- (void) getRGBA:(CGFloat *)cmp;
- (void) getHSBA:(CGFloat *)cmp;

- (CGFloat) hue;
- (CGFloat) saturation;
- (CGFloat) brightness;

- (CGFloat) red;
- (CGFloat) green;
- (CGFloat) blue;
- (CGFloat) alpha;

@end
