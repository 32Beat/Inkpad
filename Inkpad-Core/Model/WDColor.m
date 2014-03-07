////////////////////////////////////////////////////////////////////////////////
/*
	WDColor.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColor.h"
#import "WDUtilities.h"

// glSet uses glColor4f
#if TARGET_OS_IPHONE
#import <OpenGLES/ES1/gl.h>
#else
#import <OpenGL/gl.h>
#endif

// paintPath:inContext:
#import "WDPath.h"

////////////////////////////////////////////////////////////////////////////////

NSInteger const WDColorVersion = 1;
NSString *const WDColorVersionKey = @"WDColorVersion";
NSString *const WDColorTypeKey = @"WDColorType";
NSString *const WDColorComponentsKey = @"WDColorComponents";

////////////////////////////////////////////////////////////////////////////////
// Version < 2.0

NSString *const WDHueKey = @"WDHueKey";
NSString *const WDSaturationKey = @"WDSaturationKey";
NSString *const WDBrightnessKey = @"WDBrightnessKey";
NSString *const WDAlphaKey = @"WDAlphaKey";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDColor
////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithRGBA:(const CGFloat *)cmp
{ return [self colorWithType:WDColorTypeRGB components:cmp]; }

+ (id) colorWithHSBA:(const CGFloat *)cmp
{ return [self colorWithType:WDColorTypeHSB components:cmp]; }

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithType:(WDColorType)type components:(const CGFloat *)cmp
{ return [[self alloc] initWithType:type components:cmp]; }

- (id) initWithType:(WDColorType)type components:(const CGFloat *)cmp
{
	self = [super init];
	if (self != nil)
	{
		mType = type;
		mComponent[0] = cmp[0];
		mComponent[1] = cmp[1];
		mComponent[2] = cmp[2];
		mComponent[3] = cmp[3];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
	CGFloat cmp[] = { white, white, white, alpha };
	return [self colorWithType:WDColorTypeRGB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithRed:(CGFloat)red
	green:(CGFloat)green
	blue:(CGFloat)blue
	alpha:(CGFloat)alpha
{
	CGFloat cmp[] = { red, green, blue, alpha };
	return [self colorWithType:WDColorTypeRGB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithHue:(CGFloat)hue
	saturation:(CGFloat)saturation
	brightness:(CGFloat)brightness
	alpha:(CGFloat)alpha
{
	CGFloat cmp[] = { hue, saturation, brightness, alpha };
	return [self colorWithType:WDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) colorWithAlphaComponent:(CGFloat)alpha
{
	if (self.alpha == alpha)
	{ return self; }

	CGFloat cmp[4] = {
		mComponent[0],
		mComponent[1],
		mComponent[2],
		alpha };

	return [[self class] colorWithType:mType components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) colorWithComponentValue:(CGFloat)value atIndex:(int)index
{
	if (mComponent[index] == value)
	{ return self; }

	CGFloat cmp[4] = {
		mComponent[0],
		mComponent[1],
		mComponent[2],
		mComponent[3] };

	cmp[index] = value;
	return [[self class] colorWithType:mType components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithUIColor:(UIColor *)color
{
	return [self colorWithRed:[color red]
	green:[color green] blue:[color blue] alpha:[color alpha]];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) randomColor
{
	CGFloat cmp[4] = {
		WDRandomFloat(),
		WDRandomFloat(),
		WDRandomFloat(),
		0.5 + 0.5*WDRandomFloat() };

	return [self colorWithType:WDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDRandomHue
	-----------
	Generate random number between 0.0 inclusive and 1.0 exclusive
	range of random() = [0 ... ((2^31)-1)]
*/
double WDRandomHue(void)
{ return (double)random() / 2147483648.0; } // divide by 2^31

////////////////////////////////////////////////////////////////////////////////
/*
	colorWithRandomHue
	------------------
	Create an easily distinguishable highlight color
	
	In order to create easily distinguishable highlight colors
	this routine rotates sequentially through the following set of colors:

		red, orange, yellow, green, cyan, blue, purple, magenta
*/

+ (id) colorWithRandomHue
{
	static int i = 0;
	static const CGFloat HUE[] =
	{ 0.0, 30.0, 60.0, 120.0, 180.0, 220.0, 290.0, 320.0 };

	CGFloat cmp[4] = {
		HUE[(i+=5)%8] / 360.0,
		0.5 + 0.1*floor(6*WDRandomHue()),
		0.5 + 0.1*floor(6*WDRandomHue()),
		1.0 };

	return [self colorWithType:WDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (id) colorWithColorType:(WDColorType)colorType
{
	if (mType == colorType)
	{ return self; }

	CGFloat cmp[4];
	if (colorType == WDColorTypeLCH)
	{ [self getLCH:cmp]; }
	else
	if (colorType == WDColorTypeLab)
	{ [self getLAB:cmp]; }
	else
	if (colorType == WDColorTypeHSB)
	{ [self getHSB:cmp]; }
	else
	if (colorType == WDColorTypeRGB)
	{ [self getRGB:cmp]; }

	return [[self class] colorWithType:colorType components:cmp];
}

////////////////////////////////////////////////////////////////////////////////
/*
- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeFloat:hue_ forKey:WDHueKey];
	[coder encodeFloat:saturation_ forKey:WDSaturationKey]; 
	[coder encodeFloat:brightness_ forKey:WDBrightnessKey]; 
	[coder encodeFloat:alpha_ forKey:WDAlphaKey]; 
}
//*/
////////////////////////////////////////////////////////////////////////////////
//*
- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:WDColorVersion forKey:WDColorVersionKey];
	[coder encodeInt:mType forKey:WDColorTypeKey];

	NSArray *cmp = @[
		@(mComponent[0]),
		@(mComponent[1]),
		@(mComponent[2]),
		@(mComponent[3])];
	[coder encodeObject:cmp forKey:WDColorComponentsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDColorTypeKey])
	{ mType = [coder decodeIntForKey:WDColorTypeKey]; }

	if ([coder containsValueForKey:WDColorComponentsKey])
	{
		NSArray *cmp = [coder decodeObjectForKey:WDColorComponentsKey];
		if (cmp.count == 4)
		{
			mComponent[0] = [[cmp objectAtIndex:0] doubleValue];
			mComponent[1] = [[cmp objectAtIndex:1] doubleValue];
			mComponent[2] = [[cmp objectAtIndex:2] doubleValue];
			mComponent[3] = [[cmp objectAtIndex:3] doubleValue];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{
		int version = [coder decodeIntForKey:WDColorVersionKey];
		if (version == 0)
		[self decodeWithCoder0:coder];
		else
		[self decodeWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeWithCoder0:(NSCoder *)coder
{
	mType = WDColorTypeHSB;
	mComponent[0] = [coder decodeFloatForKey:WDHueKey];
	mComponent[1] = [coder decodeFloatForKey:WDSaturationKey];
	mComponent[2] = [coder decodeFloatForKey:WDBrightnessKey];
	mComponent[3] = [coder decodeFloatForKey:WDAlphaKey];
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) gradientForComponentAtIndex:(int)index
{
	if ((mType == WDColorTypeLCH)&&(index == 2))
	{
		return @[
		[self colorWithComponentValue:0.0/360 atIndex:index],
		
		[self colorWithComponentValue:15.0/360 atIndex:index],
		[self colorWithComponentValue:30.0/360 atIndex:index],
		[self colorWithComponentValue:45.0/360 atIndex:index],
		[self colorWithComponentValue:60.0/360 atIndex:index],
		[self colorWithComponentValue:75.0/360 atIndex:index],
		[self colorWithComponentValue:90.0/360 atIndex:index],

		[self colorWithComponentValue:105.0/360 atIndex:index],
		[self colorWithComponentValue:120.0/360 atIndex:index],
		[self colorWithComponentValue:135.0/360 atIndex:index],
		[self colorWithComponentValue:150.0/360 atIndex:index],
		[self colorWithComponentValue:165.0/360 atIndex:index],
		[self colorWithComponentValue:180.0/360 atIndex:index],

		[self colorWithComponentValue:195.0/360 atIndex:index],
		[self colorWithComponentValue:210.0/360 atIndex:index],
		[self colorWithComponentValue:225.0/360 atIndex:index],
		[self colorWithComponentValue:240.0/360 atIndex:index],
		[self colorWithComponentValue:255.0/360 atIndex:index],
		[self colorWithComponentValue:270.0/360 atIndex:index],

		[self colorWithComponentValue:285.0/360 atIndex:index],
		[self colorWithComponentValue:300.0/360 atIndex:index],
		[self colorWithComponentValue:315.0/360 atIndex:index],
		[self colorWithComponentValue:330.0/360 atIndex:index],
		[self colorWithComponentValue:345.0/360 atIndex:index],
		[self colorWithComponentValue:360.0/360 atIndex:index]];
	}

	if ((mType == WDColorTypeLab)||
		(mType == WDColorTypeLCH))
	{
		return @[
		[self colorWithComponentValue:0.0 atIndex:index],
		[self colorWithComponentValue:0.1 atIndex:index],
		[self colorWithComponentValue:0.2 atIndex:index],
		[self colorWithComponentValue:0.3 atIndex:index],
		[self colorWithComponentValue:0.4 atIndex:index],
		[self colorWithComponentValue:0.5 atIndex:index],
		[self colorWithComponentValue:0.6 atIndex:index],
		[self colorWithComponentValue:0.7 atIndex:index],
		[self colorWithComponentValue:0.8 atIndex:index],
		[self colorWithComponentValue:0.9 atIndex:index],
		[self colorWithComponentValue:1.0 atIndex:index]];
	}

	if ((mType == WDColorTypeHSB)&&(index == 0))
	{
		return @[
		[self colorWithComponentValue:0.0/360 atIndex:index],
		[self colorWithComponentValue:60.0/360 atIndex:index],
		[self colorWithComponentValue:120.0/360 atIndex:index],
		[self colorWithComponentValue:180.0/360 atIndex:index],
		[self colorWithComponentValue:240.0/360 atIndex:index],
		[self colorWithComponentValue:300.0/360 atIndex:index],
		[self colorWithComponentValue:360.0/360 atIndex:index]];
	}

	return @[
	[self colorWithComponentValue:0.0 atIndex:index],
	[self colorWithComponentValue:1.0 atIndex:index]];
}

////////////////////////////////////////////////////////////////////////////////


- (NSString *) description
{
	return [NSString stringWithFormat:@"%@: H: %f, S: %f, V:%f, A: %f", \
	[super description], \
	mComponent[0], \
	mComponent[1], \
	mComponent[2], \
	mComponent[3]];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) isEqual:(WDColor *)color
{
	if (color == self)
	{ return YES; }
	
	if (![color isKindOfClass:[WDColor class]])
	{ return NO; }
	
	return
	self->mType == color->mType &&
	self->mComponent[0] == color->mComponent[0] &&
	self->mComponent[1] == color->mComponent[1] &&
	self->mComponent[2] == color->mComponent[2] &&
	self->mComponent[3] == color->mComponent[3];
}

- (NSDictionary *) dictionary
{
	return @{
		WDColorTypeKey : @(mType),
		WDColorComponentsKey : @[
			@(mComponent[0]),
			@(mComponent[1]),
			@(mComponent[2]),
			@(mComponent[3])]};
}

+ (WDColor *) colorWithDictionary:(NSDictionary *)dict
{
	float hue = [dict[@"hue"] floatValue];
	float saturation = [dict[@"saturation"] floatValue];
	float brightness = [dict[@"brightness"] floatValue];
	float alpha = [dict[@"alpha"] floatValue];
	
	return [WDColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}


+ (WDColor *) colorWithData:(NSData *)data
{
	UInt16  *values = (UInt16 *) [data bytes];
	float   components[4];
	
	for (int i = 0; i < 4; i++) {
		components[i] = CFSwapInt16LittleToHost(values[i]);
		components[i] /= USHRT_MAX;
	}
	
	return [WDColor colorWithHue:components[0] saturation:components[1] brightness:components[2] alpha:components[3]];
}
	
- (NSData *) colorData
{
	UInt16 data[4];
	
	data[0] = mComponent[0] * USHRT_MAX;
	data[1] = mComponent[1] * USHRT_MAX;
	data[2] = mComponent[2] * USHRT_MAX;
	data[3] = mComponent[3] * USHRT_MAX;

	for (int i = 0; i < 4; i++) {
		data[i] = CFSwapInt16HostToLittle(data[i]);
	}
	
	return [NSData dataWithBytes:data length:8];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (UIColor *) UIColor
{
	if (mUIColor == nil)
	{
		CGFloat cmp[4];
		[self getRGB:cmp];
		mUIColor = [[UIColor alloc]
		initWithRed:cmp[0] green:cmp[1] blue:cmp[2] alpha:cmp[3]];
	}

	return mUIColor;
}

////////////////////////////////////////////////////////////////////////////////

- (CGColorRef) CGColor
{ return [[self UIColor] CGColor]; }

////////////////////////////////////////////////////////////////////////////////

- (UIColor *) opaqueUIColor
{ return [[self UIColor] colorWithAlphaComponent:1.0]; }

////////////////////////////////////////////////////////////////////////////////

- (CGColorRef) opaqueCGColor
{ return [[self opaqueUIColor] CGColor]; }

////////////////////////////////////////////////////////////////////////////////

- (BOOL) visible
{ return mComponent[3] > 0.0; }

////////////////////////////////////////////////////////////////////////////////

- (void) set
{ [[self UIColor] set]; }

////////////////////////////////////////////////////////////////////////////////

- (void) glSet
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	glColor4f(cmp[0], cmp[1], cmp[2], cmp[3]);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Raw properties
////////////////////////////////////////////////////////////////////////////////

- (WDColorType) type
{ return mType; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) componentAtIndex:(int)index
{ return mComponent[index]; }

////////////////////////////////////////////////////////////////////////////////

- (void) getComponents:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];
}

////////////////////////////////////////////////////////////////////////////////

- (void) getRGB:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	switch(mType)
	{
		case WDColorTypeLCH:
			LCHtoLAB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeLab:
			LABtoXYZ(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeXYZ:
			XYZtoSRGB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeRGB:default:
			break;

		case WDColorTypeHSB:
			HSVtoRGB(cmp[0], cmp[1], cmp[2], cmp);
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) getHSB:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	switch(mType)
	{
		case WDColorTypeLCH:
			LCHtoLAB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeLab:
			LABtoXYZ(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeXYZ:
			XYZtoSRGB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeRGB:default:
			RGBtoHSV(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeHSB:
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) getLAB:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	switch(mType)
	{
		case WDColorTypeHSB:
			HSVtoRGB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeRGB:default:
			SRGBtoXYZ(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeXYZ:
			XYZtoLAB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeLab:
			break;

		case WDColorTypeLCH:
			LCHtoLAB(cmp[0], cmp[1], cmp[2], cmp);
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) getLCH:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	switch(mType)
	{
		case WDColorTypeHSB:
			HSVtoRGB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeRGB:default:
			SRGBtoXYZ(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeXYZ:
			XYZtoLAB(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeLab:
			LABtoLCH(cmp[0], cmp[1], cmp[2], cmp);
		case WDColorTypeLCH:
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIKit synchronisation
////////////////////////////////////////////////////////////////////////////////

- (CGFloat) red
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[0];
}

- (CGFloat) green
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[1];
}

- (CGFloat) blue
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[2];
}

- (CGFloat) alpha
{ return mComponent[3]; }

- (CGFloat) hue
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[0];
}

- (CGFloat) saturation
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[1];
}

- (CGFloat) brightness
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[2];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Converted properties
////////////////////////////////////////////////////////////////////////////////

- (CGFloat) rgb_R
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[0];
}

- (CGFloat) rgb_G
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[1];
}

- (CGFloat) rgb_B
{
	CGFloat cmp[4];
	[self getRGB:cmp];
	return cmp[2];
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) hsb_H
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[0] * 360.0;
}

- (CGFloat) hsb_S
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[1] * 100.0;
}

- (CGFloat) hsb_B
{
	CGFloat cmp[4];
	[self getHSB:cmp];
	return cmp[2] * 100.0;
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) lab_L
{
	CGFloat cmp[4];
	[self getLAB:cmp];
	return cmp[0] * 100;
}

- (CGFloat) lab_a
{
	CGFloat cmp[4];
	[self getLAB:cmp];
	return cmp[1] * 240 - 120;
}

- (CGFloat) lab_b
{
	CGFloat cmp[4];
	[self getLAB:cmp];
	return cmp[2] * 240 - 120;
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) lch_L
{
	CGFloat cmp[4];
	[self getLCH:cmp];
	return cmp[0] * 100;
}

- (CGFloat) lch_C
{
	CGFloat cmp[4];
	[self getLCH:cmp];
	return cmp[1] * 120;
}

- (CGFloat) lch_H
{
	CGFloat cmp[4];
	[self getLCH:cmp];
	return cmp[2] * 360;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (WDColor *) adjustColor:(WDColor * (^)(WDColor *color))adjustment
{
	return adjustment(self);
}

- (WDColor *) colorBalanceRed:(float)rShift green:(float)gShift blue:(float)bShift
{
	CGFloat cmp[4];
	[self getRGB:cmp];

	cmp[0] = WDClamp(0, 1, cmp[0] + rShift);
	cmp[1] = WDClamp(0, 1, cmp[1] + gShift);
	cmp[2] = WDClamp(0, 1, cmp[2] + bShift);

	return [[self class] colorWithType:WDColorTypeRGB components:cmp];
}

- (WDColor *) adjustHue:(float)hShift
	saturation:(float)sShift
	brightness:(float)bShift
{
	CGFloat cmp[4];
	[self getHSB:cmp];

	CGFloat h = cmp[0] + hShift;
	BOOL negative = (h < 0);
	h = fmod(fabs(h), 1.0f);
	if (negative) {
		h = 1.0f - h;
	}
	
	sShift = 1 + sShift;
	bShift = 1 + bShift;
	CGFloat s = WDClamp(0, 1, cmp[1] * sShift);
	CGFloat b = WDClamp(0, 1, cmp[2] * bShift);
	
	return [[self class] colorWithHue:h saturation:s brightness:b alpha:cmp[3]];
}

- (WDColor *) inverted
{
	CGFloat cmp[4];
	[self getRGB:cmp];

	cmp[0] = 1.0 - cmp[0];
	cmp[1] = 1.0 - cmp[1];
	cmp[2] = 1.0 - cmp[2];

	return [[self class] colorWithType:WDColorTypeRGB components:cmp];
}

+ (WDColor *) blackColor
{
	return [WDColor colorWithHue:0.0f saturation:0.0f brightness:0.0f alpha:1.0f];
}

+ (WDColor *) grayColor
{
	return [WDColor colorWithHue:0.0f saturation:0.0f brightness:0.25f alpha:1.0f];
}

+ (WDColor *) whiteColor
{
	return [WDColor colorWithHue:0.0f saturation:0.0f brightness:1.0f alpha:1.0f];
}

+ (WDColor *) cyanColor
{
	return [WDColor colorWithRed:0 green:1 blue:1 alpha:1];
}

+ (WDColor *) redColor
{
	return [WDColor colorWithRed:1 green:0 blue:0 alpha:1];
}

+ (WDColor *) magentaColor
{
	return [WDColor colorWithRed:1 green:0 blue:1 alpha:1];
}

+ (WDColor *) greenColor
{
	return [WDColor colorWithRed:0 green:1 blue:0 alpha:1];
}

+ (WDColor *) yellowColor
{
	return [WDColor colorWithRed:1 green:1 blue:0 alpha:1];
}

+ (WDColor *) blueColor
{
	return [WDColor colorWithRed:0 green:0 blue:1 alpha:1];
}

- (WDColor *) blendedColorWithFraction:(float)blend ofColor:(WDColor *)color
{
	CGFloat src[4];
	CGFloat dst[4];

	[self getComponents:src];
	color = [color colorWithColorType:self.type];
	[color getComponents:dst];

	src[0] += blend * (dst[0] - src[0]);
	src[1] += blend * (dst[1] - src[1]);
	src[2] += blend * (dst[2] - src[2]);
	src[3] += blend * (dst[3] - src[3]);

	return [WDColor colorWithType:WDColorTypeRGB components:src];
}

- (NSString *) hexValue
{   
	CGFloat cmp[4];
	[self getRGB:cmp];

	return [NSString stringWithFormat:@"#%.2x%.2x%.2x", \
	(int)(255*cmp[0] + 0.5f), \
	(int)(255*cmp[1] + 0.5f), \
	(int)(255*cmp[2] + 0.5f)];
}

- (void) paintPath:(WDPath *)path inContext:(CGContextRef)ctx
{    
	CGContextAddPath(ctx, path.pathRef);
	CGContextSetFillColorWithColor(ctx, self.CGColor);
	
	if (path.fillRule == kWDEvenOddFillRule) {
		CGContextEOFillPath(ctx);
	} else {
		CGContextFillPath(ctx);
	}
}

- (void) drawSwatchInRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	WDDrawTransparencyDiamondInRect(ctx, rect);
	
	[self set];
	CGContextFillRect(ctx, rect);
}

- (void) drawEyedropperSwatchInRect:(CGRect)rect
{
	[self drawSwatchInRect:rect];
}

- (BOOL) wantsCenteredFillTransform
{
	return NO;
}

- (BOOL) transformable
{
	return NO;
}

- (BOOL) canPaintStroke
{
	return YES;
}

- (void) paintText:(id<WDTextRenderer>)text inContext:(CGContextRef)ctx
{
	[self set];
	[text drawTextInContext:ctx drawingMode:kCGTextFill];
}

- (id) copyWithZone:(NSZone *)zone
{
	// this object is immutable
	return self;
}

@end
