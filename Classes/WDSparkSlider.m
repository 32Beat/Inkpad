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

////////////////////////////////////////////////////////////////////////////////
@implementation WDSparkSlider
////////////////////////////////////////////////////////////////////////////////
// Need to synthesize these because of namespace collision with system

@synthesize value = mValue;
@synthesize minValue = mMinValue;
@synthesize maxValue = mMaxValue;

////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib
{
	self.opaque = NO;
	self.backgroundColor = nil;
	
	// set up the label that indicates the current value
	CGRect frame = self.bounds;
	frame.size.height = kValueLabelHeight;
	_valueLabel = [[UILabel alloc] initWithFrame:frame];
	
	self.valueLabel.opaque = NO;
	self.valueLabel.backgroundColor = nil;
	self.valueLabel.text = @"0 pt";
	self.valueLabel.font = [UIFont systemFontOfSize:17];
	self.valueLabel.textColor = [UIColor blackColor];
	self.valueLabel.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:self.valueLabel];
	
	// set up the title label
	frame = self.bounds;
	frame.origin.y = CGRectGetMaxY(frame) - kTitleLabelHeight;
	frame.size.height = kTitleLabelHeight;
	
	_titleLabel = [[UILabel alloc] initWithFrame:frame];
	
	self.titleLabel.opaque = NO;
	self.titleLabel.backgroundColor = nil;
	self.titleLabel.font = [UIFont systemFontOfSize:13];
	self.titleLabel.textColor = [UIColor darkGrayColor];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	
	[self addSubview:self.titleLabel];

	self.maxValue = 100;
}

////////////////////////////////////////////////////////////////////////////////
// Return bounds of actual slider track
- (CGRect) trackRect
{
	CGRect  trackRect = self.bounds;
	
	trackRect.origin.y += kValueLabelHeight;
	trackRect.size.height -= kValueLabelHeight;
	trackRect.size.height -= kTitleLabelHeight;

	trackRect = CGRectInset(trackRect, kBarInset, 0);
	
	trackRect.origin.y = WDCenterOfRect(trackRect).y - 1.0;
	trackRect.size.height = 2.0;

	trackRect.origin.x = round(trackRect.origin.x);
	trackRect.origin.y = round(trackRect.origin.y);

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
	{ return self.minValue; }
	if (x >= CGRectGetMaxX(R))
	{ return self.maxValue; }

	CGFloat r = (x-CGRectGetMinX(R)) / R.size.width;
	return self.minValue + r * (self.maxValue-self.minValue);
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) locationForValue:(CGFloat)value inRect:(CGRect)R
{
	if (value <= self.minValue)
	{ return CGRectGetMinX(R); }
	if (value >= self.maxValue)
	{ return CGRectGetMaxX(R); }

	CGFloat r = (value - self.minValue) / (self.maxValue - self.minValue);
	return CGRectGetMinX(R) + r * R.size.width;
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(CGRect)rect
{
	CGContextRef    ctx = UIGraphicsGetCurrentContext();
	CGRect          trackRect = [self trackRect];
	
	// gray track backround
	[[UIColor lightGrayColor] set];
	CGContextFillRect(ctx, trackRect);

	if ([self isEnabled])
	{ [[UIColor blackColor] set]; }

	// "progress" bar
	trackRect.size.width *= mValue;
	CGContextFillRect(ctx, trackRect);

	CGFloat knobX = round(CGRectGetMaxX(trackRect))-3;
	CGFloat knobY = round(CGRectGetMinY(trackRect))+1-3;
	CGRect knobR = { knobX, knobY, 6, 6 };
	CGContextFillRect(ctx, knobR);

	if ([self isTracking])
	{
		knobR = CGRectInset(knobR, 1, 1);
		[[UIColor whiteColor] set];
		CGContextFillRect(ctx, knobR);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (NSNumber *) numberValue
{ return @((int)self.value); }

////////////////////////////////////////////////////////////////////////////////
/*
	value is internally kept as a relative value,
	this allows min and max to change without affecting 
	progress indication
*/

- (float) value
{ return self.minValue + mValue * (self.maxValue - self.minValue); }

- (void) setValue:(float)value
{
	CGFloat minValue = self.minValue;
	CGFloat maxValue = self.maxValue;

	value = minValue < maxValue ?
	(value - minValue) / (maxValue - minValue) : 0.5;

	if (value < 0.0) value = 0.0;
	if (value > 1.0) value = 1.0;

	if (mValue != value)
	{
		mValue = value;
		[self setNeedsDisplay];
		[self updateLabel];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setMinValue:(float)value
{
	if (mMinValue != value)
	{
		mMinValue = value;
		[self setEnabled:mMinValue < mMaxValue];
		[self setNeedsDisplay];
		[self updateLabel];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setMaxValue:(float)value
{
	if (mMaxValue != value)
	{
		mMaxValue = value;
		[self setEnabled:mMinValue < mMaxValue];
		[self setNeedsDisplay];
		[self updateLabel];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateLabel
{
	self.valueLabel.text =
	[NSString stringWithFormat:@"%d pt", (int)round(self.value)];
/*
	self.valueLabel.text = self.maxValue > 1.0 ?
	[NSString stringWithFormat:@"%d pt", (int)round(self.value)]:
	[NSString stringWithFormat:@"%d%%", (int)round(self.value*100)];
*/
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.minValue != self.maxValue)
	{
		mTouchOffset = [touch locationInView:self].x -
		[self trackingLocationForValue:self.value];

		[self setNeedsDisplay];
		// Display will be serviced after call below which sets tracking ivar
		return [super beginTrackingWithTouch:touch withEvent:event];
	}

	return NO;
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

	// Will call actions for TouchUp events and adjust tracking ivar
	[super endTrackingWithTouch:touch withEvent:event];

	// Need to call action for UIControlEventValueChanged in case someone listens
	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	[super cancelTrackingWithEvent:event];
	[self setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


