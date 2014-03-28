//
//  WDSwatchCell.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "UIView+Additions.h"
#import "WDSwatchCell.h"
#import "WDPathPainter.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDSwatchCell
////////////////////////////////////////////////////////////////////////////////

- (void) setTitle:(NSString *)text
{
	self.nameLabel.text = text;
}

////////////////////////////////////////////////////////////////////////////////

- (UILabel *) nameLabel
{
	if (mNameLabel == nil)
	{ 
		[self.contentView addSubview:
		(mNameLabel = [self createNameLabel])]; 
	}

	return mNameLabel;
}

////////////////////////////////////////////////////////////////////////////////

- (UILabel *) createNameLabel
{
	CGFloat fontSize = [UIFont smallSystemFontSize];

	CGRect frame = self.bounds;
	frame.origin.y += frame.size.height-fontSize;
	frame.size.height = fontSize;

	UILabel *nameLabel = [[UILabel alloc] initWithFrame:frame];
	nameLabel.font = [UIFont systemFontOfSize:fontSize];
	nameLabel.textAlignment = NSTextAlignmentCenter;
	nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
	nameLabel.backgroundColor = [UIColor whiteColor];
	//nameLabel = YES;

	return nameLabel;
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(CGRect)R
{
	[self.color drawSwatchInRect:self.bounds];
}

////////////////////////////////////////////////////////////////////////////////

@synthesize shouldShowSelectionIndicator;

- (void) setSelected:(BOOL)flag
{
	[super setSelected:flag];
	
	if (!shouldShowSelectionIndicator) {
		[selectedIndicator_ removeFromSuperview];
		selectedIndicator_ = nil;
		return;
	}
	
	if (flag && !selectedIndicator_) {
		UIImage *checkmark = [UIImage imageNamed:@"checkmark.png"];
		size_t width = checkmark.size.width;
		size_t height = checkmark.size.height;
		
		selectedIndicator_ = [[UIImageView alloc] initWithImage:checkmark];
		[self addSubview:selectedIndicator_];
		
		selectedIndicator_.sharpCenter = CGPointMake(CGRectGetMaxX(self.bounds) - ((width / 3) + 1),
													 CGRectGetMaxY(self.bounds) - ((height / 3) + 1));
	} else if (!flag && selectedIndicator_){
		[UIView animateWithDuration:0.1f
						 animations:^{ selectedIndicator_.alpha = 0; }
						 completion:^(BOOL finished){ [selectedIndicator_ removeFromSuperview]; }];
		selectedIndicator_ = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setHighlighted:(BOOL)highlighted
{
	if (highlighted)
	{
		self.layer.borderColor = [UIColor colorWithWhite:0.0f alpha:0.25f].CGColor;
		self.layer.borderWidth = 0.5*self.bounds.size.width;
	}
	else
	{
		self.layer.borderColor = nil;
		self.layer.borderWidth = 0.0;
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
