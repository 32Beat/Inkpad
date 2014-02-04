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
#import "WDBezierNode.h"

////////////////////////////////////////////////////////////////////////////////
/*
	WDShape
	-------
	Superclass for editable shape items
	
	Usage: 
	
	For a simple shape with no options,
	only implement bezierNodesWithRect 
	(see WDOvalShape for example)
	
	For an editable shape with a single relative parameter
	implement WDShapeOptionsProtocol
	(see WDRectangleShape for example)

	For an editable shape with multiple parameters 
	implement WDShapeOptionsProtocol
	and add WD<name>ShapeOptions.xib
	(see WDStarShape for example)
*/
////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeType
{
	WDShapeTypeRectangle = 0,
	WDShapeTypeOval,
	WDShapeTypeStar,
	WDShapeTypePolygon, // = star with inner radius 1.0
	WDShapeTypeLine, 	// = not a shape
	WDShapeTypeSpiral,
	WDShapeTypeLeaf,
	WDShapeTypeHeart
}
WDShapeType;

////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeOptions
{
	WDShapeOptionsNone = 0,
	WDShapeOptionsDefault,
	WDShapeOptionsCustom
}
WDShapeOption;

////////////////////////////////////////////////////////////////////////////////
@protocol WDShapeOptionsProtocol

- (long) shapeTypeOptions;

@optional
- (id) paramName;
- (float) paramValue;
- (void) setParamValue:(float)value withUndo:(BOOL)shouldUndo;

@optional
// WDShapeOptionsNone means shape can be defined outside context
+ (id) bezierNodesWithRect:(CGRect)R;
+ (id) bezierNodesWithShapeInRect:(CGRect)R
		normalizedPoints:(const CGPoint *)P count:(int)nodeCount;
@end
////////////////////////////////////////////////////////////////////////////////

// Minimize deviation http://spencermortensen.com/articles/bezier-circle/

#define kWDShapeCircleFactor 	0.551915024494

////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////////
@interface WDShape : WDAbstractPath <WDShapeOptionsProtocol>
{
	// Model
	CGSize mSize;
	CGAffineTransform mTransform;
	
	// Cache
	CGRect mFrameRect; 		// boundingbox of transformed sourcerect
	CGPathRef mFramePath; 	// transformed sourcerect cornerpoints
	CGPathRef mResultPath; 	// transformed sourcepath
	CGPathRef mSourcePath; 	// path from sourcenodes
	NSArray *mSourceNodes; 	// beziernodes centered around 0,0
}

+ (id) shapeWithBounds:(CGRect)bounds;
- (id) initWithBounds:(CGRect)bounds;

- (NSString *) shapeTypeName; // defaults to classname


- (void) flushCache;
- (CGRect) frameRect;
- (CGPathRef) framePath;
- (CGPathRef) resultPath;
- (CGPathRef) sourcePath;
- (id) bezierNodes;
- (id) bezierNodesWithRect:(CGRect)R;

@end
////////////////////////////////////////////////////////////////////////////////





