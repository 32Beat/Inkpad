////////////////////////////////////////////////////////////////////////////////
/*
	WDColorLibraryController.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

#import "WDColor.h"
#import "WDColorWell.h"
#import "WDColorSlider.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDColorLibraryController
	------------------------
	ViewController for selecting a colorbook from a table view
	
	
*/

////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@interface WDColorLibraryController : UIViewController 
<UITableViewDelegate, UITableViewDataSource>
{
	NSArray *mColorBooks;
	UITableView *mTableView;
}

@end
////////////////////////////////////////////////////////////////////////////////




