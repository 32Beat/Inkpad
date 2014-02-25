//
//  WDStrokeController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDArrowController.h"
#import "WDArrowhead.h"
#import "WDColor.h"
#import "WDColorController.h"
#import "WDColorWell.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDLineAttributePicker.h"
#import "WDSparkSlider.h"
#import "WDStrokeController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"

@implementation WDStrokeController

@synthesize drawingController = drawingController_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self) {
		return nil;
	}

	UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
	title.text = NSLocalizedString(@"Stroke", @"Stroke");
	title.font = [UIFont boldSystemFontOfSize:17.0f];
	title.textColor = [UIColor blackColor];
	title.backgroundColor = nil;
	title.opaque = NO;
	[title sizeToFit];
	
	// make sure the title is centered vertically
	CGRect frame = title.frame;
	frame.size.height = 44;
	title.frame = frame;
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:title];
	self.navigationItem.leftBarButtonItem = item;
	
	modeSegment_ = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"None", @"None"),
															  NSLocalizedString(@"Color", @"Color")]];
   
	// make sure the segment control isn't too squished
	frame = modeSegment_.frame;
	frame.size.width += 40;
	modeSegment_.frame = frame;
	
	[modeSegment_ addTarget:self action:@selector(toggleStroke:) forControlEvents:UIControlEventValueChanged];
	
	item = [[UIBarButtonItem alloc] initWithCustomView:modeSegment_];
	self.navigationItem.rightBarButtonItem = item;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setDrawingController:(WDDrawingController *)drawingController
{
	drawingController_ = drawingController;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(invalidProperties:)
												 name:WDInvalidPropertiesNotification
											   object:drawingController.propertyManager];
}

- (void) invalidProperties:(NSNotification *)aNotification
{
	NSSet *properties = [aNotification userInfo][WDInvalidPropertiesKey];

	if ([properties containsObject:WDStrokeOptionsKey])
	{
		[self setStrokeOptions:
		[drawingController_.propertyManager activeStrokeOptions]];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Width Slider
////////////////////////////////////////////////////////////////////////////////

- (float) lineWidth
{ return [self strokeWidthFromSliderValue:widthSlider_.value]; }

- (void) setLineWidth:(float)lineWidth
{
	UISlider *slider = widthSlider_;
	UILabel *label = widthLabel_;

	slider.value = [self sliderValueFromStrokeWidth:lineWidth];
	label.text = [NSString stringWithFormat:@"%.1f pt", lineWidth];
	
	decrement.enabled = slider.value != slider.minimumValue;
	increment.enabled = slider.value != slider.maximumValue;
}

////////////////////////////////////////////////////////////////////////////////

- (float) sliderValueFromStrokeWidth:(float)strokeWidth
{
	float v = strokeWidth - widthSlider_.minimumValue;
	float r = widthSlider_.maximumValue - widthSlider_.minimumValue;

	return widthSlider_.minimumValue + r * sqrt(v/r);
}

////////////////////////////////////////////////////////////////////////////////

- (float) strokeWidthFromSliderValue:(float)sliderValue
{
	float v = sliderValue - widthSlider_.minimumValue;
	float r = widthSlider_.maximumValue - widthSlider_.minimumValue;

	return widthSlider_.minimumValue + v * v / r;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) takeStrokeWidthFrom:(id)sender
{
	UISlider *slider = (UISlider *)sender;

	float sliderValue = slider.value;
	float strokeWidth = [self strokeWidthFromSliderValue:sliderValue];
	widthLabel_.text = [NSString stringWithFormat:@"%.1f pt", strokeWidth];
	
	decrement.enabled = slider.value != slider.minimumValue;
	increment.enabled = slider.value != slider.maximumValue;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) takeFinalStrokeWidthFrom:(id)sender
{
	[self takeStrokeWidthFrom:sender];
	[self adjustStroke:sender];
}

////////////////////////////////////////////////////////////////////////////////

- (float) roundingFactor:(float)strokeWidth
{
	if (strokeWidth <= 5.0) {
		return 10.0f;
	} else if (strokeWidth <= 10) {
		return 5.0f;
	} else if (strokeWidth <= 20) {
		return 2.0f;
	}
	
	return 1.0f;
}

////////////////////////////////////////////////////////////////////////////////

- (void) changeSliderBy:(float)change
{
	float sliderValue = widthSlider_.value;
	float strokeWidth = [self strokeWidthFromSliderValue:sliderValue];
	float roundingFactor = [self roundingFactor:strokeWidth];
	
	strokeWidth *= roundingFactor;
	strokeWidth += change;
	strokeWidth = roundf(strokeWidth);
	strokeWidth /= roundingFactor;
	
	widthSlider_.value = [self sliderValueFromStrokeWidth:strokeWidth];
	[widthSlider_ sendActionsForControlEvents:UIControlEventTouchUpInside];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) increment:(id)sender
{
	[self changeSliderBy:1];
}

- (IBAction) decrement:(id)sender
{
	[self changeSliderBy:(-1)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////////////

- (WDStrokeOptions *) strokeOptions
{
	WDStrokeOptions *options = [WDStrokeOptions new];

	[options setActive:[modeSegment_ selectedSegmentIndex]];
	[options setColor:[mColorController color]];
	[options setLineWidth:[self lineWidth]];
	[options setLineCap:[capPicker_ cap]];
	[options setLineJoin:[joinPicker_ join]];
	[options setDashOptions:[mDashController dashOptions]];

	return options;
}

- (void) setStrokeOptions:(WDStrokeOptions *)options
{
	[modeSegment_ setSelectedSegmentIndex:[options active]];
	[mColorController setColor:[options color]];
	[self setLineWidth:[options lineWidth]];
	[capPicker_ setCap:[options lineCap]];
	[joinPicker_ setJoin:[options lineJoin]];

	[mDashController setDashOptions:[options dashOptions]];
}



- (IBAction) toggleStroke:(id)sender
{ [self adjustStroke:sender shouldUndo:!mDidAdjust]; }

- (IBAction) adjustStroke:(id)sender
{ [self adjustStroke:sender shouldUndo:![sender isTracking]]; }

- (void) adjustStroke:(id)sender shouldUndo:(BOOL)shouldUndo
{
	[drawingController_
	setValue:[self strokeOptions]
	forProperty:WDStrokeOptionsKey
	undo:shouldUndo];

	mDidAdjust = YES;
}

////////////////////////////////////////////////////////////////////////////////
// If not interactive, these should always undo

- (void) takeColorFrom:(id)sender
{ [self adjustStroke:sender shouldUndo:YES]; }

- (void) takeCapFrom:(id)sender
{ [self adjustStroke:sender shouldUndo:YES]; }

- (void) takeJoinFrom:(id)sender
{ [self adjustStroke:sender shouldUndo:YES]; }

- (void) takeDashFrom:(id)sender
{ [self adjustStroke:sender shouldUndo:YES]; } 

////////////////////////////////////////////////////////////////////////////////

- (IBAction)showArrowheads:(id)sender
{
	WDArrowController *arrowController = [[WDArrowController alloc] initWithNibName:nil bundle:nil];
	arrowController.preferredContentSize = self.view.frame.size;
	arrowController.drawingController = self.drawingController;
	[self.navigationController pushViewController:arrowController animated:YES];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - View Life Cycle
////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self prepareColorController];
	[self prepareDashController];

	widthSlider_.minimumValue = 0.1f;
	widthSlider_.maximumValue = 100.0f;
	[widthSlider_ addTarget:self action:@selector(takeStrokeWidthFrom:)
		  forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragInside | UIControlEventValueChanged)];
	[widthSlider_ addTarget:self action:@selector(takeFinalStrokeWidthFrom:)
		  forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
	
	capPicker_.mode = kStrokeCapAttribute;
	[capPicker_ addTarget:self action:@selector(takeCapFrom:) forControlEvents:UIControlEventValueChanged];
	
	joinPicker_.mode = kStrokeJoinAttribute;
	[joinPicker_ addTarget:self action:@selector(takeJoinFrom:) forControlEvents:UIControlEventValueChanged];
	

	self.preferredContentSize = self.view.frame.size;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareColorController
{
	mColorController = [WDColorController new];
	mColorController.strokeMode = YES;
	mColorController.target = self;
	mColorController.action = @selector(takeColorFrom:);

	// Exchange labelView stub with controller view
	[mColorController.view setFrame:mColorPickerView.frame];
	[self.view addSubview:mColorController.view];
	[mColorPickerView removeFromSuperview];
	mColorPickerView = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareDashController
{
	mDashController = [WDDashController new];
	mDashController.target = self;
	mDashController.action = @selector(takeDashFrom:);

	// Exchange labelView stub with controller view
	[mDashController.view setFrame:mDashOptionsView.frame];
	[self.view addSubview:mDashController.view];
	[mDashOptionsView removeFromSuperview];
	mDashOptionsView = nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// Update for most recently active options
	[self setStrokeOptions:
	[drawingController_.propertyManager activeStrokeOptions]];

	[self updateArrowPreview];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Arrow Previews
////////////////////////////////////////////////////////////////////////////////

- (void) updateArrowPreview
{
	[arrowButton_ setImage:[self arrowPreview] forState:UIControlStateNormal];
}

- (UIImage *) arrowPreview
{
	WDStrokeStyle   *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
	UIColor         *color = [UIColor colorWithRed:0.0f green:(118.0f / 255) blue:1.0f alpha:1.0f];
	WDArrowhead     *arrow;
	CGContextRef    ctx;
	CGSize          size = arrowButton_.frame.size;
	float           scale = 3.0;
	float           y = floor(size.height / 2) + 0.5f;
	float           arrowInset;
	float           stemStart;
	float           stemEnd = 40;
	
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	ctx = UIGraphicsGetCurrentContext();
	
	[color set];
	CGContextSetLineWidth(ctx, scale);
	CGContextSetLineCap(ctx, kCGLineCapRound);
	
	// start arrow
	arrow = [WDArrowhead arrowheads][strokeStyle.startArrow];
	arrowInset = arrow.insetLength;
	if (arrow) {
		[arrow addArrowInContext:ctx position:CGPointMake(arrowInset * scale, y)
						   scale:scale angle:M_PI useAdjustment:NO];
		CGContextFillPath(ctx);
		stemStart = arrowInset * scale;
	} else {
		stemStart = 10;
	}
	
	CGContextMoveToPoint(ctx, stemStart, y);
	CGContextAddLineToPoint(ctx, stemEnd, y);
	CGContextStrokePath(ctx);
	
	// end arrow
	arrow = [WDArrowhead arrowheads][strokeStyle.endArrow];
	arrowInset = arrow.insetLength;
	if (arrow) {
		[arrow addArrowInContext:ctx position:CGPointMake(size.width - (arrowInset * scale), y)
						   scale:scale angle:0 useAdjustment:NO];
		CGContextFillPath(ctx);
		stemStart = arrowInset * scale;
	} else {
		stemStart = 10;
	}
	
	CGContextMoveToPoint(ctx, size.width - stemStart, y);
	CGContextAddLineToPoint(ctx, size.width - stemEnd, y);
	CGContextStrokePath(ctx);
	
	// draw interior line
	[[color colorWithAlphaComponent:0.5f] set];
	CGContextMoveToPoint(ctx, stemEnd + 10, y);
	CGContextAddLineToPoint(ctx, size.width - (stemEnd + 10), y);
	CGContextSetLineWidth(ctx, scale - 2);
	CGContextStrokePath(ctx);
	
	// draw a label
	NSString *label = NSLocalizedString(@"arrowheads", @"arrowheads");
	NSDictionary *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:15.0f],
							NSForegroundColorAttributeName:color};
	CGRect bounds = CGRectZero;
	bounds.size = [label sizeWithAttributes:attrs];
	bounds.origin.x = (size.width - CGRectGetWidth(bounds)) / 2;
	bounds.origin.y = (size.height - CGRectGetHeight(bounds)) / 2 - 1;
	CGContextSetBlendMode(ctx, kCGBlendModeClear);
	CGContextFillRect(ctx, CGRectInset(bounds, -10, -10));
	CGContextSetBlendMode(ctx, kCGBlendModeNormal);
	[label drawInRect:bounds withAttributes:attrs];
	
	// grab the image
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}

@end
