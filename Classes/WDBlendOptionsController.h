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
#import "WDBlendModeController.h"
#import "WDBlendOptions.h"

@protocol WDBlendOptionsControllerDelegate
-(void) blendOptionsController:(id)blender willAdjustValueForKey:(id)key;
-(void) blendOptionsController:(id)blender didAdjustValueForKey:(id)key;
@end

////////////////////////////////////////////////////////////////////////////////
@interface WDBlendOptionsController : UIViewController
<UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UISlider       *mOpacitySlider;
	IBOutlet UILabel        *mOpacityLabel;
	IBOutlet UIButton       *increment;
	IBOutlet UIButton       *decrement;
	IBOutlet UITableView	*blendModeTableView_;
	WDBlendModeController	*blendModeController_;

	WDBlendOptions *mBlendOptions;
}

@property (nonatomic, weak) id rootController;
@property (nonatomic, weak) id<WDBlendOptionsControllerDelegate> delegate;

- (WDBlendOptions *) blendOptions;
- (void) setBlendOptions:(WDBlendOptions *)blendOptions;

@end
////////////////////////////////////////////////////////////////////////////////


