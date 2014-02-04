////////////////////////////////////////////////////////////////////////////////
/*
	WDRectangleShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShape.h"

////////////////////////////////////////////////////////////////////////////////
@interface WDRectangleShape : WDShape
{
	CGFloat mRadius;
}


- (void) setRadius:(CGFloat)radius;

// Options protocol
- (id) paramName;
- (float) paramValue;
- (void) setParamValue:(float)value withUndo:(BOOL)shouldUndo;

@end
////////////////////////////////////////////////////////////////////////////////
