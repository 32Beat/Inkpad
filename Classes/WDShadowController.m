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

@implementation WDShadowController

@synthesize drawingController = drawingController_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self) {
		return nil;
	}
	
	self.title = NSLocalizedString(@"Shadow and Opacity", @"Shadow and Opacity");
	
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
											   object:drawingController_.propertyManager];
}

////////////////////////////////////////////////////////////////////////////////

- (WDShadowOptions *) shadowOptions
{
	WDShadowOptions *shadow = [WDShadowOptions new];

	[shadow setActive:[shadowSwitch_ isOn]];
	[shadow setColor:[colorController_ color]];
	[shadow setAngle:[angle_ value]];
	[shadow setOffset:[offset_ value]];
	[shadow setBlur:[radius_ value]];

	return shadow;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setShadowOptions:(WDShadowOptions *)shadowOptions
{
	[colorController_ setColor:[shadowOptions color]];
	[shadowSwitch_ setOn:[shadowOptions active]];
	[angle_ setValue:[shadowOptions angle]];
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
	[drawingController_
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

- (IBAction) increment:(id)sender
{
	opacitySlider_.value = opacitySlider_.value + 1;
	[opacitySlider_ sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) decrement:(id)sender
{
	opacitySlider_.value = opacitySlider_.value - 1;
	[opacitySlider_ sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) takeOpacityFrom:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	
	int value = round(slider.value);
	opacityLabel_.text = [NSString stringWithFormat:@"%d%%", value];
	
	decrement.enabled = value != 0;
	increment.enabled = value != 100;
}

- (IBAction) takeFinalOpacityFrom:(id)sender
{
	UISlider    *slider = (UISlider *)sender;
	float       opacity = slider.value / 100.0f;
	
	[drawingController_ setValue:@(opacity) forProperty:WDOpacityProperty];
}

- (void) updateBlendMode
{
	blendMode_ = [[drawingController_.propertyManager defaultValueForProperty:WDBlendModeProperty] intValue];
	[blendModeTableView_ reloadData];
}

- (void) updateOpacity:(float)opacity
{
	opacitySlider_.value = opacity * 100;
	
	int rounded = round(opacity * 100);
	opacityLabel_.text = [NSString stringWithFormat:@"%d%%", rounded];
	
	decrement.enabled = opacity != 0.0f;
	increment.enabled = opacity != 1.0f;
}

- (void) invalidProperties:(NSNotification *)aNotification
{
	NSSet *properties = [aNotification userInfo][WDInvalidPropertiesKey];
	
	for (NSString *property in properties) {

		id value = [drawingController_.propertyManager defaultValueForProperty:property];

		if (property == WDShadowOptionsKey)
			[self setShadowOptions:value];
		else

		if ([property isEqualToString:WDOpacityProperty]) {
			[self updateOpacity:[value floatValue]];
		} else if ([property isEqualToString:WDBlendModeProperty]) {
			[self updateBlendMode];
		} else if ([property isEqualToString:WDShadowAngleProperty]) {
			angle_.value = [value floatValue];
		} else if ([property isEqualToString:WDShadowOffsetProperty]) {
			offset_.value = [value floatValue];
		} else if ([property isEqualToString:WDShadowRadiusProperty]) {
			radius_.value = [value floatValue];
		} else if ([property isEqualToString:WDShadowVisibleProperty]) {
			shadowSwitch_.on = [value boolValue];
		} else if ([property isEqualToString:WDShadowColorProperty]) {
			colorController_.color = (WDColor *)value;
		}
	}
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) viewDidLoad
{
	[super viewDidLoad];
	
	colorController_ = [[WDColorController alloc]
	initWithNibName:@"Color" bundle:nil];
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
	mBlendOptionsController.preferredContentSize = self.view.frame.size;

	blendModeController_ = [[WDBlendModeController alloc]
	initWithNibName:nil bundle:nil];
	blendModeController_.preferredContentSize = self.view.frame.size;
	blendModeController_.drawingController = self.drawingController;
	
	blendModeTableView_.backgroundColor = [UIColor clearColor];
	blendModeTableView_.opaque = NO;
	blendModeTableView_.backgroundView = nil;
	

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
	[drawingController_.propertyManager defaultShadowOptions]];
	
	// opacity
	float opacity = [[drawingController_.propertyManager defaultValueForProperty:WDOpacityProperty] floatValue];
	[self updateOpacity:opacity];
	
	[self updateBlendMode];
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"blendModeCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.text = NSLocalizedString(@"Blend Mode", @"Blend Mode");
	}
	cell.detailTextLabel.text = [blendModeController_ displayNameForBlendMode:blendMode_];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[blendModeTableView_ deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	[self.navigationController pushViewController:blendModeController_ animated:YES];
}

@end
