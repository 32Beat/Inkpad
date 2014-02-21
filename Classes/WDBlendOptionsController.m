////////////////////////////////////////////////////////////////////////////////
/*
	BlendOptionsController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDBlendOptionsController.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDBlendOptionsController
////////////////////////////////////////////////////////////////////////////////

- (id) init
{ return [self initWithNibName:@"BlendOptions" bundle:nil]; }

////////////////////////////////////////////////////////////////////////////////
- (void)loadView
{
	[super loadView];
	
	blendModeTableView_.backgroundColor = [UIColor clearColor];
	blendModeTableView_.opaque = NO;
	blendModeTableView_.backgroundView = nil;
}


- (NSArray *) blendModeNames
{
	if (mBlendModeNames == nil)
	{ mBlendModeNames = [self _blendModeNames]; }

	return mBlendModeNames;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) _blendModeNames
{
	NSArray *srcArray = [[NSArray alloc]
	initWithContentsOfURL:[[NSBundle mainBundle]
	URLForResource:@"BlendModes" withExtension:@"plist"]];

	return srcArray;
}

////////////////////////////////////////////////////////////////////////////////
- (NSString *) localizedTitleForKey:(NSString *)key
{
	// we could duplicate the BlendModes.plist for every localization, 
	// but this seems less error prone
	static NSMutableDictionary *map_ = nil;
	if (!map_) {
		map_ = [NSMutableDictionary dictionary];
		map_[@"Normal"]     = NSLocalizedString(@"Normal", @"Normal");
		map_[@"Darken"]     = NSLocalizedString(@"Darken", @"Darken");
		map_[@"Multiply"]   = NSLocalizedString(@"Multiply", @"Multiply");
		map_[@"Lighten"]    = NSLocalizedString(@"Lighten", @"Lighten");
		map_[@"Screen"]     = NSLocalizedString(@"Screen", @"Screen");
		map_[@"Overlay"]    = NSLocalizedString(@"Overlay", @"Overlay");
		map_[@"Difference"] = NSLocalizedString(@"Difference", @"Difference");
		map_[@"Exclusion"]  = NSLocalizedString(@"Exclusion", @"Exclusion");
		map_[@"Hue"]        = NSLocalizedString(@"Hue", @"Hue");
		map_[@"Saturation"] = NSLocalizedString(@"Saturation", @"Saturation");
		map_[@"Color"]      = NSLocalizedString(@"Color", @"Color");
		map_[@"Luminosity"] = NSLocalizedString(@"Luminosity", @"Luminosity");
	}
	
	return map_[key];
}


////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return [[self blendModeNames] count];
}

////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"blendModeCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[UITableViewCell alloc]
		initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	}
	
	cell.accessoryType = (indexPath.row == selectedRow_) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	NSString *blendKey = self.blendModeNames[indexPath.row][@"name"];
	cell.textLabel.text = [self localizedTitleForKey:blendKey];
	return cell;
}

////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow_ inSection:0]] setAccessoryType:UITableViewCellAccessoryNone];
	selectedRow_ = indexPath.row;
	
//	CGBlendMode blendMode = [mBlendModeNames[indexPath.row][@"value"] intValue];
//	[self.drawingController setValue:@(blendMode) forProperty:WDBlendModeProperty];
	[[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






