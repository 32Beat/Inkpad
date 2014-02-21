////////////////////////////////////////////////////////////////////////////////
/*
	WDAnglePicker.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDAnglePicker.h"
#import "WDUtilities.h"

const float kArrowInset = 5;
const float kArrowDimension = 6;

////////////////////////////////////////////////////////////////////////////////
@implementation WDAnglePicker
////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib
{
	self.exclusiveTouch = YES;
	
	self.layer.shadowOpacity = 0.15f;
	self.layer.shadowRadius = 2;
	self.layer.shadowOffset = CGSizeMake(0, 2);
	
	CGMutablePathRef pathRef = CGPathCreateMutable();
	CGRect rect = CGRectInset(self.bounds, 1, 1);
	CGPathAddEllipseInRect(pathRef, NULL, rect);
	self.layer.shadowPath = pathRef;
	CGPathRelease(pathRef);
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(CGRect)rect
{
	CGContextRef    ctx = UIGraphicsGetCurrentContext();
	float           radius = CGRectGetWidth(self.bounds) / 2 - kArrowInset;
	CGPoint         center = WDCenterOfRect(self.bounds);
	CGRect          ellipseRect = CGRectInset(self.bounds, 1, 1);
	
	[[UIColor whiteColor] set];
	CGContextFillEllipseInRect(ctx, ellipseRect);
	
	[[UIColor lightGrayColor] set];
	CGContextSetLineWidth(ctx, 1.0 / [UIScreen mainScreen].scale);
	CGContextStrokeEllipseInRect(ctx, ellipseRect);
	
	// draw an arrow to indicate direction
	CGContextSaveGState(ctx);
	
	[[UIColor colorWithRed:0.0f green:(118.0f / 255.0f) blue:1.0f alpha:1.0f] set];
	CGContextSetLineCap(ctx, kCGLineCapRound);
	CGContextSetLineWidth(ctx, 2.0f);
	
	CGContextTranslateCTM(ctx, center.x, center.y);
	CGContextRotateCTM(ctx, [self angle]);
	
	CGContextMoveToPoint(ctx, 0, 0);
	CGContextAddLineToPoint(ctx, radius - 0.5f, 0);
	CGContextStrokePath(ctx);
	
	CGContextMoveToPoint(ctx, radius - kArrowDimension, kArrowDimension);
	CGContextAddLineToPoint(ctx, radius, 0);
	CGContextAddLineToPoint(ctx, radius - kArrowDimension, -kArrowDimension);
	CGContextStrokePath(ctx);
	
	CGContextRestoreGState(ctx);
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat)angle
{ return mAngle; }

- (void) setAngle:(CGFloat)angle
{
	angle = fmod(angle, 2*M_PI);
	if (mAngle != angle)
	{
		mAngle = angle;
		mDegrees = WDDegreesFromRadians(angle);
		[self setNeedsDisplay];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat)degrees
{ return mDegrees; }

- (void) setDegrees:(CGFloat)degrees
{
	degrees = fmod(degrees, 360.0);
	if (mDegrees != degrees)
	{
		mDegrees = degrees;
		mAngle = WDRadiansFromDegrees(degrees);
		[self setNeedsDisplay];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (CGFloat) angleForTouch:(UITouch *)touch
{
	CGPoint P = [touch locationInView:self];
	CGPoint C = WDCenterOfRect(self.bounds);
	CGPoint V = WDSubtractPoints(P, C);

	return atan2(V.y, V.x);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	mTouchOffset = [self angleForTouch:touch] - [self angle];

	return [super beginTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self setAngle:[self angleForTouch:touch] - mTouchOffset];
	return [super continueTrackingWithTouch:touch withEvent:event];
}

////////////////////////////////////////////////////////////////////////////////

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self setAngle:[self angleForTouch:touch] - mTouchOffset];
	[super endTrackingWithTouch:touch withEvent:event];

	// isTracking == NO will trigger undo, so call actions after super
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
