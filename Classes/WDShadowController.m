//
//  WDShadowController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDAnglePicker.h"
#import "WDBlendModeController.h"
#import "WDBlendOptionsController.h"

#import "WDColorController.h"
#import "WDColor.h"
#import "WDColorWell.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDShadowController.h"
#import "WDPropertyManager.h"
#import "WDShadow.h"
#import "WDSparkSlider.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDShadowController
////////////////////////////////////////////////////////////////////////////////

- (id) init
{
	self = [super initWithNibName:@"Shadow" bundle:nil];
	if (self != nil)
	{
		self.title =
		NSLocalizedString(@"Shadow and Opacity", @"Shadow and Opacity");
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithDelegate:(id)delegate
{
	self = [super init];
	if (self != nil)
	{
		//self.delegate = delegate;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setDrawingController:(WDDrawingController *)drawingController
{
	_drawingController = drawingController;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(invalidProperties:)
												 name:WDInvalidPropertiesNotification
											   object:_drawingController.propertyManager];
}

////////////////////////////////////////////////////////////////////////////////

- (WDShadowOptions *) shadowOptions
{
	WDShadowOptions *shadow = [WDShadowOptions new];

	[shadow setActive:[shadowSwitch_ isOn]];
	[shadow setColor:[colorController_ color]];
	[shadow setAngle:[angle_ angle]];
	[shadow setOffset:[offset_ value]];
	[shadow setBlur:[radius_ value]];

	return shadow;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setShadowOptions:(WDShadowOptions *)shadowOptions
{
	[colorController_ setColor:[shadowOptions color]];
	[shadowSwitch_ setOn:[shadowOptions active]];
	[angle_ setAngle:[shadowOptions angle]];
	[offset_ setValue:[shadowOptions offset]];
	[radius_ setValue:[shadowOptions blur]];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) toggleShadow:(id)sender
{ [self adjustShadow:sender undo:!mDidAdjust]; }

- (IBAction) adjustShadow:(id)sender
{ [self adjustShadow:sender undo:![sender isTracking]]; }

- (void) adjustShadow:(id)sender undo:(BOOL)shouldUndo
{
	[_drawingController
	setValue:[self shadowOptions]
	forProperty:WDShadowOptionsKey
	undo:shouldUndo];

	mDidAdjust = YES;
}

////////////////////////////////////////////////////////////////////////////////
// Will be sent by colorController

- (void) takeColorFrom:(id)sender
{ [self adjustShadow:sender]; }

////////////////////////////////////////////////////////////////////////////////

- (void) invalidProperties:(NSNotification *)aNotification
{
	NSSet *properties = [aNotification userInfo][WDInvalidPropertiesKey];
	
	for (NSString *property in properties)
	{
		if (property == WDShadowOptionsKey)
		{
			[self setShadowOptions:
			[_drawingController.propertyManager activeShadowOptions]];
		}
		else
		if (property == WDBlendOptionsKey)
		{
			[mBlendOptionsController setBlendOptions:
			[_drawingController.propertyManager activeBlendOptions]];
		}
	}
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) viewDidLoad
{
	[super viewDidLoad];
	
	colorController_ = [WDColorController new];
	[self.view addSubview:colorController_.view];
	colorController_.shadowMode = YES;
	
	CGRect frame = colorController_.view.frame;
	frame.origin = CGPointMake(5, 5);
	colorController_.view.frame = frame;

	colorController_.target = self;
	colorController_.action = @selector(takeColorFrom:);


	mBlendOptionsController = [WDBlendOptionsController new];
	[self.view addSubview:mBlendOptionsController.view];

	CGRect srcFrame = mBlendOptionsController.view.frame;
	CGRect dstFrame = self.view.frame;

	srcFrame.origin.x += 5;
	srcFrame.origin.y = CGRectGetMaxY(dstFrame)-srcFrame.size.height;
	mBlendOptionsController.view.frame = srcFrame;

	mBlendOptionsController.rootController = self;
	mBlendOptionsController.delegate = self;
/*
	blendModeController_ = [[WDBlendModeController alloc]
	initWithNibName:nil bundle:nil];
	blendModeController_.preferredContentSize = self.view.frame.size;
	blendModeController_.drawingController = self.drawingController;
	
	blendModeTableView_.backgroundColor = [UIColor clearColor];
	blendModeTableView_.opaque = NO;
	blendModeTableView_.backgroundView = nil;
*/	

	radius_.title.text = NSLocalizedString(@"blur", @"blur");
	radius_.maxValue = 50;
	
	offset_.title.text = NSLocalizedString(@"offset", @"offset");
	offset_.maxValue = 50;
	
	angle_.backgroundColor = nil;
	
	[angle_ addTarget:self action:@selector(adjustShadow:)
	forControlEvents:UIControlEventValueChanged];
	
	[offset_ addTarget:self action:@selector(adjustShadow:)
	forControlEvents:UIControlEventValueChanged];

	[radius_ addTarget:self action:@selector(adjustShadow:)
	forControlEvents:UIControlEventValueChanged];
	
	self.preferredContentSize = self.view.frame.size;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self setShadowOptions:
	[_drawingController.propertyManager activeShadowOptions]];

	[mBlendOptionsController setBlendOptions:
	[_drawingController.propertyManager activeBlendOptions]];
}

-(void) blendOptionsController:(id)blender willAdjustValueForKey:(id)key
{}

-(void) blendOptionsController:(id)blender didAdjustValueForKey:(id)key
{
	[_drawingController
	setValue:[blender blendOptions]
	forProperty:WDBlendOptionsKey
	undo:YES];

	[[NSNotificationCenter defaultCenter]
	postNotificationName:WDActiveBlendChangedNotification object:self userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
