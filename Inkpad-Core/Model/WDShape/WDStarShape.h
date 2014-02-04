////////////////////////////////////////////////////////////////////////////////
/*
	WDStarShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDShape.h"

////////////////////////////////////////////////////////////////////////////////
@interface WDStarShape : WDShape
{
	long mCount;
	CGFloat mRadius;
}


- (long) pointCount;
- (void) setPointCount:(long)count;
- (float) innerRadius;
- (void) setInnerRadius:(float)radius;

- (void) adjustPointCount:(long)count withUndo:(BOOL)shouldUndo;
- (void) adjustInnerRadius:(float)radius withUndo:(BOOL)shouldUndo;

- (id) bezierNodesWithShapeInRect:(CGRect)R;

@end
////////////////////////////////////////////////////////////////////////////////
