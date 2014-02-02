////////////////////////////////////////////////////////////////////////////////
/*
	WDShape.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDAbstractPath.h"

////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeType
{
	WDShapeTypeRectangle = 0,
	WDShapeTypeOval,
	WDShapeTypeStar,
	WDShapeTypePolygon,
	WDShapeTypeLine,
	WDShapeTypeSpiral
}
WDShapeType;

////////////////////////////////////////////////////////////////////////////////

// Minimize deviation http://spencermortensen.com/articles/bezier-circle/

#define kWDShapeCircleFactor 	0.551915024494

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@interface WDShape : WDAbstractPath
{
	// Model
	long mType;
	CGSize mSize;
	CGAffineTransform mTransform;
	
	// Cache
	CGPathRef mBoundsPath;
	CGPathRef mResultPath;
	CGPathRef mSourcePath;
	NSArray *mSourceNodes;

	// Tracking
	BOOL mTracking;
}

+ (id) shapeWithBounds:(CGRect)bounds;
- (id) initWithBounds:(CGRect)bounds;

- (WDShapeType) shapeType;
- (NSString *) shapeTypeName;

- (void) flushCache;
- (CGPathRef) boundsPath;
- (CGPathRef) resultPath;
- (CGPathRef) sourcePath;

- (id) bezierNodes;
- (id) createNodes;
- (id) bezierNodesWithRect:(CGRect)R;

- (void) adjustParamValue:(float)value isFinal:(BOOL)final;

@end
////////////////////////////////////////////////////////////////////////////////




