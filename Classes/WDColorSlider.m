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
{
	float mValue;
}

// Indicator management
@property (nonatomic, weak) WDColorIndicator *indicator;
- (void) _updateIndicatorColor;
- (void) _updateIndicatorPosition;

@end
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@implementation WDColorSlider
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

- (CGColorRef) defaultPattern
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
	[self prepareTrack];
	[self prepareIndicator];

	self.minValue = 0.0;
	self.maxValue = 1.0;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareIndicator
{
	self.dynamicIndicatorColor = YES;

	self.indicator = [WDColorIndicator colorIndicator];
	self.indicator.center = WDCenterOfRect([self bounds]);
	[self addSubview:self.indicator];
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
	self.gradientLayer.backgroundColor = self.defaultPattern;
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

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	CGRect bounds = CGRectInset(self.bounds, -10, -10);
	return CGRectContainsPoint(bounds, point);
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{
	_color = color;
	self.floatValue = [color componentAtIndex:self.componentIndex];

	// Update trackGradient if necessary
	if (self.dynamicTrackGradient)
		[self setTrackGradient:
		[color gradientForComponentAtIndex:self.componentIndex]];

	if (self.reversed)
	{ color = [color colorWithAlphaComponent:(1.0f - color.alpha)]; }
	else
	if (color.type == WDColorTypeHSB)
	{
		if (self.componentIndex == 0)
		{
			color = [WDColor colorWithHue:color.hue
			saturation:1 brightness:1 alpha:1];
		}
	}

	// Update indicatorColor if necessary
	if (self.dynamicIndicatorColor)
	{ [self.indicator setColor:color]; }
	[self _updateIndicatorPosition];
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

- (float) indicatorCenterX_
{
	CGRect trackRect = self.trackingRect;
	return CGRectGetMinX(trackRect) + mValue * CGRectGetWidth(trackRect);
}

////////////////////////////////////////////////////////////////////////////////

- (void) setValue:(float)value
{ mValue = value; }

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

- (float) valueForLocation:(CGPoint)pt
{
	CGRect trackRect = self.trackingRect;
	float value;
	
	value = (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
	value = WDClamp(0.0f, 1.0f, value);

	return value;
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];
	
	[self setValue:[self valueForLocation:pt]];
	[self _updateIndicatorPosition];
	
	return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];

	[self setValue:[self valueForLocation:pt]];
	[self _updateIndicatorPosition];
	
	return [super continueTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void) _updateIndicatorColor
{
	// Update indicatorColor if necessary
	if (self.dynamicIndicatorColor)
	{ [self.indicator setColor:self.color]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) _updateIndicatorPosition
{
	self.indicator.center =
	CGPointMake([self indicatorCenterX_], self.indicator.center.y);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




