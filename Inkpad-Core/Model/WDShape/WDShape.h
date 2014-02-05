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
	only implement bezierNodesWithShapeInRect 
	(see WDOvalShape for example)
	
	For an editable shape with a single relative parameter
	implement WDShapeOptionsProtocol
	(see WDRectangleShape for example)

	For an editable shape with multiple parameters 
	implement WDShapeOptionsProtocol
	and add WD<name>ShapeOptions.xib
	(see WDStarShape for example)
	
	
	Shapes are closed by default, if open path is desired overwrite:
	- (CGPathRef) createSourcePath
	{ return WDCreateCGPathRefWithNodes([self bezierNodes], YES); }
*/
////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeType
{
	WDShapeTypeRectangle = 0,
	WDShapeTypeOval,
	WDShapeTypePie,
	WDShapeTypeStar,
	WDShapeTypePolygon, // = star with inner radius 1.0
	WDShapeTypeLine, 	// = not a shape
	WDShapeTypeSpiral,
	WDShapeTypeLeaf,
	WDShapeTypeHeart,
	WDShapeTypeDiamond
}
WDShapeType;

////////////////////////////////////////////////////////////////////////////////

typedef enum WDShapeOptions
{
	WDShapeOptionsNone = 0,
	WDShapeOptionsDefault,
	WDShapeOptionsCustom
}
WDShapeOptions;

////////////////////////////////////////////////////////////////////////////////
@protocol WDShapeOptionsProtocol

- (NSInteger) shapeOptions;

@optional
- (id) paramName;
- (int) paramVersion;
- (float) paramValue;
- (void) setParamValue:(float)value withVersion:(int)version;
- (void) setParamValue:(float)value withUndo:(BOOL)shouldUndo;

@optional
// WDShapeOptionsNone means shape can be defined outside context
+ (id) bezierNodesWithShapeInRect:(CGRect)R;
+ (id) bezierNodesWithShapeInRect:(CGRect)R paramValue:(float)value;
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
	CGFloat mRotation;
	CGPoint mPosition;

	CGAffineTransform mTransform;
	
	// Cache
	CGRect mFrameRect; 		// boundingbox of transformed sourcerect
	CGPathRef mFramePath; 	// transformed sourcerect cornerpoints
	CGPathRef mResultPath; 	// transformed sourcepath
	CGPathRef mSourcePath; 	// path from sourcenodes
	NSArray *mSourceNodes; 	// beziernodes centered around 0,0
}

+ (id) shapeWithFrame:(CGRect)frame;
- (id) initWithFrame:(CGRect)frame;

- (NSString *) shapeName; // defaults to classname
- (NSInteger) shapeVersion; // defaults to 0

- (void) flushCache;
- (CGRect) frameRect;
- (CGPathRef) framePath;
- (CGPathRef) resultPath;
- (CGPathRef) sourcePath;
- (id) bezierNodes;
- (id) bezierNodesWithShapeInRect:(CGRect)R;

@end
////////////////////////////////////////////////////////////////////////////////





