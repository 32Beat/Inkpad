////////////////////////////////////////////////////////////////////////////////
/*
	WDColorLibraryController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColorLibraryController.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDColorLibraryController
////////////////////////////////////////////////////////////////////////////////

- (id) init
{
	self = [super initWithNibName:nil bundle:nil];
	if (self != nil)
	{
		if ([self loadColorBooks])
		{
			if ([self loadTableView])
			{
				self.title = @"Color Library";
				return self;
			}
		}
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadColorBooks
{
	mColorBooks = @[
		@"Book 1",
		@"Book 2",
		@"Book 3",
		@"Book 4",
		@"Book 5",
		@"Book 6",
		@"Book 7",
		@"Book 8",
		@"Book 9",
		@"Book A",
		@"Book B",
		];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadTableView
{
	mTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	mTableView.dataSource = self;
	mTableView.autoresizingMask = 
	UIViewAutoresizingFlexibleWidth|
	UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:mTableView];
	
	return mTableView != nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView 
	numberOfRowsInSection:(NSInteger)section
{
	return mColorBooks.count;
}

////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView 
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *bookCell = 
	[tableView dequeueReusableCellWithIdentifier:@"ColorBookCell"];
	
	if (bookCell == nil)
	{
		bookCell = [[UITableViewCell alloc] 
		initWithStyle:UITableViewCellStyleSubtitle 
		reuseIdentifier:@"ColorBookCell"];		
	}
	
	UIEdgeInsets inset = bookCell.separatorInset;
	inset.right = inset.left;
	bookCell.separatorInset = inset;
		
	bookCell.textLabel.text = [mColorBooks objectAtIndex:indexPath.row];
	bookCell.detailTextLabel.text = @"subtitle";
	bookCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return bookCell;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



