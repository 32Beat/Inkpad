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
#import "WDUtilities.h"
#import "WDColorIndicator.h"
#import "WDColor.h"
#import "UIView+Additions.h"
#import "UIImage+Additions.h"


#define kCornerRadius   10
#define kIndicatorInset 10

@interface  WDColorSlider (Private)
- (void) positionIndicator_;
@end


////////////////////////////////////////////////////////////////////////////////
@implementation WDColorSlider
////////////////////////////////////////////////////////////////////////////////

@synthesize floatValue = value_;
@synthesize color = color_;
@synthesize reversed = reversed_;
@synthesize indicator = indicator_;

////////////////////////////////////////////////////////////////////////////////

+ (Class) layerClass
{ return [CAGradientLayer class]; }

////////////////////////////////////////////////////////////////////////////////
// Convenience getter for self.layer

- (CAGradientLayer *) gradientLayer
{ return (CAGradientLayer *)self.layer; }

////////////////////////////////////////////////////////////////////////////////

- (void) setGradientColors:(NSArray *)colors
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

- (void) setGradientColors:(NSArray *)colors
	withAnimationDuration:(NSTimeInterval)time
{
	NSMutableArray *cgColors = [NSMutableArray new];

	for (WDColor *color in colors)
	{ [cgColors addObject:(id)color.CGColor]; }

	[[self gradientLayer] setColors:cgColors];

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
	indicator_ = [WDColorIndicator colorIndicator];
	indicator_.sharpCenter = WDCenterOfRect([self bounds]);
	[self addSubview:indicator_];
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


- (void) setColor:(WDColor *)color
{
	color_ = color;
	value_ = [color componentAtIndex:self.componentIndex];

	[self setGradientColors:
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

	[indicator_ setColor:color];
	[self positionIndicator_];
	[self setNeedsDisplay];
}

- (void) setComponentIndex:(int)index
{
	_componentIndex = index;
	indicator_.alphaMode = (index == 3);
	[self setNeedsDisplay];
}

- (void) setReversed:(BOOL)reversed
{
	reversed_ = reversed;
	[self setNeedsDisplay];
}

- (UIImage *) borderImage
{
	static UIImage *borderImage = nil;
	
	if (borderImage && !CGSizeEqualToSize(borderImage.size, self.bounds.size)) {
		borderImage = nil;
	}
	
	if (!borderImage) {
		borderImage = [UIImage imageNamed:@"slider_border.png"];
		borderImage = [borderImage stretchableImageWithLeftCapWidth:16 topCapHeight:0];
		
		UIGraphicsBeginImageContextWithOptions([self bounds].size, NO, 0);
		[borderImage drawInRect:[self bounds]];
		borderImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	
	return borderImage;
}


- (float) indicatorCenterX_
{
	CGRect  trackRect = CGRectInset(self.bounds, kIndicatorInset, 0);
	
	return roundf(value_ * CGRectGetWidth(trackRect) + CGRectGetMinX(trackRect));
}

- (void) computeValue_:(CGPoint)pt
{
	CGRect  trackRect = CGRectInset(self.bounds, kIndicatorInset, 0);
	float   percentage;
	
	percentage = (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
	percentage = WDClamp(0.0f, 1.0f, percentage);
	
	value_ = percentage;
	[self setNeedsDisplay];
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];
	
	[self computeValue_:pt];
	[self positionIndicator_];
	
	return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];

	[self computeValue_:pt];
	[self positionIndicator_];
	
	return [super continueTrackingWithTouch:touch withEvent:event];
}

@end

@implementation WDColorSlider (Private)

- (void) positionIndicator_
{
	indicator_.sharpCenter =
	CGPointMake([self indicatorCenterX_], indicator_.center.y);
}

@end
