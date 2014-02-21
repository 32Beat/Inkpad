//
//  WDBlendModeController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBlendModeController.h"
#import "WDdrawingController.h"
#import "WDPropertyManager.h"
#import "WDInspectableProperties.h"

@interface WDBlendModeController ()
- (NSIndexPath *) indexPathForBlendMode:(CGBlendMode)blendMode;
@end

////////////////////////////////////////////////////////////////////////////////
@implementation WDBlendModeController
////////////////////////////////////////////////////////////////////////////////

- (NSArray *) blendNames
{
	static NSArray *gBlendNames = nil;
	if (gBlendNames == nil)
	{ gBlendNames = [self _blendNames]; }
	return gBlendNames;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) _blendNames
{
	NSMutableArray *names = [NSMutableArray new];

	for (CGBlendMode n=kCGBlendModeNormal; n<=kCGBlendModeLuminosity; n++)
	{ [names addObject:[self blendNameForBlendMode:n]]; }

	return [NSArray arrayWithArray:names];
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) displayNameForBlendMode:(CGBlendMode)blendMode
{
	return [self blendNameForBlendMode:blendMode];
}

////////////////////////////////////////////////////////////////////////////////

- (NSString *) blendNameForBlendMode:(CGBlendMode)mode
{
	switch(mode)
	{
		case kCGBlendModeNormal: return @"Normal";
		case kCGBlendModeMultiply: return @"Multiply";
		case kCGBlendModeScreen: return @"Screen";
		case kCGBlendModeOverlay: return @"Overlay";
		case kCGBlendModeDarken: return @"Darken";
		case kCGBlendModeLighten: return @"Lighten";
		case kCGBlendModeColorDodge: return @"Dodge";
		case kCGBlendModeColorBurn: return @"Burn";
		case kCGBlendModeSoftLight: return @"Soft Light";
		case kCGBlendModeHardLight: return @"Hard Light";
		case kCGBlendModeDifference: return @"Difference";
		case kCGBlendModeExclusion: return @"Exclusion";
		case kCGBlendModeHue: return @"Hue";
		case kCGBlendModeSaturation: return @"Saturation";
		case kCGBlendModeColor: return @"Color";
		case kCGBlendModeLuminosity: return @"Luminosity";
		default: return nil;
	}

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self != nil)
	{
		self.title = NSLocalizedString(@"Blend Mode", @"Blend Mode");
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (void)loadView
{
    CGRect frame = {{0.0,0.0},[self preferredContentSize]};

	tableView_ = [[UITableView alloc]
	initWithFrame:frame style:UITableViewStylePlain];

	tableView_.delegate = self;
	tableView_.dataSource = self;
	self.view = tableView_;
}

////////////////////////////////////////////////////////////////////////////////

- (void)viewWillAppear:(BOOL)animated
{
	selectedRow_ = [self _blendMode];

	// Completely incomprehensible method of scrolling to selected row
	NSIndexPath *activeMode =
	[self indexPathForBlendMode:[self _blendMode]];

	[tableView_ selectRowAtIndexPath:activeMode animated:NO
	scrollPosition:UITableViewScrollPositionNone];

	[tableView_ scrollToRowAtIndexPath:activeMode
	atScrollPosition:UITableViewScrollPositionNone animated:NO];

	[tableView_ deselectRowAtIndexPath:activeMode animated:NO];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGBlendMode) _blendMode
{
	return [[[self representedObject] valueForKey:WDBlendModeKey] intValue];
}

- (void) _setBlendMode:(CGBlendMode)mode
{
	[[self representedObject] setValue:@(mode) forKey:WDBlendModeKey];
}

////////////////////////////////////////////////////////////////////////////////

- (NSIndexPath *) indexPathForBlendMode:(CGBlendMode)blendMode
{
	return [NSIndexPath indexPathForRow:blendMode inSection:0];
}

////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self blendNames] count];
}

////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"blendModeCell";

	UITableViewCell *cell =
	[tableView dequeueReusableCellWithIdentifier:identifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc]
		initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	}
	
	cell.accessoryType = (indexPath.row == selectedRow_) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	cell.textLabel.text = [self blendNames][indexPath.row];
	return cell;
}

////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set new selection
	selectedRow_ = indexPath.row;

	[tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
	withRowAnimation:UITableViewRowAnimationFade];

	// Set new value
	[self _setBlendMode:selectedRow_];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
