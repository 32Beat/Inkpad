//
//  WDShadow.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDColor.h"
#import "WDShadow.h"
#import "WDXMLElement.h"

NSString *_WDShadowColorKey = @"WDShadowColorKey";
NSString *_WDShadowOffsetKey = @"WDShadowOffsetKey";
NSString *_WDShadowRadiusKey = @"WDShadowRadiusKey";
NSString *_WDShadowAngleKey = @"WDShadowAngleKey";

@implementation WDShadow

@synthesize color = color_;
@synthesize radius = radius_;
@synthesize offset = offset_;
@synthesize angle = angle_;


+ (WDShadow *) shadowWithColor:(WDColor *)color radius:(float)radius offset:(float)offset angle:(float)angle
{
    WDShadow *shadow = [[WDShadow alloc] initWithColor:color radius:radius offset:offset angle:angle];
    return shadow;
}

- (id) initWithColor:(WDColor *)color radius:(float)radius offset:(float)offset angle:(float)angle
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    color_ = color;
    radius_ = radius;
    offset_ = offset;
    angle_ = angle;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:color_ forKey:_WDShadowColorKey];
    [coder encodeFloat:radius_ forKey:_WDShadowRadiusKey];
    [coder encodeFloat:offset_ forKey:_WDShadowOffsetKey];
    [coder encodeFloat:angle_ forKey:_WDShadowAngleKey];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    color_ = [coder decodeObjectForKey:_WDShadowColorKey];
    radius_ = [coder decodeFloatForKey:_WDShadowRadiusKey];
    offset_ = [coder decodeFloatForKey:_WDShadowOffsetKey];
    angle_ = [coder decodeFloatForKey:_WDShadowAngleKey]; 
    
    return self; 
}

- (BOOL) isEqual:(WDShadow *)shadow
{
    if (shadow == self) {
        return YES;
    }
    
    if (![shadow isKindOfClass:[WDShadow class]]) {
        return NO;
    }
    
    return ((radius_ == shadow.radius) && (offset_ == shadow.offset) && (angle_ == shadow.angle) && [color_ isEqual:shadow.color]);
}


- (CGVector) offsetVector
{
	CGVector V = (CGVector){
	self.offset * cos(self.angle),
	self.offset * sin(self.angle) };

	return V;
}

- (CGRect) shadowAreaForRect:(CGRect)R
{
	// Expand by blur radius
	CGFloat r = ceil(self.radius);
	R = CGRectInset(R, -r, -r);

	// Move by offset
	CGVector V = [self offsetVector];
	R = CGRectOffset(R, V.dx, V.dy);

	return R;
}

- (CGRect) expandRenderArea:(CGRect)R
{
	return CGRectUnion(R, [self shadowAreaForRect:R]);
}


- (CGRect) __expandStyleBounds:(CGRect)srcR
{
	// Move by offset
	CGVector V = [self offsetVector];
	CGRect R = CGRectOffset(srcR, V.dx, V.dy);
	// Expand by blur radius
	R = CGRectInset(R, -self.radius, -self.radius);

	return CGRectUnion(srcR, R);
}


- (void) applyInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
    float x = cos(angle_) * offset_ * metaData.scale;
    float y = sin(angle_) * offset_ * metaData.scale;
    
#if !TARGET_OS_IPHONE
    y *= -1;
#endif
    
    if (metaData.flags & WDRenderFlipped) {
        y *= -1;
    }
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(x,y), radius_ * metaData.scale, color_.CGColor);
}

- (WDShadow *) adjustColor:(WDColor * (^)(WDColor *color))adjustment
{
    return [WDShadow shadowWithColor:[self.color adjustColor:adjustment] radius:self.radius offset:self.offset angle:self.angle];
}

- (void) addSVGAttributes:(WDXMLElement *)element
{
    [element setAttribute:@"inkpad:shadowColor" value:[self.color hexValue]];
    [element setAttribute:@"inkpad:shadowOpacity" floatValue:[self.color alpha]];
    [element setAttribute:@"inkpad:shadowRadius" floatValue:self.radius];
    [element setAttribute:@"inkpad:shadowOffset" floatValue:self.offset];
    [element setAttribute:@"inkpad:shadowAngle" floatValue:self.angle];
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

@end
