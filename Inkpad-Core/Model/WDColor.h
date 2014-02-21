////////////////////////////////////////////////////////////////////////////////
/*
	WDColor.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import "WDPathPainter.h"
#import "UIColor_Additions.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDColor
	-------
	Color object with original parameter entries

	The user generally wants to see the original entries for parameters, 
	and using a separate object allows additional colorspaces.
	In order to prevent confusion with CGColorSpaceRef and WDColorSpaceKey
	we'll use WDColorType
*/
////////////////////////////////////////////////////////////////////////////////

typedef enum
{
	kWDColorTypeRGB,
	kWDColorTypeHSB
}
WDColorType;

////////////////////////////////////////////////////////////////////////////////

@interface WDColor : NSObject <NSCoding, NSCopying, WDPathPainter>
{
	WDColorType mType;
	CGFloat mComponent[4];

	// Cached
	UIColor *mUIColor;
}

- (CGFloat)red;
- (CGFloat)green;
- (CGFloat)blue;
- (CGFloat) alpha;

- (CGFloat) hue;
- (CGFloat) saturation;
- (CGFloat) brightness;


+ (WDColor *) colorWithRGBA:(const CGFloat *)cmp;
+ (WDColor *) colorWithHSBA:(const CGFloat *)cmp;
+ (WDColor *) colorWithType:(WDColorType)type components:(const CGFloat *)cmp;
- (WDColor *) initWithType:(WDColorType)type components:(const CGFloat *)cmp;
- (WDColor *) colorWithAlphaComponent:(float)alpha;

+ (WDColor *) colorWithWhite:(CGFloat)white
		alpha:(CGFloat)alpha;
+ (WDColor *) colorWithRed:(CGFloat)red
		green:(CGFloat)green
		blue:(CGFloat)blue
		alpha:(CGFloat)alpha;
+ (WDColor *) colorWithHue:(CGFloat)hue
		saturation:(CGFloat)saturation
		brightness:(CGFloat)brightness
		alpha:(CGFloat)alpha;

+ (WDColor *) randomColor;
+ (WDColor *) colorWithUIColor:(UIColor *)color;


+ (WDColor *) colorWithDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionary;

+ (WDColor *) colorWithData:(NSData *)data;
- (NSData *) colorData;

- (UIColor *) UIColor;
- (UIColor *) opaqueUIColor;

- (CGColorRef) CGColor;
- (CGColorRef) opaqueCGColor;

- (void) set;

- (WDColor *) adjustColor:(WDColor * (^)(WDColor *color))adjustment;
- (WDColor *) colorBalanceRed:(float)rShift green:(float)gShift blue:(float)bShift;
- (WDColor *) adjustHue:(float)hShift saturation:(float)sShift brightness:(float)bShift;
- (WDColor *) inverted;

+ (WDColor *) blackColor;
+ (WDColor *) grayColor;
+ (WDColor *) whiteColor;
+ (WDColor *) cyanColor;
+ (WDColor *) redColor;
+ (WDColor *) magentaColor;
+ (WDColor *) greenColor;
+ (WDColor *) yellowColor;
+ (WDColor *) blueColor;

- (NSString *) hexValue;

- (WDColor *) blendedColorWithFraction:(float)fraction ofColor:(WDColor *)color;
@end

