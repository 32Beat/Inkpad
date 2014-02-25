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

#if !TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "WDColor.h"
#import "WDPath.h"
#import "WDUtilities.h"

NSString *WDHueKey = @"WDHueKey";
NSString *WDSaturationKey = @"WDSaturationKey";
NSString *WDBrightnessKey = @"WDBrightnessKey";
NSString *WDAlphaKey = @"WDAlphaKey";

NSInteger const WDColorVersion = 1;
NSString *const WDColorVersionKey = @"WDColorVersion";
NSString *const WDColorTypeKey = @"WDColorType";
NSString *const WDColorComponentsKey = @"WDColorComponents";

////////////////////////////////////////////////////////////////////////////////
@implementation WDColor
////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithRGBA:(const CGFloat *)cmp
{ return [self colorWithType:kWDColorTypeRGB components:cmp]; }

+ (id) colorWithHSBA:(const CGFloat *)cmp
{ return [self colorWithType:kWDColorTypeHSB components:cmp]; }

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
	return [self colorWithType:kWDColorTypeRGB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithRed:(CGFloat)red
	green:(CGFloat)green
	blue:(CGFloat)blue
	alpha:(CGFloat)alpha
{
	CGFloat cmp[] = { red, green, blue, alpha };
	return [self colorWithType:kWDColorTypeRGB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithHue:(CGFloat)hue
	saturation:(CGFloat)saturation
	brightness:(CGFloat)brightness
	alpha:(CGFloat)alpha
{
	CGFloat cmp[] = { hue, saturation, brightness, alpha };
	return [self colorWithType:kWDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

- (id) colorWithAlphaComponent:(CGFloat)alpha
{
	CGFloat cmp[4] = {
		mComponent[0],
		mComponent[1],
		mComponent[2],
		alpha };

	return [[self class] colorWithType:mType components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) randomColor
{
	CGFloat cmp[4] = {
		WDRandomFloat(),
		WDRandomFloat(),
		WDRandomFloat(),
		0.5 + 0.5*WDRandomFloat() };

	return [self colorWithType:kWDColorTypeHSB components:cmp];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) colorWithUIColor:(UIColor *)color
{
	return [self colorWithRed:[color red]
	green:[color green] blue:[color blue] alpha:[color alpha]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) getRGBA:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	if (mType == kWDColorTypeHSB)
	{ HSVtoRGB(cmp[0], cmp[1], cmp[2], &cmp[0], &cmp[1], &cmp[2]); }
}

////////////////////////////////////////////////////////////////////////////////

- (void) getHSBA:(CGFloat *)cmp
{
	cmp[0] = mComponent[0];
	cmp[1] = mComponent[1];
	cmp[2] = mComponent[2];
	cmp[3] = mComponent[3];

	if (mType == kWDColorTypeRGB)
	{ RGBtoHSV(cmp[0], cmp[1], cmp[2], &cmp[0], &cmp[1], &cmp[2]); }
}

////////////////////////////////////////////////////////////////////////////////

- (id) colorWithColorType:(WDColorType)colorType
{
	if (mType == colorType)
	{ return self; }

	CGFloat cmp[4];
	if (colorType == kWDColorTypeHSB)
	{ [self getHSBA:cmp]; }
	else
	{ [self getRGBA:cmp]; }

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
	mType = kWDColorTypeHSB;
	mComponent[0] = [coder decodeFloatForKey:WDHueKey];
	mComponent[1] = [coder decodeFloatForKey:WDSaturationKey];
	mComponent[2] = [coder decodeFloatForKey:WDBrightnessKey];
	mComponent[3] = [coder decodeFloatForKey:WDAlphaKey];
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
	if (color == self) {
		return YES;
	}
	
	if (![color isKindOfClass:[WDColor class]]) {
		return NO;
	}
	
	return
	self->mType == color->mType &&
	self->mComponent[0] == color->mComponent[0] &&
	self->mComponent[1] == color->mComponent[1] &&
	self->mComponent[2] == color->mComponent[2] &&
	self->mComponent[3] == color->mComponent[3];
}

+ (WDColor *) colorWithDictionary:(NSDictionary *)dict
{
	float hue = [dict[@"hue"] floatValue];
	float saturation = [dict[@"saturation"] floatValue];
	float brightness = [dict[@"brightness"] floatValue];
	float alpha = [dict[@"alpha"] floatValue];
	
	return [WDColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
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
		[self getRGBA:cmp];
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

- (void) set
{ [[self UIColor] set]; }

////////////////////////////////////////////////////////////////////////////////

- (WDColor *) adjustColor:(WDColor * (^)(WDColor *color))adjustment
{
	return adjustment(self);
}

- (CGFloat) red
{
	CGFloat cmp[4];
	[self getRGBA:cmp];
	return cmp[0];
}

- (CGFloat) green
{
	CGFloat cmp[4];
	[self getRGBA:cmp];
	return cmp[1];
}

- (CGFloat) blue
{
	CGFloat cmp[4];
	[self getRGBA:cmp];
	return cmp[2];
}

- (CGFloat) alpha
{ return mComponent[3]; }

- (CGFloat) hue
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	return cmp[0];
}

- (CGFloat) saturation
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	return cmp[1];
}

- (CGFloat) brightness
{
	CGFloat cmp[4];
	[self getHSBA:cmp];
	return cmp[2];
}



- (WDColor *) colorBalanceRed:(float)rShift green:(float)gShift blue:(float)bShift
{
	CGFloat cmp[4];
	[self getRGBA:cmp];

	cmp[0] = WDClamp(0, 1, cmp[0] + rShift);
	cmp[1] = WDClamp(0, 1, cmp[1] + gShift);
	cmp[2] = WDClamp(0, 1, cmp[2] + bShift);

	return [[self class] colorWithType:kWDColorTypeRGB components:cmp];
}

- (WDColor *) adjustHue:(float)hShift
	saturation:(float)sShift
	brightness:(float)bShift
{
	CGFloat cmp[4];
	[self getHSBA:cmp];

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
	[self getRGBA:cmp];

	cmp[0] = 1.0 - cmp[0];
	cmp[1] = 1.0 - cmp[1];
	cmp[2] = 1.0 - cmp[2];

	return [[self class] colorWithType:kWDColorTypeRGB components:cmp];
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

	[self getRGBA:src];
	[color getRGBA:dst];

	src[0] += blend * (dst[0] - src[0]);
	src[1] += blend * (dst[1] - src[1]);
	src[2] += blend * (dst[2] - src[2]);
	src[3] += blend * (dst[3] - src[3]);

	return [WDColor colorWithType:kWDColorTypeRGB components:src];
}

- (NSString *) hexValue
{   
	CGFloat cmp[4];
	[self getRGBA:cmp];

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
