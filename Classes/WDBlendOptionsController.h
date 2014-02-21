////////////////////////////////////////////////////////////////////////////////
/*
	BlendOptionsController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>


////////////////////////////////////////////////////////////////////////////////
@interface WDBlendOptionsController : UIViewController
<UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UISlider       *opacitySlider_;
	IBOutlet UILabel        *opacityLabel_;
	IBOutlet UIButton       *increment;
	IBOutlet UIButton       *decrement;
	IBOutlet UITableView	*blendModeTableView_;
	CGBlendMode				blendMode_;

	NSArray *mBlendModeNames;
	NSUInteger selectedRow_;
}



@end
////////////////////////////////////////////////////////////////////////////////
