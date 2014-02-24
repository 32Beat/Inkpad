////////////////////////////////////////////////////////////////////////////////
/*
	WDFillController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColorController.h"
#import "WDColor.h"
#import "WDColorWell.h"
#import "WDDrawingController.h"
#import "WDGradient.h"
#import "WDGradientController.h"
#import "WDInspectableProperties.h"
#import "WDFillController.h"
#import "WDPropertyManager.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDFillController
////////////////////////////////////////////////////////////////////////////////

@synthesize drawingController = drawingController_;

////////////////////////////////////////////////////////////////////////////////

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self) {
		return nil;
	}
	
	UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
	title.text = NSLocalizedString(@"Fill", @"Fill");
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
															  NSLocalizedString(@"Color", @"Color"),
															  NSLocalizedString(@"Gradient", @"Gradient")]];
	[modeSegment_ addTarget:self action:@selector(adjustMode:) forControlEvents:UIControlEventValueChanged];
	
	item = [[UIBarButtonItem alloc] initWithCustomView:modeSegment_];
	self.navigationItem.rightBarButtonItem = item;
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDrawingController:(WDDrawingController *)drawingController
{
	drawingController_ = drawingController;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(invalidProperties:)
												 name:WDInvalidPropertiesNotification
											   object:drawingController.propertyManager];
}

////////////////////////////////////////////////////////////////////////////////

- (void) modeChanged:(id)sender
{
	fillMode_ = (int) [modeSegment_ selectedSegmentIndex];
	
	if (fillMode_ == kFillNone) {
		[drawingController_ setValue:[NSNull null] forProperty:WDFillProperty];
	} else if (fillMode_ == kFillColor) {
		[drawingController_ setValue:colorController_.color forProperty:WDFillProperty];
	} else { // gradient
		[drawingController_ setValue:gradientController_.gradient forProperty:WDFillProperty];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (WDFillOptions *) fillOptions
{
	WDFillOptions *options = [WDFillOptions new];

	[options setActive:[modeSegment_ selectedSegmentIndex]];
	[options setColor:[colorController_ color]];

	return options;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFillOptions:(WDFillOptions *)options
{
	[modeSegment_ setSelectedSegmentIndex:[options active]];
	[colorController_ setColor:[options color]];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) adjustMode:(id)sender
{ [self adjustFill:sender shouldUndo:!mDidAdjust]; }

- (IBAction) adjustFill:(id)sender
{ [self adjustFill:sender shouldUndo:![sender isTracking]]; }

- (void) adjustFill:(id)sender shouldUndo:(BOOL)shouldUndo
{
	[drawingController_
	setValue:[self fillOptions]
	forProperty:WDFillOptionsKey
	undo:shouldUndo];

	mDidAdjust = YES;
}

////////////////////////////////////////////////////////////////////////////////
// If not interactive, these should always undo

- (void) takeColorFrom:(id)sender
{ [self adjustFill:sender shouldUndo:YES]; }

////////////////////////////////////////////////////////////////////////////////

- (void) takeGradientFrom:(id)sender
{
	WDGradientController *controller = (WDGradientController *)sender;
	
	[drawingController_ setValue:controller.gradient forProperty:WDFillProperty];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	colorController_ = [WDColorController new];
	colorController_.target = self;
	colorController_.action = @selector(takeColorFrom:);

	CGRect frame = colorController_.view.frame;
	frame.origin = CGPointMake(5, 5);
	colorController_.view.frame = frame;
	[self.view addSubview:colorController_.view];



	gradientController_ = [[WDGradientController alloc] initWithNibName:@"Gradient" bundle:nil];
	[self.view addSubview:gradientController_.view];
	
	gradientController_.target = self;
	gradientController_.action = @selector(takeGradientFrom:);
	gradientController_.colorController = colorController_;
	
	frame = gradientController_.view.frame;
	frame.origin.x = 5;
	frame.origin.y = CGRectGetMaxY(colorController_.view.frame) + 15;
	gradientController_.view.frame = frame;
	
	frame = self.view.frame;
	frame.size.height = CGRectGetMaxY(gradientController_.view.frame) + 4;
	self.view.frame = frame;
	
	self.preferredContentSize = self.view.frame.size;
}

- (void) configureUIWithFill:(id<WDPathPainter>)fill
{
	if (!fill || [fill isEqual:[NSNull null]]) {
		gradientController_.inactive = YES;
		colorController_.gradientStopMode = NO;
		fillMode_ = kFillNone;
	} else if ([fill isKindOfClass:[WDColor class]]) {
		gradientController_.inactive = YES;
		colorController_.gradientStopMode = NO;
		colorController_.color = (WDColor *) fill;
		fillMode_ = kFillColor;
	} else {
		gradientController_.inactive = NO;
		colorController_.gradientStopMode = YES;
		gradientController_.gradient = (WDGradient *) fill;
		fillMode_ = kFillGradient;
	}
	
	[modeSegment_ removeTarget:self action:@selector(adjustMode:) forControlEvents:UIControlEventValueChanged];
	modeSegment_.selectedSegmentIndex = fillMode_;
	[modeSegment_ addTarget:self action:@selector(adjustMode:) forControlEvents:UIControlEventValueChanged];
}

- (void) invalidProperties:(NSNotification *)aNotification
{
	NSSet *properties = [aNotification userInfo][WDInvalidPropertiesKey];

	if ([properties containsObject:WDFillOptionsKey])
	{
		[self setFillOptions:
		[drawingController_.propertyManager activeFillOptions]];
	}
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self setFillOptions:
	[drawingController_.propertyManager activeFillOptions]];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
