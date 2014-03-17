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
@implementation WDColor
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
#pragma mark -
#pragma mark Encoding/Decoding
////////////////////////////////////////////////////////////////////////////////

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

- (void) decodeWithCoder0:(NSCoder *)coder
{
	mType = WDColorTypeHSB;
	mComponent[0] = [coder decodeFloatForKey:WDHueKey];
	mComponent[1] = [coder decodeFloatForKey:WDSaturationKey];
	mComponent[2] = [coder decodeFloatForKey:WDBrightnessKey];
	mComponent[3] = [coder decodeFloatForKey:WDAlphaKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Creators with extended values
////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithR:(CGFloat)R G:(CGFloat)G B:(CGFloat)B
{ return [self colorWithR:R G:G B:B alpha:1.0]; }

+ (id) colorWithR:(CGFloat)R G:(CGFloat)G B:(CGFloat)B alpha:(CGFloat)alpha
{
	CGFloat cmp[4] = { R, G, B, alpha };
	return [self colorWithType:WDColorTypeRGB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithH:(CGFloat)H S:(CGFloat)S B:(CGFloat)B
{ return [self colorWithH:H S:S B:B alpha:1.0]; }

+ (id) colorWithH:(CGFloat)H S:(CGFloat)S B:(CGFloat)B alpha:(CGFloat)alpha
{
	CGFloat cmp[4] = {
		H / 360.0,
		S / 100.0,
		B / 100.0,
		alpha };

	return [self colorWithType:WDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithL:(CGFloat)L a:(CGFloat)a b:(CGFloat)b
{ return [self colorWithL:L a:a b:b alpha:1.0]; }

+ (id) colorWithL:(CGFloat)L a:(CGFloat)a b:(CGFloat)b alpha:(CGFloat)alpha
{
	CGFloat cmp[4] = {
		(L / 100.0),
		(a / 300.0) + 0.5,
		(b / 300.0) + 0.5,
		alpha };

	return [self colorWithType:WDColorTypeLab components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithL:(CGFloat)L C:(CGFloat)C H:(CGFloat)H
{ return [self colorWithL:L C:C H:H alpha:1.0]; }

+ (id) colorWithL:(CGFloat)L C:(CGFloat)C H:(CGFloat)H alpha:(CGFloat)alpha
{
	CGFloat cmp[4] = {
		L / 100.0,
		C / 150.0,
		H / 360.0,
		alpha };

	return [self colorWithType:WDColorTypeLCH components:cmp];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Extended Value Getters
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
	return cmp[1] * 300 - 150;
}

- (CGFloat) lab_b
{
	CGFloat cmp[4];
	[self getLAB:cmp];
	return cmp[2] * 300 - 150;
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
	return cmp[1] * 150;
}

- (CGFloat) lch_H
{
	CGFloat cmp[4];
	[self getLCH:cmp];
	return cmp[2] * 360;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIKit synchronisation
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

+ (id) colorWithHue:(CGFloat)hue
{
	CGFloat cmp[] = { hue, 1.0, 1.0, 1.0 };
	return [self colorWithType:WDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithUIColor:(UIColor *)color
{
	return [self colorWithRed:[color red]
	green:[color green] blue:[color blue] alpha:[color alpha]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
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

- (void) set
{ [[self UIColor] set]; }

- (void) setFill
{ [[self UIColor] setFill]; }

- (void) setStroke
{ [[self UIColor] setStroke]; }

- (void) setFillColorInContext:(CGContextRef)ctx
{ CGContextSetFillColorWithColor(ctx, self.CGColor); }

- (void) setStrokeColorInContext:(CGContextRef)ctx
{ CGContextSetStrokeColorWithColor(ctx, self.CGColor); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
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

+ (NSArray *) hueGradientHSB
{
	static const CGFloat S = 100.0;
	static const CGFloat B = 100.0;

	static NSArray *gHueGradient = nil;
	if (gHueGradient == nil)
	 	gHueGradient = @[
		[self colorWithH:0.0 S:S B:B],
		[self colorWithH:60.0 S:S B:B],
		[self colorWithH:120.0 S:S B:B],
		[self colorWithH:180.0 S:S B:B],
		[self colorWithH:240.0 S:S B:B],
		[self colorWithH:300.0 S:S B:B],
		[self colorWithH:360.0 S:S B:B]];

	return gHueGradient;
}

////////////////////////////////////////////////////////////////////////////////

+ (NSArray *) hueGradientLCH
{
	static const CGFloat L = 100.0;
	static const CGFloat C = 100.0;
	// Actual range of C may exceed 120...

	static NSArray *gHueGradient = nil;
	if (gHueGradient == nil)
	 	gHueGradient = @[
		[self colorWithL:L C:C H:0.0],
		
		[self colorWithL:L C:C H:15.0],
		[self colorWithL:L C:C H:30.0],
		[self colorWithL:L C:C H:45.0],
		[self colorWithL:L C:C H:60.0],
		[self colorWithL:L C:C H:75.0],
		[self colorWithL:L C:C H:90.0],

		[self colorWithL:L C:C H:105.0],
		[self colorWithL:L C:C H:120.0],
		[self colorWithL:L C:C H:135.0],
		[self colorWithL:L C:C H:150.0],
		[self colorWithL:L C:C H:165.0],
		[self colorWithL:L C:C H:180.0],

		[self colorWithL:L C:C H:195.0],
		[self colorWithL:L C:C H:210.0],
		[self colorWithL:L C:C H:225.0],
		[self colorWithL:L C:C H:240.0],
		[self colorWithL:L C:C H:255.0],
		[self colorWithL:L C:C H:270.0],

		[self colorWithL:L C:C H:285.0],
		[self colorWithL:L C:C H:300.0],
		[self colorWithL:L C:C H:315.0],
		[self colorWithL:L C:C H:330.0],
		[self colorWithL:L C:C H:345.0],
		[self colorWithL:L C:C H:360.0]];

	return gHueGradient;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) gradientForComponentAtIndex:(int)index
{
	id color = [self colorWithAlphaComponent:1.0];

	if ((mType == WDColorTypeLCH)&&(index == 2))
	{
		return @[
		[color colorWithComponentValue:0.0/360 atIndex:index],
		
		[color colorWithComponentValue:15.0/360 atIndex:index],
		[color colorWithComponentValue:30.0/360 atIndex:index],
		[color colorWithComponentValue:45.0/360 atIndex:index],
		[color colorWithComponentValue:60.0/360 atIndex:index],
		[color colorWithComponentValue:75.0/360 atIndex:index],
		[color colorWithComponentValue:90.0/360 atIndex:index],

		[color colorWithComponentValue:105.0/360 atIndex:index],
		[color colorWithComponentValue:120.0/360 atIndex:index],
		[color colorWithComponentValue:135.0/360 atIndex:index],
		[color colorWithComponentValue:150.0/360 atIndex:index],
		[color colorWithComponentValue:165.0/360 atIndex:index],
		[color colorWithComponentValue:180.0/360 atIndex:index],

		[color colorWithComponentValue:195.0/360 atIndex:index],
		[color colorWithComponentValue:210.0/360 atIndex:index],
		[color colorWithComponentValue:225.0/360 atIndex:index],
		[color colorWithComponentValue:240.0/360 atIndex:index],
		[color colorWithComponentValue:255.0/360 atIndex:index],
		[color colorWithComponentValue:270.0/360 atIndex:index],

		[color colorWithComponentValue:285.0/360 atIndex:index],
		[color colorWithComponentValue:300.0/360 atIndex:index],
		[color colorWithComponentValue:315.0/360 atIndex:index],
		[color colorWithComponentValue:330.0/360 atIndex:index],
		[color colorWithComponentValue:345.0/360 atIndex:index],
		[color colorWithComponentValue:360.0/360 atIndex:index]];
	}

	if ((mType == WDColorTypeLab)||
		(mType == WDColorTypeLCH))
	{
		return @[
		[color colorWithComponentValue:0.0 atIndex:index],
		[color colorWithComponentValue:0.1 atIndex:index],
		[color colorWithComponentValue:0.2 atIndex:index],
		[color colorWithComponentValue:0.3 atIndex:index],
		[color colorWithComponentValue:0.4 atIndex:index],
		[color colorWithComponentValue:0.5 atIndex:index],
		[color colorWithComponentValue:0.6 atIndex:index],
		[color colorWithComponentValue:0.7 atIndex:index],
		[color colorWithComponentValue:0.8 atIndex:index],
		[color colorWithComponentValue:0.9 atIndex:index],
		[color colorWithComponentValue:1.0 atIndex:index]];
	}

	if (mType == WDColorTypeHSB)
	{
		if (index == 0)
		{ return [[self class] hueGradientHSB]; }
	}

	return @[
	[color colorWithComponentValue:0.0 atIndex:index],
	[color colorWithComponentValue:1.0 atIndex:index]];
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

- (BOOL) visible
{ return mComponent[3] > 0.0; }

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

////////////////////////////////////////////////////////////////////////////////

+ (WDColor *) blackColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:0.0 G:0.0 B:0.0]);
}

+ (WDColor *) grayColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:0.5 G:0.5 B:0.5]);
//	return [WDColor colorWithHue:0.0f saturation:0.0f brightness:0.25f alpha:1.0f];
}

+ (WDColor *) whiteColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:1.0 G:1.0 B:1.0]);
}

+ (WDColor *) redColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:1.0 G:0.0 B:0.0]);
}

+ (WDColor *) yellowColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:1.0 G:1.0 B:0.0]);
}

+ (WDColor *) greenColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:0.0 G:1.0 B:0.0]);
}

+ (WDColor *) cyanColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:0.0 G:1.0 B:1.0]);
}

+ (WDColor *) blueColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:0.0 G:0.0 B:1.0]);
}

+ (WDColor *) magentaColor
{
	static id gColor = nil;
	return gColor ? gColor :
	(gColor = [WDColor colorWithR:1.0 G:0.0 B:1.0]);
}

////////////////////////////////////////////////////////////////////////////////




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

	return [WDColor colorWithType:self.type components:src];
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
	if (self.alpha < 1.0)
	{ WDDrawTransparencyDiamondInRect(ctx, rect); }
	
	CGContextSetFillColorWithColor(ctx, self.CGColor);
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
