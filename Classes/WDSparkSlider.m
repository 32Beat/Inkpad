//
//  WDSparkSlider.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDSparkSlider.h"
#import "WDUtilities.h"
#import "UIView+Additions.h"

#define kValueLabelHeight   20
#define kTitleLabelHeight   18
#define kBarInset           8
#define kBarHeight          1
#define kDragDampening      1.5

@implementation WDSparkSlider

@synthesize title = title_;
@synthesize value = value_;
@synthesize minValue = minValue_;
@synthesize maxValue = maxValue_;

- (void) awakeFromNib
{
	self.opaque = NO;
	self.backgroundColor = nil;
	
	// set up the label that indicates the current value
	CGRect frame = self.bounds;
	frame.size.height = kValueLabelHeight;
	valueLabel_ = [[UILabel alloc] initWithFrame:frame];
	
	valueLabel_.opaque = NO;
	valueLabel_.backgroundColor = nil;
	valueLabel_.text = @"0 pt";
	valueLabel_.font = [UIFont systemFontOfSize:17];
	valueLabel_.textColor = [UIColor blackColor];
	valueLabel_.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:valueLabel_];
	
	// set up the title label
	frame = self.bounds;
	frame.origin.y = CGRectGetMaxY(frame) - kTitleLabelHeight;
	frame.size.height = kTitleLabelHeight;
	
	title_ = [[UILabel alloc] initWithFrame:frame];
	
	title_.opaque = NO;
	title_.backgroundColor = nil;
	title_.font = [UIFont systemFontOfSize:13];
	title_.textColor = [UIColor darkGrayColor];
	title_.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:title_];
	
	maxValue_ = 100;
}

////////////////////////////////////////////////////////////////////////////////
// Return bounds of actual slider track
- (CGRect) trackRect
{
	CGRect  trackRect = self.bounds;
	
	trackRect.origin.y += kValueLabelHeight;
	trackRect.size.height -= kValueLabelHeight + kTitleLabelHeight;
	trackRect = CGRectInset(trackRect, kBarInset, 0);
	
	trackRect.origin.y = WDCenterOfRect(trackRect).y;
	trackRect.size.height = kBarHeight;
	
	return trackRect;
}

////////////////////////////////////////////////////////////////////////////////
// Return bounds of virtual slider track
- (CGRect) trackingRect
{
	CGRect trackRect = self.trackRect;
	CGFloat expansion = 0.25*trackRect.size.width;

	return CGRectInset(trackRect, -expansion, 0);
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) valueForTrackingLocation:(CGFloat)x
{ return [self valueForLocation:x inRect:[self trackingRect]]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) trackingLocationForValue:(CGFloat)value
{ return [self locationForValue:value inRect:[self trackingRect]]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) locationForValue:(CGFloat)value
{ return [self locationForValue:value inRect:[self trackRect]]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) valueForLocation:(CGFloat)x inRect:(CGRect)R
{
	if (x <= CGRectGetMinX(R))
	{ return minValue_; }
	if (x >= CGRectGetMaxX(R))
	{ return maxValue_; }

	CGFloat r = (x-CGRectGetMinX(R)) / R.size.width;
	return minValue_ + r * (maxValue_-minValue_);
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) locationForValue:(CGFloat)value inRect:(CGRect)R
{
	if (value <= minValue_)
	{ return CGRectGetMinX(R); }
	if (value >= maxValue_)
	{ return CGRectGetMaxX(R); }

	CGFloat r = (value - minValue_) / (maxValue_ - minValue_);
	return CGRectGetMinX(R) + r * R.size.width;
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(CGRect)rect
{
	CGContextRef    ctx = UIGraphicsGetCurrentContext();
	CGRect          trackRect = [self trackRect];
	
	// gray track backround
	[[UIColor colorWithWhite:0.75f alpha:1.0f] set];
	CGContextFillRect(ctx, trackRect);
	
	// bottom highlight
	[[UIColor colorWithWhite:1 alpha:0.6] set];
	CGContextFillRect(ctx, CGRectOffset(trackRect, 0,1));
	
	// "progress" bar
	trackRect.size.width *= value_;
	[[UIColor blackColor] set];
	CGContextFillRect(ctx, trackRect);
}

- (void) updateIndicator
{
	if (!indicator_) {
		indicator_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spark_knob.png"]];
		[self addSubview:indicator_];
	}
		
	CGRect trackRect = CGRectInset([self trackRect], 2.5f, 0);
	CGFloat x = [self locationForValue:[self value] inRect:trackRect];

	indicator_.sharpCenter = CGPointMake(x, CGRectGetMidY(trackRect));
}





- (NSNumber *) numberValue
{
	return @((int)self.value);
}

- (CGFloat)value \
{ return minValue_ + value_ * (maxValue_ - minValue_); }


- (void) setValue:(float)value
{
	CGFloat minValue = self.minValue;
	CGFloat maxValue = self.maxValue;

	value = minValue < maxValue ?
	(value - minValue) / (maxValue - minValue) : 0.5;

	if (value < 0.0) value = 0.0;
	if (value > 1.0) value = 1.0;

	if (value == value_) {
		if (!indicator_) {
			// make sure we start in a good state
			[self updateIndicator];
		}
		
		return;
	}

	value_ = value;
	[self setNeedsDisplay];
	
	[self updateIndicator];
	
	[self updateLabel];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setMaxValue:(CGFloat)value
{
	if (maxValue_ != value)
	{
		maxValue_ = value;
		[self updateLabel];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateLabel
{
	valueLabel_.text = maxValue_ > 1.0 ?
	[NSString stringWithFormat:@"%d pt", (int)round(self.value)]:
	[NSString stringWithFormat:@"%d%%", (int)round(self.value*100)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	mTouchOffset = [touch locationInView:self].x -
	[self trackingLocationForValue:[self value]];
	
	dragging_ = YES;
	moved_ = NO;
	
	indicator_.image = [UIImage imageNamed:@"spark_knob_highlighted.png"];
	
	[self setNeedsDisplay];
	
	return [super beginTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];
	self.value = [self valueForTrackingLocation:pt.x - mTouchOffset];
	
	return [super continueTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];
	self.value = [self valueForTrackingLocation:pt.x - mTouchOffset];

	dragging_ = NO;
	indicator_.image = [UIImage imageNamed:@"spark_knob.png"];
	
	[super endTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	dragging_ = NO;
	indicator_.image = [UIImage imageNamed:@"spark_knob.png"];
	[self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


