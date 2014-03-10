////////////////////////////////////////////////////////////////////////////////
/*
	WDColorSlider.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColorSlider.h"
#import "WDColorIndicator.h"

#import "WDUtilities.h"
#import "UIImage+Additions.h"

////////////////////////////////////////////////////////////////////////////////
@interface  WDColorSlider ()

// Indicator management
@property (nonatomic, weak) WDColorIndicator *indicator;
- (void) prepareIndicator;
- (void) updateIndicator;
- (void) updateIndicatorColor;
- (void) updateIndicatorPosition;

@end
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@implementation WDColorSlider
////////////////////////////////////////////////////////////////////////////////

@synthesize color = mColor;
@synthesize value = mValue;

////////////////////////////////////////////////////////////////////////////////

+ (Class) layerClass
{ return [CAGradientLayer class]; }

////////////////////////////////////////////////////////////////////////////////
// Convenience getter for self.layer

- (CAGradientLayer *) gradientLayer
{ return (CAGradientLayer *)self.layer; }

////////////////////////////////////////////////////////////////////////////////

- (void) setTrackGradient:(NSArray *)colors
{
	[self _setTrackGradient:colors];
	[self setDynamicTrackGradient:NO];
}

////////////////////////////////////////////////////////////////////////////////

- (void) _setTrackGradient:(NSArray *)colors
{
	NSMutableArray *cgColors = [NSMutableArray new];

	for (WDColor *color in colors)
	{ [cgColors addObject:(id)color.CGColor]; }

	[[self gradientLayer] setColors:cgColors];
}

/*
	If gradientLayer is a sublayer instead of backinglayer,
	then changes will be animated. Following code allows 
	duration control for this animation

- (void) setTrackGradient:(NSArray *)colors
	withAnimationDuration:(NSTimeInterval)time
{
	NSMutableArray *cgColors = [NSMutableArray new];

	for (WDColor *color in colors)
	{ [cgColors addObject:(id)color.CGColor]; }

	[CATransaction begin];
	[CATransaction setAnimationDuration:desiredDuration];
	[[self gradientLayer] setColors:cgColors];
	[CATransaction commit];
}
*/
////////////////////////////////////////////////////////////////////////////////

- (CGColorRef) defaultBackgroundPattern
{
	static UIColor *gPatternColor = nil;
	if (gPatternColor == nil)
	{
		gPatternColor = [[UIColor alloc]
		initWithPatternImage:[UIImage checkerBoardPattern]];
	}

	return gPatternColor.CGColor;
}

////////////////////////////////////////////////////////////////////////////////

- (CGColorRef) defaultBorderColor
{
	static UIColor *gBorderColor = nil;
	if (gBorderColor == nil)
	{
		gBorderColor = [[UIColor alloc]
		initWithWhite:0.0 alpha:0.1];
	}

	return gBorderColor.CGColor;
}

////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib
{
	self.opaque = NO;
	self.minValue = 0.0;
	self.maxValue = 1.0;

	[self prepareTrack];
	[self prepareIndicator];
}

////////////////////////////////////////////////////////////////////////////////
/*
	prepareTrack
	------------
	Prepare backing layer to display gradients
	
	Backinglayer can't display both gradient and border, 
	because border will be drawn over any content including indicator image. 
	We therefore use an additional layer to draw border, suggesting we might 
	as well draw the entire track in this layer.
	
	A sublayer however will mean implicit animations, and the border can
	only be a simple stroke.
*/

- (void) prepareTrack
{
	self.dynamicTrackGradient = YES;

	// Set checkerboard background
	self.gradientLayer.backgroundColor = self.defaultBackgroundPattern;
	self.gradientLayer.cornerRadius = 0.5*self.bounds.size.height;
	self.gradientLayer.startPoint = (CGPoint){ 0.0, 0.0 };
	self.gradientLayer.endPoint = (CGPoint){ 1.0, 0.0 };

	[self prepareBorder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareBorder
{
	CALayer *border = [CALayer layer];
	border.frame = [self bounds];
	border.cornerRadius = 0.5*self.bounds.size.height;
	border.borderColor = self.defaultBorderColor;
	border.borderWidth = 1.0;
	[self.layer addSublayer:border];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{
	mColor = color;

	// NOTE: currently assumes component is normalized
	mValue = [color componentAtIndex:self.componentIndex];

	[self updateIndicator];

	// Update trackGradient if necessary
	if (self.dynamicTrackGradient)
		[self _setTrackGradient:
		[color gradientForComponentAtIndex:self.componentIndex]];

	[self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setComponentIndex:(int)index
{
	_componentIndex = index;
	self.indicator.showsAlpha = (index == 3);
	[self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) trackingRect
{ return CGRectInset(self.bounds, self.bounds.size.height/2.0, 0); }

////////////////////////////////////////////////////////////////////////////////

- (float) value
{ return self.minValue + mValue * (self.maxValue - self.minValue); }

////////////////////////////////////////////////////////////////////////////////

- (void) setValue:(float)value
{
	mValue = (self.maxValue <= self.minValue) ? 0.5 :
	(value - self.minValue) / (self.maxValue - self.minValue);
}

////////////////////////////////////////////////////////////////////////////////

- (void) _setValue:(float)value
{
	if (mValue != value)
	{
		mValue = value;
		[self updateIndicatorPosition];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (float) floatValue
{ return self.minValue + mValue * (self.maxValue - self.minValue); }

////////////////////////////////////////////////////////////////////////////////

- (void) setFloatValue:(float)value
{
	mValue = (self.maxValue <= self.minValue) ? 0.5 :
	(value - self.minValue) / (self.maxValue - self.minValue);
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) locationForValue:(float)value
{
	CGRect trackRect = self.trackingRect;
	CGFloat X = CGRectGetMinX(trackRect) + value * CGRectGetWidth(trackRect);
	return round(X);
}

////////////////////////////////////////////////////////////////////////////////

- (float) valueForLocation:(CGPoint)pt
{
	CGRect trackRect = self.trackingRect;
	float value;
	
	value = (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
	value = WDClamp(0.0f, 1.0f, value);

	return value;
}

////////////////////////////////////////////////////////////////////////////////

- (float) valueForTouch:(UITouch *)touch
{ return [self valueForLocation:[touch locationInView:self]]; }

////////////////////////////////////////////////////////////////////////////////

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	return CGRectContainsPoint(self.bounds, point);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self _setValue:[self valueForTouch:touch]];
	return [super beginTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self _setValue:[self valueForTouch:touch]];
	return [super continueTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self _setValue:[self valueForTouch:touch]];
	[super endTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Indicator Management
////////////////////////////////////////////////////////////////////////////////
/*
	prepareIndicator
	----------------
	Create a  color indicator subview
	
	Note that the indicator ivar is weak. Assigning the colorindicator 
	to self.indicator prior to adding as subview seems to result in 
	a prematurely released ivar on 64bit system.
*/

- (void) prepareIndicator
{
	self.dynamicIndicatorColor = YES;

	// Assign strong before weak
	WDColorIndicator *indicator = [WDColorIndicator colorIndicator];
	indicator.center = WDCenterOfRect([self bounds]);
	indicator.center = WDRoundPoint(indicator.center);
	[self addSubview:indicator];
	self.indicator = indicator;
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateIndicator
{
	// Update indicatorColor if necessary
	if (self.dynamicIndicatorColor)
	{ [self updateIndicatorColor]; }
	[self updateIndicatorPosition];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateIndicatorColor
{
	WDColor *color = self.color;

	if (color.type == WDColorTypeHSB)
	{
		if (self.componentIndex == 0)
		{ color = [WDColor colorWithH:color.hsb_H S:100.0 B:100.0]; }
	}
	else
	if (color.type == WDColorTypeLCH)
	{
		if (self.componentIndex == 2)
		{ color = [WDColor colorWithL:100.0 C:100.0 H:color.lch_H]; }
	}

	[self.indicator setColor:color];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateIndicatorPosition
{
	CGPoint P = self.indicator.center;
	P.x = [self locationForValue:mValue];
	self.indicator.center = P;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




