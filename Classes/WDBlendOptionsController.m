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
}

////////////////////////////////////////////////////////////////////////////////

- (WDBlendOptions *)blendOptions
{ return mBlendOptions; }

- (void) setBlendOptions:(id)options
{
	if (mBlendOptions != options)
	{
		mBlendOptions = [options copy];
		[self updateControls];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) willAdjustValueForKey:(id)key
{ [_delegate blendOptionsController:self willAdjustValueForKey:(id)key]; }

- (void) didAdjustValueForKey:(id)key
{ [_delegate blendOptionsController:self didAdjustValueForKey:(id)key]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setBlendMode:(CGBlendMode)mode
{
	if (mBlendOptions.mode != mode)
	{
		[self willAdjustValueForKey:WDBlendModeKey];
		[mBlendOptions setMode:mode];
		[self updateTable];
		[self didAdjustValueForKey:WDBlendModeKey];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setOpacity:(CGFloat)opacity
{
	if (mBlendOptions.opacity != opacity)
	{
		[self willAdjustValueForKey:WDBlendOpacityKey];
		[mBlendOptions setOpacity:opacity];
		[self updateControls];
		[self didAdjustValueForKey:WDBlendOpacityKey];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateTable
{ [blendModeTableView_ reloadData]; }

////////////////////////////////////////////////////////////////////////////////

- (void) updateControls
{
	mOpacitySlider.value = 100*mBlendOptions.opacity;
	[self updateLabel];
}

- (void) updateLabel
{
	int value = round(mOpacitySlider.value);
	mOpacityLabel.text = [NSString stringWithFormat:@"%d%%", value];

	decrement.enabled = value != 0;
	increment.enabled = value != 100;
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) increment:(id)sender
{
	mOpacitySlider.value += 1;
	[mOpacitySlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) decrement:(id)sender
{
	mOpacitySlider.value -= 1;
	[mOpacitySlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) takeOpacityFrom:(id)sender
{
	//mBlendOptions.opacity = 0.01*[mOpacitySlider value];
	[self updateLabel];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) takeFinalOpacityFrom:(id)sender
{
	[self setOpacity:0.01*[mOpacitySlider value]];
}

- (void) updateBlendMode
{
	[blendModeTableView_ reloadData];
}

- (void) updateOpacity:(float)opacity
{
	mOpacitySlider.value = opacity * 100;
	
	int rounded = round(opacity * 100);
	mOpacityLabel.text = [NSString stringWithFormat:@"%d%%", rounded];
	
	decrement.enabled = opacity != 0.0f;
	increment.enabled = opacity != 1.0f;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (id) blendModeController
{
	if (blendModeController_ == nil)
	{
		blendModeController_ = [[WDBlendModeController alloc]
		initWithNibName:nil bundle:nil];

		CGSize size = self.view.superview.frame.size;
		blendModeController_.preferredContentSize = size;
		blendModeController_.representedObject = self;
	}

	return blendModeController_;
}

////////////////////////////////////////////////////////////////////////////////

- (id) valueForKey:(id)key
{
	return key == WDBlendModeKey ?
	@(self.blendOptions.mode) :
	[super valueForKey:key];
}

- (void) setValue:(id)value forKey:(id)key
{
	if (key == WDBlendModeKey)
	{ [self setBlendMode:[value intValue]]; }
	else
	{ [super setValue:value forKey:key]; }
}

////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{ return 1; }

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
		initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.text = NSLocalizedString(@"Blend Mode", @"Blend Mode");
	}

	cell.detailTextLabel.text =
	[[self blendModeController] displayNameForBlendMode:mBlendOptions.mode];
	
	return cell;
}

////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id nav = ((UIViewController *)(self.rootController)).navigationController;
	[nav pushViewController:[self blendModeController] animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






