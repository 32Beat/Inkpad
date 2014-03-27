//
//  UIBarButtonItem+Additions.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Steve Sprang
//

#import "UIBarButtonItem+Additions.h"

@implementation UIBarButtonItem (Additions)

+ (UIBarButtonItem *) segmentedControlWithLabels:(NSArray *)labels
{
	return [[UIBarButtonItem alloc] initWithCustomView: 
	[[UISegmentedControl alloc] initWithItems:labels]];
}

+ (UIBarButtonItem *) segmentedControlWithLocalizedLabels:(NSArray *)labels
{
	NSMutableArray *localizedLabels = [NSMutableArray array];
	for (id label in labels)
	{ [localizedLabels addObject:NSLocalizedString(label, /**/)]; }
	return [self segmentedControlWithLabels:localizedLabels];
}



+ (UIBarButtonItem *) flexibleItem
{
	return [[UIBarButtonItem alloc] 
	initWithBarButtonSystemItem:
	UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *) fixedItemWithWidth:(float)width
{
	UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] 
	initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
	target:nil action:nil];
	
	fixedItem.width = width;

	return fixedItem;
}

@end
