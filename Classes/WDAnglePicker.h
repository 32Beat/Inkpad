////////////////////////////////////////////////////////////////////////////////
/*
	WDAnglePicker.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

// TODO: decide on saving degrees in ShadowOptions
/*
	Everything is designed to accommodate user values, 
	and users don't think in radians...
*/
////////////////////////////////////////////////////////////////////////////////
@interface WDAnglePicker : UIControl
{
	CGFloat mTouchOffset;

	CGFloat mAngle;
	CGFloat mDegrees;
}

- (CGFloat) angle;
- (void) setAngle:(CGFloat)a;

- (CGFloat) degrees;
- (void) setDegrees:(CGFloat)d;

@end
////////////////////////////////////////////////////////////////////////////////
