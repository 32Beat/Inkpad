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
	and using a separate object allows additional colortypes internally.
*/
////////////////////////////////////////////////////////////////////////////////
/*
	WDColorType
	-----------
	Enumeration for types of components
	This only refers to what type of components are stored, it does not 
	refer to the interpretation. In order to prevent confusion with 
	CGColorSpaceRef and WDColorSpaceKey which are typically used for 
	interpretation, we'll use WDColorType.
	
	Note: for all kinds of reasons we will not support CMYK 
*/

typedef enum
{
	WDColorTypeDevice = 0,
	WDColorTypeWht,
	WDColorTypeRGB,
	WDColorTypeHSB,
	WDColorTypeXYZ,
	WDColorTypeLab,
	WDColorTypeLCH
}
WDColorType;

////////////////////////////////////////////////////////////////////////////////
/*
	WDColorSpace
	------------
	Enumeration for some default colorspaces
	We'll define Colorspace as: interpretation reference for colorcoordinates.
	
	i.e.: 
	we can have HSB components, 
	which convert to RGB coordinates,
	that need to be interpreted as sRGB

	While this enumeration is not currently used, 
	it will enforce usage patterns internally.
	
	Within our definitions there is technically no such thing
	as an Lab space. Lab has XYZ interpretation reference.
	Strictly XYZ is only valid if it includes an illuminant reference. 
	Once that becomes relevant, methods will be created to ensure 
	it will always be clear what is used.
	
	For now we always use illuminant E = { 1.0, 1.0, 1.0 } since 
	we are primarily interested in relative colorimetric Lab to RGB
	conversions for which illuminant is irrelevant.
*/

typedef enum
{
	WDColorSpaceCustom = (-1),
	WDColorSpaceDevice = 0,
	WDColorSpaceSRGB,
	WDColorSpaceXYZ
}
WDColorSpace;

////////////////////////////////////////////////////////////////////////////////
/*

*/

@interface WDColor : NSObject <NSCoding, NSCopying, WDPathPainter>
{
	// Component values
	CGFloat mComponent[4];

	// Type of components
	WDColorType mType;
	// Interpretation of color
	WDColorSpace mSpace;

	// Cache
	UIColor *mUIColor;
}

// Raw properties
- (WDColorType) type;
- (CGFloat) componentAtIndex:(int)index;
- (void) getComponents:(CGFloat *)cmp;

// Synchronisation with UIColor
- (CGFloat) red;
- (CGFloat) green;
- (CGFloat) blue;
- (CGFloat) alpha;

- (CGFloat) hue;
- (CGFloat) saturation;
- (CGFloat) brightness;


// Typed query
- (CGFloat) rgb_R;
- (CGFloat) rgb_G;
- (CGFloat) rgb_B;

- (CGFloat) hsb_H;
- (CGFloat) hsb_S;
- (CGFloat) hsb_B;
/*
- (CGFloat) xyz_X;
- (CGFloat) xyz_Y;
- (CGFloat) xyz_Z;
*/
- (CGFloat) lab_L;
- (CGFloat) lab_a;
- (CGFloat) lab_b;

- (CGFloat) lch_L;
- (CGFloat) lch_C;
- (CGFloat) lch_H;



+ (WDColor *) colorWithRGBA:(const CGFloat *)cmp;
+ (WDColor *) colorWithHSBA:(const CGFloat *)cmp;
+ (WDColor *) colorWithType:(WDColorType)type components:(const CGFloat *)cmp;
- (WDColor *) initWithType:(WDColorType)type components:(const CGFloat *)cmp;

- (WDColor *) colorWithColorType:(WDColorType)colorType;
- (WDColor *) colorWithComponentValue:(CGFloat)value atIndex:(int)index;
- (WDColor *) colorWithAlphaComponent:(CGFloat)alpha;

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
+ (WDColor *) colorWithRandomHue;
+ (WDColor *) colorWithUIColor:(UIColor *)color;


+ (WDColor *) colorWithDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionary;

+ (WDColor *) colorWithData:(NSData *)data;
- (NSData *) colorData;


- (NSArray *) gradientForComponentAtIndex:(int)index;


- (UIColor *) UIColor;
- (UIColor *) opaqueUIColor;

- (CGColorRef) CGColor;
- (CGColorRef) opaqueCGColor;

- (BOOL) visible;
- (void) set;
- (void) glSet;

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



