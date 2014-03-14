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
	CGFloat mValue;
}

- (void) setValue:(CGFloat)value;

// Track management
- (void) prepareTrack;
- (void) prepareBorder;
- (void) updateTrack;

// Indicator management
@property (nonatomic, weak) WDColorIndicator *indicator;
- (void) prepareIndicator;
- (void) updateIndicator;
- (void) updateIndicatorColor;
- (void) updateIndicatorPosition;

- (id) indicatorColor;
- (CGPoint) indicatorPosition;

@end
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@implementation WDColorSlider
////////////////////////////////////////////////////////////////////////////////

@synthesize color = mColor;

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

+ (Class) layerClass
{ return [CAGradientLayer class]; }

////////////////////////////////////////////////////////////////////////////////
// Convenience getter for self.layer

- (CAGradientLayer *) gradientLayer
{ return (CAGradientLayer *)self.layer; }

////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib
{
	self.opaque = NO;
	[self prepareTrack];
	[self prepareIndicator];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setColor:(WDColor *)color
{
	mColor = color;
	mValue = [color componentAtIndex:self.componentIndex];

	[self updateTrack];
	[self updateIndicator];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setValue:(CGFloat)value
{
	mValue = WDClamp(0.0, 1.0, value);
	[self updateIndicatorPosition];
}

////////////////////////////////////////////////////////////////////////////////

- (float) floatValue
{ return mValue; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGRect) trackingRect
{ return CGRectInset(self.bounds, self.bounds.size.height/2.0, 0); }

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) locationForValue:(float)value
{
	CGRect trackRect = self.trackingRect;
	CGFloat x = CGRectGetMinX(trackRect) + value * CGRectGetWidth(trackRect);
	CGFloat y = CGRectGetMidY(trackRect);
	return (CGPoint){ round(x), round(y) };
}

////////////////////////////////////////////////////////////////////////////////

- (float) valueForLocation:(CGPoint)pt
{
	CGRect trackRect = self.trackingRect;
	return (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
}

////////////////////////////////////////////////////////////////////////////////

- (float) valueForTouch:(UITouch *)touch
{ return [self valueForLocation:[touch locationInView:self]]; }

////////////////////////////////////////////////////////////////////////////////
// Overwrite hittest in order to ignore indicator hits

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{ return [self pointInside:point withEvent:event] ? self : nil; }

////////////////////////////////////////////////////////////////////////////////

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self setValue:[self valueForTouch:touch]];
	return [super beginTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self setValue:[self valueForTouch:touch]];
	return [super continueTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self setValue:[self valueForTouch:touch]];
	[super endTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Track Management
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
	self.gradientLayer.backgroundColor = self.trackBackgroundPattern;
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
	border.borderColor = self.trackBorderColor;
	border.borderWidth = 1.0;
	[self.layer addSublayer:border];
}

////////////////////////////////////////////////////////////////////////////////

- (CGColorRef) trackBackgroundPattern
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

- (CGColorRef) trackBorderColor
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

- (void) updateTrack
{
	// Update trackGradient if necessary
	if (self.dynamicTrackGradient)
		[self setTrackGradient:
		[self.color gradientForComponentAtIndex:self.componentIndex]];
}

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
{ [self.indicator setColor:[self indicatorColor]]; }

////////////////////////////////////////////////////////////////////////////////

- (void) updateIndicatorPosition
{ [self.indicator setCenter:[self indicatorPosition]]; }

////////////////////////////////////////////////////////////////////////////////

- (id) indicatorColor
{
	return self.componentIndex == 3 ? self.color :
	[self.color colorWithAlphaComponent:1.0];
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) indicatorPosition
{ return [self locationForValue:mValue]; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




