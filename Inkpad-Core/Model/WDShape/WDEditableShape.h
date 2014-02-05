////////////////////////////////////////////////////////////////////////////////
/*
	WDEditableShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShape.h"

////////////////////////////////////////////////////////////////////////////////
/*
	mValue is typed equal to UISlider and doesn't 
	need to exceed feedback precision of 2 decimals.
*/
@interface WDEditableShape : WDShape
{
	float mValue;
}

- (void) adjustValue:(float)value withUndo:(BOOL)shouldUndo;

@end
////////////////////////////////////////////////////////////////////////////////


