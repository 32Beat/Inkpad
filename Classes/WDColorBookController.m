////////////////////////////////////////////////////////////////////////////////
/*
	WDColorBookController.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDColorBookController.h"
#import "WDAdobeColorBook.h"
#import "WDSwatchController.h"
#import "WDSwatchCell.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDColorBookController
////////////////////////////////////////////////////////////////////////////////

- (id) initWithData:(NSData *)data
{
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	flowLayout.minimumLineSpacing = 5.0;
	flowLayout.minimumInteritemSpacing = 5.0;
	flowLayout.sectionInset = (UIEdgeInsets){ 5, 5, 5, 5 };
	flowLayout.itemSize = (CGSize){ 45, 45 };
	
	self = [super initWithCollectionViewLayout:flowLayout];
	if (self != nil)
	{
		if ([self prepareSwatches:data.bytes])
		{
			if ([self prepareCollectionView])
			{
				self.title = AdobeColorBookData_FetchName([data bytes]);
				return self;
			}
		}
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareSwatches:(const Byte *)dataPtr
{
	mColors = AdobeColorBookData_FetchColors(dataPtr);	
	mPageSize = AdobeColorBookData_FetchPageSize(dataPtr);
	
	return mColors != nil;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareCollectionView
{
	self.collectionView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	self.collectionView.autoresizingMask = 
	UIViewAutoresizingFlexibleWidth|
	UIViewAutoresizingFlexibleHeight;

	[self.collectionView registerClass:[WDSwatchCell class] forCellWithReuseIdentifier:@"ColorSwatch"];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGSize) preferredContentSize
{
	UICollectionViewFlowLayout *flowLayout = 
	(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	CGSize size = flowLayout.itemSize;

	size.width += flowLayout.minimumInteritemSpacing;
	size.width *= mPageSize;
	size.width += flowLayout.minimumInteritemSpacing;

	size.height += flowLayout.minimumLineSpacing;
	size.height *= mColors.count;
	size.height += flowLayout.minimumInteritemSpacing;
	
	return size;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return mColors.count;
}

////////////////////////////////////////////////////////////////////////////////

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	WDSwatchCell *swatchCell = 
	[collectionView dequeueReusableCellWithReuseIdentifier:@"ColorSwatch"
	forIndexPath:indexPath];
	
	NSString *entry = [mColors objectAtIndex:indexPath.row];
	NSArray *stringComponents = [entry componentsSeparatedByString:@", "];
	if (stringComponents.count >= 4)
	{
		CGFloat L = ((NSString *)stringComponents[1]).floatValue;
		CGFloat a = ((NSString *)stringComponents[2]).floatValue;
		CGFloat b = ((NSString *)stringComponents[3]).floatValue;
		
		swatchCell.title = stringComponents[0];
		swatchCell.color = [WDColor colorWithL:L a:a b:b];
	}
	
	return swatchCell;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



