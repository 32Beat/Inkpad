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
#import "WDColorBookController.h"
#import "WDSwatchController.h"

#import "WDAdobeColorBook.h"

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
	NSArray *bookURLs =
	[[NSBundle mainBundle] URLsForResourcesWithExtension:@"acb" 
	subdirectory:@"ColorBooks"];
	
	NSMutableArray *bookList = [NSMutableArray new];
	
	for (NSURL *bookURL in bookURLs)
	{
/*
		NSError *errorPtr = nil;	
		NSDictionary *resourceValues = 
		[bookURL resourceValuesForKeys:@[NSURLLocalizedNameKey] error:&errorPtr];
		
		NSString *name = [resourceValues objectForKey:NSURLLocalizedNameKey];
		if (name == nil)
		{ name = [bookURL lastPathComponent]; }
		
		name = [name stringByReplacingOccurrencesOfString:@".acb" withString:@""];
*/
		NSData *data = [NSData dataWithContentsOfURL:bookURL];
		if (AdobeColorBookData_IsLabColor([data bytes]))
		{
			//NSString *name = AdobeColorBookData_FetchName([data bytes]);
			//if (name != nil)
			[bookList addObject:data];
		}
	}
	
	mColorBooks = bookList;	
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadTableView
{
	mTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	mTableView.dataSource = self;
	mTableView.delegate = self;
	mTableView.autoresizingMask = 
	UIViewAutoresizingFlexibleWidth|
	UIViewAutoresizingFlexibleHeight;
	
	if (mTableView != nil)
	{ [self.view addSubview:mTableView]; }
	
	return mTableView != nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// DataSource

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
	
	NSData *data = [mColorBooks objectAtIndex:indexPath.row];
	bookCell.textLabel.text = 
	AdobeColorBookData_FetchName([data bytes]);
	bookCell.detailTextLabel.text = 
	AdobeColorBookData_FetchDescription([data bytes]);
	bookCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return bookCell;
}

////////////////////////////////////////////////////////////////////////////////
// Delegate

- (void)tableView:(UITableView *)tableView 
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSData *data = [mColorBooks objectAtIndex:indexPath.row];
	id viewController = 
	[[WDColorBookController alloc] initWithData:data];
	
	[[self navigationController] pushViewController:viewController animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



