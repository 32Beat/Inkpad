//
//  WDPath.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "UIColor+Additions.h"
#import "WDArrowhead.h"
#import "WDBezierNode.h"
#import "WDBezierSegment.h"
#import "WDColor.h"
#import "WDCompoundPath.h"
#import "WDFillTransform.h"
#import "WDGLUtilities.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDPathfinder.h"
#import "WDShadow.h"
#import "WDUtilities.h"

const float kMiterLimit  = 10;

// Fit t = 0.5
//const float circleFactor = 0.5522847498307936;

// Minimize deviation http://spencermortensen.com/articles/bezier-circle/
const float circleFactor = 0.551915024494;

static NSString *WDPathVersionKey = @"WDPathVersion";

//static NSInteger WDPathVersion = 100;
static NSString *WDPathReversedKey = @"WDPathReversed";
static NSString *WDPathClosedKey = @"WDPathClosed";
static NSString *WDPathNodesKey = @"WDPathNodes";

//static NSInteger WDPathVersion0 = 0;
NSString *WDReversedPathKey = @"WDReversedPathKey";
NSString *WDSuperpathKey = @"WDSuperpathKey";
NSString *WDNodesKey = @"WDNodesKey";
NSString *WDClosedKey = @"WDClosedKey";

@implementation WDPath

@synthesize closed = closed_;
@synthesize reversed = reversed_;
@synthesize nodes = nodes_;
@synthesize superpath = superpath_;

// to simplify rendering
@synthesize displayNodes = displayNodes_;
@synthesize displayColor = displayColor_;   
@synthesize displayClosed = displayClosed_;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		nodes_ = [[NSMutableArray alloc] init];
		boundsDirty_ = YES;
	}

	return self;
}

- (id) initWithNode:(WDBezierNode *)node
{
    self = [self init];
    if (self != nil)
	{
		[nodes_ addObject:node];
		boundsDirty_ = YES;
	}

	return self;
}




- (void) dealloc
{
    if (pathRef_) {
        CGPathRelease(pathRef_);
    }
    
    if (strokePathRef_) {
        CGPathRelease(strokePathRef_);
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:nodes_ forKey:WDNodesKey];
    [coder encodeBool:closed_ forKey:WDClosedKey];
    [coder encodeBool:reversed_ forKey:WDReversedPathKey];
    
    if (superpath_) {
        [coder encodeConditionalObject:superpath_ forKey:WDSuperpathKey];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		nodes_ = [coder decodeObjectForKey:WDNodesKey];
		closed_ = [coder decodeBoolForKey:WDClosedKey];
		reversed_ = [coder decodeBoolForKey:WDReversedPathKey];
		superpath_ = [coder decodeObjectForKey:WDSuperpathKey];

		nodes_ = [nodes_ mutableCopyWithZone:nil];

		boundsDirty_ = YES;
	}

	return self;
}


//- (id) nodes \
{ return nodes_ ? nodes_ : (nodes_ = [[NSMutableArray alloc] init]); }

- (NSMutableArray *) mutableNodes
{ return [[self nodes] mutableCopyWithZone:nil]; }

- (NSMutableArray *) reversedNodes
{
    NSMutableArray *reversed = [NSMutableArray array];
    
    for (WDBezierNode *node in [[self nodes] reverseObjectEnumerator])
	{ [reversed addObject:[node flippedNode]]; }
    
    return reversed;
}

- (NSArray *) orderedNodes
{ return reversed_ ? [self reversedNodes] : [self nodes]; }

- (NSArray *) closedNodes
{
	NSArray *nodes = [self orderedNodes];
	return [nodes arrayByAddingObject:[nodes firstObject]];
}

- (NSArray *) segmentNodes
{ return closed_ ? [self closedNodes] : [self orderedNodes]; }

////////////////////////////////////////////////////////////////////////////////

static void CGPathAddSegmentWithNodes
(CGMutablePathRef pathRef, WDBezierNode *N1, WDBezierNode *N2)
{
	if (N1 == nil)
		CGPathMoveToPoint(pathRef, NULL,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
	else
	if (N1.hasOutPoint || N2.hasInPoint)
		CGPathAddCurveToPoint(pathRef, NULL,
			N1.outPoint.x,
			N1.outPoint.y,
			N2.inPoint.x,
			N2.inPoint.y,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
	else
		CGPathAddLineToPoint(pathRef, NULL,
			N2.anchorPoint.x,
			N2.anchorPoint.y);
}

////////////////////////////////////////////////////////////////////////////////

- (void) computePathRef
{
	if (pathRef_ != nil)
	{ CGPathRelease(pathRef_); }
	pathRef_ = [self createPathRef];
}

- (CGMutablePathRef) createPathRef
{ return [self createPathRefWithNodes:[self segmentNodes]]; }

- (CGMutablePathRef) createPathRefWithNodes:(NSArray *)nodes
{
	CGMutablePathRef pathRef = CGPathCreateMutable();
	if (pathRef != nil)
	{
		WDBezierNode *lastNode = nil;

		for (WDBezierNode *nextNode in nodes)
		{
			CGPathAddSegmentWithNodes(pathRef, lastNode, nextNode);
			lastNode = nextNode;
		}

		// For closed path, objectptr is copied
		if (nodes.firstObject==nodes.lastObject)
		{ CGPathCloseSubpath(pathRef); }
	}

	return pathRef;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) insetForArrowhead:(WDArrowhead *)arrowhead
				nodes:(NSArray *)nodes
				attachment:(CGPoint *)attachment
				angle:(float *)angle
{
    NSMutableArray  *newNodes = [NSMutableArray array];
    NSInteger       numNodes = nodes.count;
    WDBezierNode    *firstNode = nodes[0];
    CGPoint         arrowTip = firstNode.anchorPoint;
    CGPoint         result;
    WDStrokeStyle   *stroke = [self effectiveStrokeStyle];
    float           t, scale = stroke.width;
    BOOL            butt = (stroke.cap == kCGLineCapButt) ? YES : NO;
    
    for (int i = 0; i < numNodes-1; i++) {
        WDBezierNode    *a = nodes[i];
        WDBezierNode    *b = nodes[i+1];
        WDBezierSegment segment = WDBezierSegmentMakeWithNodes(a, b);
        WDBezierSegment L, R;
        
        if (WDBezierSegmentPointDistantFromPoint
			(segment, [arrowhead insetLength:butt] * scale, arrowTip, &result, &t))
		{
            WDBezierSegmentSplitAtT(segment, &L, &R, t);
            [newNodes addObject:[WDBezierNode
			bezierNodeWithAnchorPoint:result
							outPoint:R.out_
							inPoint:result]];

            [newNodes addObject:[b copyWithNewInPoint:R.in_]];

            for (int n = i+2; n < numNodes; n++) {
                [newNodes addObject:nodes[n % numNodes]];
            }
            
            *attachment = result;
            CGPoint delta = WDSubtractPoints(arrowTip, result);
            *angle = atan2(delta.y, delta.x);
            
            break;
        }
    }
    
    return newNodes;
}

- (void) computeStrokePathRef
{
    WDStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    if (strokePathRef_) {
        CGPathRelease(strokePathRef_);
    }
    
    if (![stroke hasArrow]) {
        // since we don't have arrowheads, the stroke path is the same as the fill path
        strokePathRef_ = (CGMutablePathRef) CGPathRetain(self.pathRef);
        return;
    }
    
    // need to calculate arrowhead positions and inset the path appropriately
    
    NSArray *nodes = [nodes_ copy];
    if (closed_) {
        nodes = [nodes arrayByAddingObject:nodes[0]];
    }
    
    // by default, we can fit an arrow
    canFitStartArrow_ = canFitEndArrow_ = YES;
    
    // start arrow?
    WDArrowhead *startArrowhead = [WDArrowhead arrowheads][stroke.startArrow];
    if (startArrowhead) {
        nodes = [self insetForArrowhead:startArrowhead nodes:nodes attachment:&arrowStartAttachment_ angle:&arrowStartAngle_];
        // if we ate up the path, we can't fit
        canFitStartArrow_ = nodes.count;
    }
    
    // end arrow?
    WDArrowhead *endArrowhead = [WDArrowhead arrowheads][stroke.endArrow];
    if (endArrowhead && nodes.count) {
        NSMutableArray *reversed = [NSMutableArray array];
        for (WDBezierNode *node in [nodes reverseObjectEnumerator]) {
            [reversed addObject:[node flippedNode]];
        }
        
        NSArray *result = [self insetForArrowhead:endArrowhead nodes:reversed attachment:&arrowEndAttachment_ angle:&arrowEndAngle_];
        // if we ate up the path, we can't fit
        canFitEndArrow_ = result.count;
        
        if (canFitEndArrow_) {
            nodes = result;
        }
    }
    
    if (!canFitStartArrow_ || !canFitEndArrow_) {
        // we either fit both arrows or no arrows
        canFitStartArrow_ = canFitEndArrow_ = NO;
        strokePathRef_ = (CGMutablePathRef) CGPathRetain(pathRef_);
        return;
    }

    // construct the path ref from the remaining node list
    WDBezierNode    *prevNode = nil;
    BOOL            firstTime = YES;

    strokePathRef_ = CGPathCreateMutable();
    for (WDBezierNode *node in nodes) {
        if (firstTime) {
            CGPathMoveToPoint(strokePathRef_, NULL, node.anchorPoint.x, node.anchorPoint.y);
            firstTime = NO;
        } else if ([prevNode hasOutPoint] || [node hasInPoint]) {
            CGPathAddCurveToPoint(strokePathRef_, NULL, prevNode.outPoint.x, prevNode.outPoint.y,
                                  node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        } else {
            CGPathAddLineToPoint(strokePathRef_, NULL, node.anchorPoint.x, node.anchorPoint.y);
        }
        prevNode = node;
    }
}

- (CGPathRef) strokePathRef
{
    if (nodes_.count == 0) {
        return NULL;
    }
    
    if (!strokePathRef_) {
        [self computeStrokePathRef];
    }
    
    return strokePathRef_;
}

- (CGPathRef) pathRef
{
    if (nodes_.count == 0) {
        return NULL;
    }
    
    if (!pathRef_) {
        [self computePathRef];
    }
    
    return pathRef_;
}

+ (WDPath *) pathWithRect:(CGRect)R
{ return [[self alloc] initWithRect:R]; }




- (void) strokeStyleChanged
{
    [self invalidatePath];
}


+ (WDPath *) pathWithRoundedRect:(CGRect)rect cornerRadius:(float)radius
{
//	if (rect.size.width && rect.size.height)
	{ return [[WDPath alloc] initWithRoundedRect:rect cornerRadius:radius]; }
	return nil;
}

+ (WDPath *) pathWithOvalInRect:(CGRect)rect
{ return [[self alloc] initWithOvalInRect:rect]; }

+ (WDPath *) pathWithStart:(CGPoint)start end:(CGPoint)end
{
    WDPath *path = [[WDPath alloc] initWithStart:start end:end];
    return path;
}

- (id) initWithRect:(CGRect)R
{
	self = [super init];
	if (self != nil)
	{
		[self prepareWithRect:R];
	}

	return self;
}

- (BOOL) prepareWithBounds:(CGRect)B
{
	nodes_ = [[NSMutableArray alloc] init];
	bounds_ = B;
	boundsDirty_ = YES;

	return nodes_ != nil;
}

- (BOOL) prepareWithRect:(CGRect)R
{
	if ([self prepareWithBounds:R])
	{
		[self addNodeWithAnchorPoint:(CGPoint){ CGRectGetMinX(R), CGRectGetMinY(R) }];
		[self addNodeWithAnchorPoint:(CGPoint){ CGRectGetMaxX(R), CGRectGetMinY(R) }];
		[self addNodeWithAnchorPoint:(CGPoint){ CGRectGetMaxX(R), CGRectGetMaxY(R) }];
		[self addNodeWithAnchorPoint:(CGPoint){ CGRectGetMinX(R), CGRectGetMaxY(R) }];
		self.closed = YES;

		return YES;
	}

	return NO;
}




- (id) initWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)radius
{
	CGFloat W = CGRectGetWidth(rect);
	CGFloat H = CGRectGetHeight(rect);
	CGFloat maxRadius = 0.5 * MIN(W, H);

	if (radius > maxRadius)
	{ radius = maxRadius; }

	if (radius <= 0.0f)
	{ return [self initWithRect:rect]; }

	self = [self init];
	if (!self) return nil;

	W -= 2*radius;
	H -= 2*radius;


	CGPoint C, A = rect.origin;

	A.x += radius;
	C = A;
	C.x -= radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.x += W;
	C = A;
	C.x += radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.x += radius;
	A.y += radius;
	C = A;
	C.y -= radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.y += H;
	C = A;
	C.y += radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.x -= radius;
	A.y += radius;
	C = A;
	C.x += radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.x -= W;
	C = A;
	C.x -= radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	A.x -= radius;
	A.y -= radius;
	C = A;
	C.y += radius * circleFactor;

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:A inPoint:C]];

	self.closed = YES;
	bounds_ = rect;

	return self;
}

- (id) initWithOvalInRect:(CGRect)rect
{
	self = [self init];
	
	if (!self) {
		return nil;
	}

	CGPoint M = { CGRectGetMidX(rect), CGRectGetMidY(rect) };
	CGFloat rx = M.x - rect.origin.x;
	CGFloat ry = M.y - rect.origin.y;
	CGFloat cx = rx * circleFactor;
	CGFloat cy = ry * circleFactor;

	CGPoint A, B, C;

	A = (CGPoint){ M.x+rx, M.y };
	B = (CGPoint){ M.x+rx, M.y+cy };
	C = (CGPoint){ M.x+rx, M.y-cy };

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

	A = (CGPoint){ M.x,    M.y+ry };
	B = (CGPoint){ M.x-cx, M.y+ry };
	C = (CGPoint){ M.x+cx, M.y+ry };

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

	A = (CGPoint){ M.x-rx, M.y };
	B = (CGPoint){ M.x-rx, M.y-cy };
	C = (CGPoint){ M.x-rx, M.y+cy };

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

	A = (CGPoint){ M.x,    M.y-ry };
	B = (CGPoint){ M.x+cx, M.y-ry };
	C = (CGPoint){ M.x-cx, M.y-ry };

	[nodes_ addObject:[WDBezierNode
	bezierNodeWithAnchorPoint:A outPoint:B inPoint:C]];

	self.closed = YES;
	bounds_ = rect;
	
	return self;
}

- (id) initWithStart:(CGPoint)start end:(CGPoint)end
{
    self = [self init];
    
    if (!self) {
        return nil;
    }
    
    [nodes_ addObject:[WDBezierNode bezierNodeWithAnchorPoint:start]];
    [nodes_ addObject:[WDBezierNode bezierNodeWithAnchorPoint:end]];
    
 //   boundsDirty_ = YES;
    
    return self;
}

- (void) setClosedQuiet:(BOOL)closed
{
    if (closed && nodes_.count < 2) {
        // need at least 2 nodes to close a path
        return;
    }
    
    if (closed) {
        // if the first and last node have the same anchor, one is redundant
        WDBezierNode *first = [self firstNode];
        WDBezierNode *last = [self lastNode];
        if (CGPointEqualToPoint(first.anchorPoint, last.anchorPoint)) {
            WDBezierNode *closedNode =
			[first copyWithNewInPoint:last.inPoint];

            NSMutableArray *newNodes = [NSMutableArray arrayWithArray:nodes_];
            newNodes[0] = closedNode;
            [newNodes removeLastObject];
            
            self.nodes = newNodes;
        }
    }
    
    closed_ = closed;
}

- (void) setClosed:(BOOL)closed
{
    if (closed && nodes_.count < 2) {
        // need at least 2 nodes to close a path
        return;
    }
    
    [self cacheDirtyBounds];
    [[self.undoManager prepareWithInvocationTarget:self] setClosed:closed_];
    
    [self setClosedQuiet:closed];
    
    [self invalidatePath];
    [self postDirtyBoundsChange];
}

- (BOOL) addNode:(WDBezierNode *)node scale:(float)scale
{
    [self cacheDirtyBounds];
    
    if (nodes_.count && WDDistance(node.anchorPoint, ((WDBezierNode *) nodes_[0]).anchorPoint) < (kNodeSelectionTolerance / scale)) {
        self.closed = YES;
    } else {
        NSMutableArray *newNodes = [nodes_ mutableCopy];
        [newNodes addObject:node];
        self.nodes = newNodes;
    }
    
    [self postDirtyBoundsChange];
    
    return closed_;
}

- (void) addNodeWithAnchorPoint:(CGPoint)P
{ [self addNode:[WDBezierNode bezierNodeWithAnchorPoint:P]]; }

- (void) addNode:(WDBezierNode *)node
{
	if (node != nil)
	[self.nodes addObject:node];
}

- (void) replaceFirstNodeWithNode:(WDBezierNode *)node
{
    NSMutableArray *newNodes = [NSMutableArray arrayWithArray:nodes_];
    newNodes[0] = node;
    self.nodes = newNodes;
}

- (void) replaceLastNodeWithNode:(WDBezierNode *)node
{
    NSMutableArray *newNodes = [NSMutableArray arrayWithArray:nodes_];
    [newNodes removeLastObject];
    [newNodes addObject:node];
    self.nodes = newNodes;
}

- (WDBezierNode *) firstNode
{
    return nodes_[0];
}

- (WDBezierNode *) lastNode
{
    return (closed_ ? nodes_[0] : [nodes_ lastObject]); 
}

- (void) reversePathDirection
{
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] reversePathDirection];
    
    if (self.strokeStyle && [self.strokeStyle hasArrow]) {
        WDStrokeStyle *flippedArrows = [self.strokeStyle strokeStyleWithSwappedArrows];
        NSSet *changedProperties = [self changedStrokePropertiesFrom:self.strokeStyle to:flippedArrows];
        
        if (changedProperties.count) {
            [self setStrokeStyleQuiet:flippedArrows];
            [self strokeStyleChanged];
            [self propertiesChanged:changedProperties];
        }
    }
    
    reversed_ = !reversed_;
    [self invalidatePath];

    [self postDirtyBoundsChange];
}

- (void) invalidatePath
{
    if (pathRef_) {
        CGPathRelease(pathRef_);
        pathRef_ = NULL;
    }
    
    if (strokePathRef_) {
        CGPathRelease(strokePathRef_);
        strokePathRef_ = NULL;
    }
    
    if (self.superpath) {
        [self.superpath invalidatePath];
    }
    
    boundsDirty_ = YES;
}

////////////////////////////////////////////////////////////////////////////////
// alternative to CGPathGetPathBoundingBox() which didn't exist before iOS 4

- (CGRect) getPathBoundingBox
{
	CGRect bbox = CGRectNull;

	NSArray *segmentNodes = [self segmentNodes];

	WDBezierNode *lastNode = nil;
	for (WDBezierNode *nextNode in segmentNodes)
	{
		if (lastNode != nil)
		{
			//bbox = CGRectUnion(bbox,
			bbox = CGRectUnion(bbox,
				WDBezierSegmentCurveBounds(
				WDBezierSegmentMakeWithNodes(lastNode, nextNode)));
		}
		
		lastNode = nextNode;
	}

	return bbox;
}

////////////////////////////////////////////////////////////////////////////////

- (void) computeBounds
{
	//bounds_ = CGPathGetPathBoundingBox(self.pathRef);
	bounds_ = [self getPathBoundingBox];
	boundsDirty_ = NO;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{
    if (boundsDirty_) {
        [self computeBounds];
    }
    
    return bounds_;
}

////////////////////////////////////////////////////////////////////////////////

static inline CGPoint CGPointMin(CGPoint a, CGPoint b)
{ return (CGPoint){ MIN(a.x, b.x), MIN(a.y, b.y) }; }

static inline CGPoint CGPointMax(CGPoint a, CGPoint b)
{ return (CGPoint){ MAX(a.x, b.x), MAX(a.y, b.y) }; }

- (CGRect) controlBounds
{
	id nodes = [self nodes];

	CGPoint min = ((WDBezierNode *)(nodes[0])).anchorPoint;
	CGPoint max = ((WDBezierNode *)(nodes[0])).anchorPoint;

	for (WDBezierNode *node in nodes)
	{
		min = CGPointMin(min, node.inPoint);
		max = CGPointMax(max, node.inPoint);
		min = CGPointMin(min, node.anchorPoint);
		max = CGPointMax(max, node.anchorPoint);
		min = CGPointMin(min, node.outPoint);
		max = CGPointMax(max, node.outPoint);
	}
	  
	CGRect bbox = CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);

	if (self.fillTransform)
	{
		bbox = WDGrowRectToPoint(bbox, self.fillTransform.transformedStart);
		bbox = WDGrowRectToPoint(bbox, self.fillTransform.transformedEnd);
	}

	return bbox;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) subselectionBounds
{
    if (![self anyNodesSelected]) {
        return [self bounds];
    }
    
    NSArray *selected = [self selectedNodes];
    WDBezierNode *initial = [selected lastObject];
    float   minX, maxX, minY, maxY;
    
    minX = maxX = initial.anchorPoint.x;
    minY = maxY = initial.anchorPoint.y;
    
    for (WDBezierNode *node in selected) {
        minX = MIN(minX, node.anchorPoint.x);
        maxX = MAX(maxX, node.anchorPoint.x);
        minY = MIN(minY, node.anchorPoint.y);
        maxY = MAX(maxY, node.anchorPoint.y);
    }
    
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

- (WDShadow *) shadowForStyleBounds
{
    return self.superpath ? self.superpath.shadow : self.shadow;;
}

/* 
 * Bounding box of path with its style applied.
 */
- (CGRect) styleBounds
{
	CGRect R = [self bounds];

	WDStrokeStyle *strokeStyle = [self effectiveStrokeStyle];
	if (![strokeStyle willRender])
	{ return R; }

	R = [strokeStyle expandStyleBounds:R];

	// include miter joins on corners
	if (nodes_.count > 2 && strokeStyle.join == kCGLineJoinMiter) {
		NSInteger       nodeCount = closed_ ? nodes_.count + 1 : nodes_.count;
		WDBezierNode    *prev = nodes_[0];
		WDBezierNode    *curr = nodes_[1];
		WDBezierNode    *next;
		CGPoint         inPoint, outPoint, inVec, outVec;
		float           miterLength, angle;
		
		for (int i = 1; i < nodeCount; i++) {
			next = nodes_[(i+1) % nodes_.count];
			
			inPoint = [curr hasInPoint] ? curr.inPoint : prev.outPoint;
			outPoint = [curr hasOutPoint] ? curr.outPoint : next.inPoint;
			
			inVec = WDSubtractPoints(inPoint, curr.anchorPoint);
			outVec = WDSubtractPoints(outPoint, curr.anchorPoint);
			
			inVec = WDNormalizePoint(inVec);
			outVec = WDNormalizePoint(outVec);
			
			angle = acos(inVec.x * outVec.x + inVec.y * outVec.y);
			miterLength = strokeStyle.width / sin(angle / 2.0f);
			
			if ((miterLength / strokeStyle.width) < kMiterLimit) {
				CGPoint avg = WDAveragePoints(inVec, outVec);
				CGPoint directed = WDMultiplyPointScalar(WDNormalizePoint(avg), -miterLength / 2.0f);
				
				R = WDGrowRectToPoint(R, WDAddPoints(curr.anchorPoint, directed));
			}
			
			prev = curr;
			curr = next;
		}
	}

	// add in arrowheads, if any
	if ([strokeStyle hasArrow] && self.nodes && self.nodes.count) {
		float               scale = strokeStyle.width;
		CGRect              arrowBounds;
		WDArrowhead         *arrow;
		
		// make sure this computed
		[self strokePathRef];
		
		// start arrow
		if ([strokeStyle hasStartArrow]) {
			arrow = [WDArrowhead arrowheads][strokeStyle.startArrow];
			arrowBounds = [arrow boundingBoxAtPosition:arrowStartAttachment_ scale:scale angle:arrowStartAngle_
									 useAdjustment:(strokeStyle.cap == kCGLineCapButt)];
			R = CGRectUnion(R, arrowBounds);
		}
		
		// end arrow
		if ([strokeStyle hasEndArrow]) {
			arrow = [WDArrowhead arrowheads][strokeStyle.endArrow];
			arrowBounds = [arrow boundingBoxAtPosition:arrowEndAttachment_ scale:scale angle:arrowEndAngle_
									 useAdjustment:(strokeStyle.cap == kCGLineCapButt)];
			R = CGRectUnion(R, arrowBounds);
		}
	}

	return R;
	//    return [self expandStyleBounds:styleBounds];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) intersectsRect:(CGRect)R
{
	NSArray *nodes = [self segmentNodes];

	if (nodes.count == 0)
	{ return NO; }

	if (nodes.count == 1)
	{ return CGRectContainsPoint(R, [self firstNode].anchorPoint); }

	WDBezierNode *lastNode = nil;

	for (WDBezierNode *nextNode in nodes)
	{
		if (lastNode != nil)
		{
			WDBezierSegment S =
			WDBezierSegmentMakeWithNodes(lastNode, nextNode);

			if (WDBezierSegmentCurveIntersectsRect(S, R))
			{ return YES; }
		}

		lastNode = nextNode;
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (NSSet *) nodesInRect:(CGRect)rect
{
    NSMutableSet *nodesInRect = [NSMutableSet set];
    
    for (WDBezierNode *node in nodes_) {
        if (CGRectContainsPoint(rect, node.anchorPoint)) {
            [nodesInRect addObject:node];
        }
    }
    
    return nodesInRect;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) nodesWithTransform:(CGAffineTransform)T
{
	// TODO: Why would closed be different for display?
	BOOL closed = displayNodes_ ? displayClosed_ : closed_;
	NSArray *nodes = displayNodes_ ? displayNodes_ : nodes_;

    if (!nodes || nodes.count == 0) return nil;

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:nodes.count+1];

	for (WDBezierNode *node in nodes)
	{
		id newNode = [node copyWithTransform:T];
		if (newNode != nil)
		{ [result addObject:newNode]; }
	}

	if (closed)
	[result addObject:[result firstObject]];

	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (NSArray *) nodesWithTransform:(CGAffineTransform)viewTransform
				adjustmentTransform:(CGAffineTransform)adjustmentTransform
{
	// TODO: Why would closed be different for display?
	BOOL closed = displayNodes_ ? displayClosed_ : closed_;
	NSArray *nodes = displayNodes_ ? displayNodes_ : nodes_;

    if (!nodes || nodes.count == 0) return nil;

	BOOL transformAll = ![self anyNodesSelected];
	CGAffineTransform combined =
	CGAffineTransformConcat(adjustmentTransform, viewTransform);

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:nodes.count+1];

	for (WDBezierNode *node in nodes)
	{
		// Apply relevant transform
		CGAffineTransform T =
		([node selected] || transformAll) ? combined : viewTransform;

		WDBezierNode *newNode = [node copyWithTransform:T];
		if (newNode != nil)
		{ [result addObject:newNode]; }
	}

	if (closed)
	[result addObject:[result firstObject]];

	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderGLOutlineWithNodes:(NSArray *)nodes
{
	// A single point is never visible in GL outline mode
	if (nodes.count > 1)
	{
		// Build bezier segments for every 2 nodes
		long n, total = nodes.count;
		for (n=1; n!=total; n++)
		{
			WDBezierSegment segment =
			WDBezierSegmentMakeWithNodes(nodes[n-1], nodes[n]);

			WDGLQueueAddSegment(segment);
		}

		// Transfer vertexdata to openGL
		WDGLQueueFlush(GL_LINE_STRIP);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
	if (CGRectIntersectsRect(self.bounds, visibleRect))
	{
		[self renderGLOutlineWithNodes:
		[self nodesWithTransform:viewTransform]];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
	[super drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];
	
	displayColor_ ? [displayColor_ openGLSet]: [self.layer.highlightColor openGLSet];

	[self renderGLOutlineWithNodes:
	[self nodesWithTransform:viewTransform adjustmentTransform:transform]];

}



- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
    UIColor *color = displayColor_ ? displayColor_ : self.layer.highlightColor;
    NSArray *nodes = displayNodes_ ? displayNodes_ : nodes_;
    
    for (WDBezierNode *node in nodes) {
        [node drawGLWithViewTransform:transform color:color mode:kWDBezierNodeRenderClosed];
    }
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    CGAffineTransform   combined = CGAffineTransformConcat(transform, viewTransform);
    UIColor             *color = displayColor_ ? displayColor_ : self.layer.highlightColor;
    NSArray             *nodes = displayNodes_ ? displayNodes_ : nodes_;
    
    for (WDBezierNode *node in nodes) {
        if (node.selected) {
            [node drawGLWithViewTransform:combined color:color mode:kWDBezierNodeRenderSelected];
        } else {
            [node drawGLWithViewTransform:viewTransform color:color mode:kWDBezierNodeRenderOpen];
        }
    }
}

- (BOOL) anyNodesSelected
{
    for (WDBezierNode *node in nodes_) {
        if (node.selected) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) allNodesSelected
{
    for (WDBezierNode *node in nodes_) {
        if (!node.selected) {
            return NO;
        }
    }
    
    return YES;
}

- (NSSet *) alignToRect:(CGRect)rect alignment:(WDAlignment)align
{
    if (![self anyNodesSelected]) {
        return [super alignToRect:rect alignment:align];
    }
    
    CGPoint             topLeft = rect.origin;
    CGPoint             rectCenter = WDCenterOfRect(rect);
    CGPoint             bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGAffineTransform   translate = CGAffineTransformIdentity;
    NSMutableArray      *newNodes = [NSMutableArray array];
    NSMutableSet        *exchangedNodes = [NSMutableSet set];
    
    for (WDBezierNode *node in nodes_) {
        if (node.selected) {
            switch(align) {
                case WDAlignLeft:
                    translate = CGAffineTransformMakeTranslation(topLeft.x - node.anchorPoint.x, 0.0f);
                    break;
                case WDAlignCenter:
                    translate = CGAffineTransformMakeTranslation(rectCenter.x - node.anchorPoint.x, 0.0f);
                    break;
                case WDAlignRight:
                    translate = CGAffineTransformMakeTranslation(bottomRight.x - node.anchorPoint.x, 0.0f);
                    break;
                case WDAlignTop:
                    translate = CGAffineTransformMakeTranslation(0.0f, topLeft.y - node.anchorPoint.y);  
                    break;
                case WDAlignMiddle:
                    translate = CGAffineTransformMakeTranslation(0.0f, rectCenter.y - node.anchorPoint.y);
                    break;
                case WDAlignBottom:          
                    translate = CGAffineTransformMakeTranslation(0.0f, bottomRight.y - node.anchorPoint.y);
                    break;
            }
            
            WDBezierNode *alignedNode = [node copyWithTransform:translate];
            [newNodes addObject:alignedNode];
            [exchangedNodes addObject:alignedNode];
        } else {
            [newNodes addObject:node];
        }
    }

    self.nodes = newNodes;
    
    return exchangedNodes;
}

- (void) setNodes:(NSMutableArray *)nodes
{
    if ([nodes_ isEqualToArray:nodes]) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setNodes:nodes_];
    
    nodes_ = nodes;
    
    [self invalidatePath];
    
    [self postDirtyBoundsChange];
}

- (NSSet *) transform:(CGAffineTransform)transform
{
    NSMutableArray      *newNodes = [[NSMutableArray alloc] init];
    BOOL                transformAll = [self anyNodesSelected] ? NO : YES;
    NSMutableSet        *exchangedNodes = [NSMutableSet set];
    
    for (WDBezierNode *node in nodes_) {
        if (transformAll || node.selected) {
            WDBezierNode *transformed = [node copyWithTransform:transform];
            [newNodes addObject:transformed];
            
            if (node.selected) {
                [exchangedNodes addObject:transformed];
            }
        } else {
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
    
    if (transformAll) {
        // parent transforms masked elements and fill transform
        [super transform:transform];
    }
    
    return exchangedNodes;
}

- (NSArray *) selectedNodes
{   
    NSMutableArray *selected = [NSMutableArray array];
    
    for (WDBezierNode *node in nodes_) {
        if (node.selected) {
            [selected addObject:node];
        }
    }
    
    return selected;
}

// When splitting a path there are two cases. Spliting a closed path (reopen it)
// and splitting an open path (breaking it into two)
- (NSDictionary *) splitAtNode:(WDBezierNode *)node
{
    NSMutableDictionary *whatToSelect = [NSMutableDictionary dictionary];
    NSUInteger          i, startIx = [nodes_ indexOfObject:node];
    
    if (self.closed) {
        NSMutableArray  *newNodes = [NSMutableArray array];
        
        for (i = startIx; i < nodes_.count; i++) {
            [newNodes addObject:nodes_[i]];
        }
        
        for (i = 0; i < startIx; i++) {
            [newNodes addObject:nodes_[i]];
        }
        
        [newNodes addObject:[node copy]]; // copy this node since it would otherwise be shared
        
        self.nodes = newNodes;
        self.closed = NO; // can't be closed now
        
        whatToSelect[@"path"] = self;
        whatToSelect[@"node"] = [newNodes lastObject];
    } else {
        // the original path gets the first half of the original nodes
        NSMutableArray  *newNodes = [NSMutableArray array];
        for (i = 0; i < startIx; i++) {
            [newNodes addObject:nodes_[i]];
        }
        [newNodes addObject:[node copy]]; // copy this node since it would otherwise be shared
        
        // create a new path to take the rest of the nodes
        WDPath *sibling = [[WDPath alloc] init];
        NSMutableArray  *siblingNodes = [NSMutableArray array];
        for (i = startIx; i < nodes_.count; i++) {
            [siblingNodes addObject:nodes_[i]];
        }
        
        // set this after building siblingNodes so that nodes_ doesn't go away
        self.nodes = newNodes;
        
        sibling.nodes = siblingNodes;
        sibling.fill = self.fill;
        sibling.fillTransform = self.fillTransform;
        sibling.strokeStyle = self.strokeStyle;
        sibling.opacity = self.opacity;
        sibling.shadow = self.shadow;
        
        if (self.reversed) {
            [sibling reversePathDirection];
        }
        
        if (self.superpath) {
            [self.superpath addSubpath:sibling];
        } else {
            [self.layer insertObject:sibling above:self];
        }
        
        whatToSelect[@"path"] = sibling;
        whatToSelect[@"node"] = siblingNodes[0];
    }
    
    return whatToSelect;
}

- (NSDictionary *) splitAtPoint:(CGPoint)pt viewScale:(float)viewScale
{
    WDBezierNode *node = [self addAnchorAtPoint:pt viewScale:viewScale];
    
    return [self splitAtNode:node];
}


- (WDBezierNode *) addAnchorAtPoint:(CGPoint)pt viewScale:(float)viewScale
{
	NSArray *nodes = closed_ ? [self closedNodes] : [self nodes];

	if (nodes.count <= 1) return nil;

	// Initialize 1 segment for every 2 nodes
	NSUInteger numSegments = nodes.count-1;

	// Attempt to find segment within tolerance
	CGFloat tolerance = kNodeSelectionTolerance / viewScale;
	long targetIndex = -1;
	WDFindInfo targetInfo;
	WDBezierSegment targetSegment;

	// Traverse segments
	for (NSUInteger i=0; i!=numSegments; i++)
	{
		// Create test segment
		WDBezierSegment testSegment =
		WDBezierSegmentMakeWithNodes(nodes[i], nodes[i+1]);
		// Test against incoming point
		WDFindInfo info =
		WDBezierSegmentFindClosestPoint(testSegment, pt);

		if (info.D <= tolerance)
		{
			targetIndex = i;
			targetSegment = testSegment;
			targetInfo = info;
		}
	}

	// Split target segment if found
	if (targetIndex != -1)
	{
		WDBezierSegment L, R;
		// Split target segment
		WDBezierSegmentSplitAtT(targetSegment, &L, &R, targetInfo.t);

		WDBezierNode *targetNode1 = nodes[targetIndex+0];
		WDBezierNode *targetNode2 = nodes[targetIndex+1];

		// Adjusting by reference would automatically propagate changes
		//targetNode1->outPoint_ = L.out_;
		//targetNode2->inPoint_ = R.in_;

		// This shouldn't be necessary, as there is no need for immutable nodes
		targetNode1 = [targetNode1 copyWithNewOutPoint:L.out_];
		targetNode2 = [targetNode2 copyWithNewInPoint:R.in_];

		NSMutableArray *newNodes = [[self nodes] mutableCopyWithZone:nil];

		[newNodes replaceObjectAtIndex:(targetIndex+0)
			withObject:targetNode1];
		[newNodes replaceObjectAtIndex:(targetIndex+1)%newNodes.count
			withObject:targetNode2];

//		CGPoint P[] = { L.in_, R.a_, R.out_ };
		WDBezierNode *newNode = [WDBezierNode
		bezierNodeWithAnchorPoint:R.a_ outPoint:R.out_ inPoint:L.in_];

		[newNodes insertObject:newNode atIndex:targetIndex+1];

		self.nodes = newNodes;

		return newNode;
	}

	return nil;
}


- (WDBezierNode *) _addAnchorAtPoint:(CGPoint)pt viewScale:(float)viewScale
{
	NSMutableArray      *newNodes = [NSMutableArray array];
	NSInteger           numNodes = closed_ ? (nodes_.count + 1) : nodes_.count;
	NSInteger           numSegments = numNodes; // includes an extra one for the one that gets split
	WDBezierSegment     segments[numSegments];
	WDBezierSegment     segment;
	WDBezierNode        *prev, *curr, *node, *newestNode = nil;
	NSUInteger          newestNodeSegmentIx = 0, segmentIndex = 0;
	float               t;
	BOOL                added = NO;

	prev = nodes_[0];
	for (int i = 1; i < numNodes; i++, segmentIndex ++) {
		curr = nodes_[(i % nodes_.count)];
		
		segment = WDBezierSegmentMakeWithNodes(prev, curr);
		
		if (!added && WDBezierSegmentFindPointOnSegment(segment, pt, kNodeSelectionTolerance / viewScale, NULL, &t)) {
			WDBezierSegmentSplitAtT(segment,  &segments[segmentIndex], &segments[segmentIndex+1], t);
			segmentIndex++;
			newestNodeSegmentIx = segmentIndex;
			added = YES;
		} else {
			segments[segmentIndex] = segment;
		}
		
		prev = curr;
	}

	// convert the segments back to nodes
	for (int i = 0; i < numSegments; i++) {
		if (i == 0)
		{
			CGPoint inPoint = closed_ ? segments[numSegments - 1].in_ : [self firstNode].inPoint;

			node = [WDBezierNode
			bezierNodeWithAnchorPoint:segments[i].a_
			outPoint:segments[i].out_ inPoint:inPoint];
		}
		else
		{
			node = [WDBezierNode
			bezierNodeWithAnchorPoint:segments[i].a_
			outPoint:segments[i].out_ inPoint:segments[i-1].in_];
		}
		
		[newNodes addObject:node];
		
		if (i == newestNodeSegmentIx) {
			newestNode = node;
		}
		
		if (i == (numSegments - 1) && !closed_)
		{
			node = [WDBezierNode
			bezierNodeWithAnchorPoint:segments[i].b_
			outPoint:[self lastNode].outPoint inPoint:segments[i].in_];
			[newNodes addObject:node];
		}
	}

	self.nodes = newNodes;

	return newestNode;
}

- (void) addAnchors
{
    NSMutableArray      *newNodes = [NSMutableArray array];
    NSInteger           numNodes = closed_ ? (nodes_.count + 1) : nodes_.count;
    NSInteger           numSegments = (numNodes - 1) * 2;
    WDBezierSegment     segments[numSegments];
    WDBezierSegment     segment;
    WDBezierNode        *prev, *curr, *node;
    NSUInteger          segmentIndex = 0;
    
    prev = nodes_[0];
    for (int i = 1; i < numNodes; i++, segmentIndex += 2) {
        curr = nodes_[(i % nodes_.count)];
        
        segment = WDBezierSegmentMakeWithNodes(prev, curr);
        WDBezierSegmentSplitAtT(segment, &segments[segmentIndex], &segments[segmentIndex+1], 0.5);
        
        prev = curr;
    }
    
    // convert the segments back to nodes
    for (int i = 0; i < numSegments; i++) {
        if (i == 0) {
            CGPoint inPoint = closed_ ? segments[numSegments - 1].in_ : [self firstNode].inPoint;
            node = [WDBezierNode bezierNodeWithInPoint:inPoint anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        } else {
            node = [WDBezierNode bezierNodeWithInPoint:segments[i-1].in_ anchorPoint:segments[i].a_ outPoint:segments[i].out_];
        }
        
        [newNodes addObject:node];
        
        if (i == (numSegments - 1) && !closed_) {
            node = [WDBezierNode bezierNodeWithInPoint:segments[i].in_ anchorPoint:segments[i].b_ outPoint:[self lastNode].outPoint];
            [newNodes addObject:node];
        }
    }
    
    self.nodes = newNodes;
}

- (BOOL) canDeleteAnchors
{
    NSUInteger unselectedCount = 0;
    NSUInteger selectedCount = 0;
    
    for (WDBezierNode *node in nodes_) {
        if (!node.selected) {
            unselectedCount++;
        } else {
            selectedCount++;
        }
        
        if (unselectedCount >= 2 && selectedCount > 0) {
            return YES;
        }
    }
    
    return NO;
}

- (void) deleteAnchor:(WDBezierNode *)node
{
    if (nodes_.count > 2) {
        NSMutableArray *newNodes = [nodes_ mutableCopy];
        [newNodes removeObject:node];
        self.nodes = newNodes;
    }
}

- (void) deleteAnchors
{   
    NSMutableArray *newNodes = [nodes_ mutableCopy];
    [newNodes removeObjectsInArray:[self selectedNodes]];
    self.nodes = newNodes;
}

- (void) appendPath:(WDPath *)path
{
    NSArray     *baseNodes, *nodesToAdd;
    CGPoint     delta;
    BOOL        reverseMyNodes = YES;
    BOOL        reverseIncomingNodes = NO;
    float       distance, minDistance = WDDistance([self firstNode].anchorPoint, [path firstNode].anchorPoint);
    
    // find the closest pair of end points
    distance = WDDistance([self firstNode].anchorPoint, [path lastNode].anchorPoint);
    if (distance < minDistance) {
        minDistance = distance;
        reverseIncomingNodes = YES;
    }
    
    distance = WDDistance([path firstNode].anchorPoint, [self lastNode].anchorPoint);
    if (distance < minDistance) {
        minDistance = distance;
        reverseMyNodes = NO;
        reverseIncomingNodes = NO;
    }
    
    distance = WDDistance([path lastNode].anchorPoint, [self lastNode].anchorPoint);
    if (distance < minDistance) {
        reverseMyNodes = NO;
        reverseIncomingNodes = YES;
    }
    
    baseNodes = reverseMyNodes ? self.reversedNodes : self.nodes;
    nodesToAdd = reverseIncomingNodes ? path.reversedNodes : path.nodes;
    
    // add the base nodes (up to the shared node) to the new nodes
    NSMutableArray *newNodes = [NSMutableArray array];
    for (int i = 0; i < baseNodes.count - 1; i++) {
        [newNodes addObject:baseNodes[i]];
    }
    
    // compute the translation necessary to align the incoming path
    WDBezierNode *lastNode = [baseNodes lastObject];
    WDBezierNode *firstNode = nodesToAdd[0];
    delta = WDSubtractPoints(lastNode.anchorPoint, firstNode.anchorPoint);
    CGAffineTransform transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    
    // add the shared node (combine the handles appropriately)
    firstNode = [firstNode copyWithTransform:transform];
    [newNodes addObject:[WDBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:firstNode.anchorPoint outPoint:firstNode.outPoint]];
    
    // add the incoming path's nodes
    for (int i = 1; i < nodesToAdd.count; i++) {
        [newNodes addObject:[nodesToAdd[i] transform:transform]];
    }
    
    // see if the last node is the same as the first node
    firstNode = newNodes[0];
    lastNode = [newNodes lastObject];
    
    if (WDDistance(firstNode.anchorPoint, lastNode.anchorPoint) < 0.5f) {
        WDBezierNode *closedNode = [WDBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:firstNode.anchorPoint outPoint:firstNode.outPoint];
        newNodes[0] = closedNode;
        [newNodes removeLastObject];
        self.closed = YES;
    }
    
    self.nodes = newNodes;
}

- (WDBezierNode *) convertNode:(WDBezierNode *)node whichPoint:(WDPickResultType)whichPoint
{
    WDBezierNode     *newNode = nil;
    
    if (whichPoint == kWDInPoint) {
        newNode = [node chopInHandle];
    } else if (whichPoint == kWDOutPoint) {
        newNode = [node chopOutHandle];
    } else {
        if (node.hasInPoint || node.hasOutPoint) {
            newNode = [node chopHandles];
        } else {
            NSInteger ix = [nodes_ indexOfObject:node];
            NSInteger pix, nix;
            WDBezierNode *prev = nil, *next = nil;
            
            pix = ix - 1;
            if (pix >= 0) {
                prev = nodes_[pix];
            } else if (closed_ && nodes_.count > 2) {
                prev = [nodes_ lastObject];
            }
            
            nix = ix + 1;
            if (nix < nodes_.count) {
                next = nodes_[nix];
            } else if (closed_ && nodes_.count > 2) {
                next = nodes_[0];
            }
            
            if (!prev) {
                prev = node;
            }
            
            if (!next) {
                next = node;
            }
            
            if (prev && next) {
                CGPoint    vector = WDSubtractPoints(next.anchorPoint, prev.anchorPoint);
                float      magnitude = WDDistance(vector, CGPointZero);
                
                vector = WDNormalizePoint(vector);
                vector = WDMultiplyPointScalar(vector, magnitude / 4.0f);
                
                newNode = [WDBezierNode bezierNodeWithInPoint:WDSubtractPoints(node.anchorPoint, vector) anchorPoint:node.anchorPoint outPoint:WDAddPoints(node.anchorPoint, vector)];
            }
        }
    }
    
    NSMutableArray *newNodes = [NSMutableArray array];
    for (WDBezierNode *oldNode in nodes_) {
        if (node == oldNode) {
            [newNodes addObject:newNode];
        } else {
            [newNodes addObject:oldNode];
        }
    }
    
    self.nodes = newNodes;
    
    return newNode;
}

- (BOOL) hasFill
{
    return [super hasFill] || self.maskedElements;
}

- (WDPickResult *) hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
    WDPickResult        *result = [WDPickResult pickResult];
    CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    float               distance, minDistance = MAXFLOAT;
    float               tolerance = kNodeSelectionTolerance / viewScale;
    
    if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
        return result;
    }
    
    if (flags & kWDSnapNodes) {
        // look for fill control points
        if (self.fillTransform) {
            distance = WDDistance([self.fillTransform transformedStart], point);
            if (distance < MIN(tolerance, minDistance)) {
                result.type = kWDFillStartPoint;
                minDistance = distance;
            }
            
            distance = WDDistance([self.fillTransform transformedEnd], point);
            if (distance < MIN(tolerance, minDistance)) {
                result.type = kWDFillEndPoint;
                minDistance = distance;
            }
        }
        
        // pre-existing selected node gets first crack
        for (WDBezierNode *selectedNode in [self selectedNodes]) {
            distance = WDDistance(selectedNode.anchorPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = kWDAnchorPoint;
                minDistance = distance;
            }
            
            distance = WDDistance(selectedNode.outPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = kWDOutPoint;
                minDistance = distance;
            }
            
            distance = WDDistance(selectedNode.inPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = selectedNode;
                result.type = kWDInPoint;
                minDistance = distance;
            } 
        }
        
        for (WDBezierNode *node in nodes_) {
            distance = WDDistance(node.anchorPoint, point);
            if (distance < MIN(tolerance, minDistance)) {
                result.node = node;
                result.type = kWDAnchorPoint;
                minDistance = distance;
            }
        }
        
        if (result.type != kWDEther) {
            result.element = self;
            return result;
        }
    }
    
    if (flags & kWDSnapEdges) {
        // check path edges
        NSInteger           numNodes = closed_ ? nodes_.count : nodes_.count - 1;
        WDBezierSegment     segment;
        
        for (int i = 0; i < numNodes; i++) {
            WDBezierNode    *a = nodes_[i];
            WDBezierNode    *b = nodes_[(i+1) % nodes_.count];
            CGPoint         nearest;
            
            segment.a_ = a.anchorPoint;
            segment.out_ = a.outPoint;
            segment.in_ = b.inPoint;
            segment.b_ = b.anchorPoint;
            
            if (WDBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                result.element = self;
                result.type = kWDEdge;
                result.snappedPoint = nearest;
                
                return result;
            }
        }
    }
    
    if ((flags & kWDSnapFills) && ([self hasFill])) {
        if (CGPathContainsPoint(self.pathRef, NULL, point, self.fillRule)) {
            result.element = self;
            result.type = kWDObjectFill;
            return result;
        }
    }
    
    return result;
}

- (WDPickResult *) snappedPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
    WDPickResult        *result = [WDPickResult pickResult];
    CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    
    if (!CGRectIntersectsRect(pointRect, [self controlBounds])) {
        return result;
    }
    
    if (flags & kWDSnapNodes) {
        for (WDBezierNode *node in nodes_) {
            if (WDDistance(node.anchorPoint, point) < (kNodeSelectionTolerance / viewScale)) {
                result.element = self;
                result.node = node;
                result.type = kWDAnchorPoint;
                result.nodePosition = kWDMiddleNode;
                result.snappedPoint = node.anchorPoint;
                
                if (!closed_) {
                    if (node == nodes_[0]) {
                        result.nodePosition = kWDFirstNode;
                    } else if (node == [nodes_ lastObject]) {
                        result.nodePosition = kWDLastNode;
                    }
                }
                
                return result;
            }
        }
    }
    
    if (flags & kWDSnapEdges) {
        // check path edges
        NSInteger           numNodes = closed_ ? nodes_.count : nodes_.count - 1;
        WDBezierSegment     segment;
        
        
        for (int i = 0; i < numNodes; i++) {
            WDBezierNode    *a = nodes_[i];
            WDBezierNode    *b = nodes_[(i+1) % nodes_.count];
            CGPoint         nearest;
            
            segment.a_ = a.anchorPoint;
            segment.out_ = a.outPoint;
            segment.in_ = b.inPoint;
            segment.b_ = b.anchorPoint;
            
            if (WDBezierSegmentFindPointOnSegment(segment, point, kNodeSelectionTolerance / viewScale, &nearest, NULL)) {
                result.element = self;
                result.type = kWDEdge;
                result.snappedPoint = nearest;
                
                return result;
            }
        }
    }
    
    return result;
}

- (void) setSuperpath:(WDCompoundPath *)superpath
{
    [[self.undoManager prepareWithInvocationTarget:self] setSuperpath:superpath_];
    
    superpath_ = superpath;
    
    if (superpath) {
        self.fill = nil;
        self.strokeStyle = nil;
        self.fillTransform = nil;
        self.shadow = nil;
    }
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager
{
    if (self.superpath) {
        [self.superpath setValue:value forProperty:property propertyManager:propertyManager];
        return;
    }
    
    return [super setValue:value forProperty:property propertyManager:propertyManager];
}

- (id) valueForProperty:(NSString *)property
{
    if (self.superpath) {
        return [self.superpath valueForProperty:property];
    }
    
    return [super valueForProperty:property];
}

- (BOOL) canPlaceText
{
    return (!self.superpath && !self.maskedElements);
}

- (NSArray *) erase:(WDAbstractPath *)erasePath
{
    if (self.closed) {
        WDAbstractPath *result = [WDPathfinder combinePaths:@[self, erasePath] operation:WDPathFinderSubtract];
        
        if (!result) {
            return @[];
        }
        
        [result takeStylePropertiesFrom:self];
        
        if (self.superpath && [result isKindOfClass:[WDCompoundPath class]]) {
            WDCompoundPath *cp = (WDCompoundPath *)result;
            [[cp subpaths] makeObjectsPerformSelector:@selector(setSuperpath:) withObject:nil];
            return cp.subpaths;
        }
        
        return @[result];
    } else {
        if (!CGRectIntersectsRect(self.bounds, erasePath.bounds)) {
            WDPath *clone = [[WDPath alloc] init];
            [clone takeStylePropertiesFrom:self];
            NSMutableArray *nodes = [self.nodes mutableCopy];
            clone.nodes = nodes;
            
            NSArray *result = @[clone];
            return result;
        }
        
        // break down path
        NSArray             *nodes = reversed_ ? [self reversedNodes] : nodes_;
        NSInteger           segmentCount = nodes.count - 1;
        WDBezierSegment     segments[segmentCount]; 
        
        WDBezierSegment     *splitSegments;
        NSUInteger          splitSegmentSize = 256;
        int                 splitSegmentIx = 0;
        
        WDBezierNode        *prev, *curr;
        
        // this might need to grow, so dynamically allocate it
        splitSegments = calloc(sizeof(WDBezierSegment), splitSegmentSize);
        
        prev = nodes[0];
        for (int i = 1; i < nodes.count; i++, prev = curr) {
            curr = nodes[i];
            segments[i-1] = WDBezierSegmentMakeWithNodes(prev, curr);
        }
        
        erasePath = [erasePath pathByFlatteningPath];
        
        WDBezierSegment     L, R;
        NSArray             *subpaths = [erasePath isKindOfClass:[WDPath class]] ? @[erasePath] : [(WDCompoundPath *)erasePath subpaths];
        float               smallestT, t;
        BOOL                intersected;
        
        for (int i = 0; i < segmentCount; i++) {
            smallestT = MAXFLOAT;
            intersected = NO;
            
            // split the segments into more segments at every intersection with the erasing path
            for (WDPath *subpath in subpaths) {
                prev = (subpath.nodes)[0];
                
                for (int n = 1; n < subpath.nodes.count; n++, prev = curr) {
                    curr = (subpath.nodes)[n];
                    
                    if (WDBezierSegmentGetIntersection(segments[i], prev.anchorPoint, curr.anchorPoint, &t)) {
                        if (t < smallestT && (fabs(t) > 0.001)) {
                            smallestT = t;
                            intersected = YES;
                        }
                    }
                }
            }
                
            if (!intersected || fabs(1 - smallestT) < 0.001) {
                splitSegments[splitSegmentIx++] = segments[i];
            } else {
                WDBezierSegmentSplitAtT(segments[i], &L, &R, smallestT);
                                    
                splitSegments[splitSegmentIx++] = L;
                segments[i] = R;
                i--;
            }
            
            if (splitSegmentIx >= splitSegmentSize) {
                splitSegmentSize *= 2;
                splitSegments = realloc(splitSegments, sizeof(WDBezierSegment) * splitSegmentSize);
            }
        }
        
        // toss out any segment that's inside the erase path
        WDBezierSegment newSegments[splitSegmentIx];
        int             newSegmentIx = 0;
        
        for (int i = 0; i < splitSegmentIx; i++) {
            CGPoint midPoint = WDBezierSegmentSplitAtT(splitSegments[i], NULL, NULL, 0.5);
            
            if (![erasePath containsPoint:midPoint]) {
                newSegments[newSegmentIx++] = splitSegments[i];
            }
        }

        // clean up
        free(splitSegments);
                    
        if (newSegmentIx == 0) {
            return @[];
        }
        
        // reassemble segments
        NSMutableArray  *array = [NSMutableArray array];
        WDPath          *currentPath = [[WDPath alloc] init];
        
        [currentPath takeStylePropertiesFrom:self];
        [array addObject:currentPath];
        
        for (int i = 0; i < newSegmentIx; i++) {
            WDBezierNode *lastNode = [currentPath lastNode];
            
            if (!lastNode) {            
                [currentPath addNode:[WDBezierNode bezierNodeWithInPoint:newSegments[i].a_ anchorPoint:newSegments[i].a_ outPoint:newSegments[i].out_]];
            } else if (CGPointEqualToPoint(lastNode.anchorPoint, newSegments[i].a_)) {
                [currentPath replaceLastNodeWithNode:[WDBezierNode bezierNodeWithInPoint:lastNode.inPoint anchorPoint:lastNode.anchorPoint outPoint:newSegments[i].out_]];
            } else {
                currentPath = [[WDPath alloc] init];
                [currentPath takeStylePropertiesFrom:self];
                [array addObject:currentPath];
                
                [currentPath addNode:[WDBezierNode bezierNodeWithInPoint:newSegments[i].a_ anchorPoint:newSegments[i].a_ outPoint:newSegments[i].out_]];
            }
            
            [currentPath addNode:[WDBezierNode bezierNodeWithInPoint:newSegments[i].in_ anchorPoint:newSegments[i].b_ outPoint:newSegments[i].b_]];
        }
        
        return array;
    }
}

- (void) simplify
{
    // strip collinear anchors
    
    if (nodes_.count < 3) {
        return;
    }
    
    NSMutableArray  *newNodes = [NSMutableArray array];
    WDBezierNode    *current, *next, *nextnext;
    NSInteger       nodeCount = closed_ ? nodes_.count + 1 : nodes_.count;
    NSInteger       ix = 0;
    
    current = nodes_[ix++];
    next = nodes_[ix++];
    nextnext = nodes_[ix++];
    
    [newNodes addObject:current];
    
    while (nextnext) {
        if (!WDCollinear(current.anchorPoint, current.outPoint, next.inPoint) ||
            !WDCollinear(current.anchorPoint, next.inPoint, next.anchorPoint) ||
            !WDCollinear(current.anchorPoint, next.anchorPoint, next.outPoint) ||
            !WDCollinear(current.anchorPoint, next.anchorPoint, nextnext.inPoint) ||
            !WDCollinear(current.anchorPoint, next.anchorPoint, nextnext.anchorPoint))
        {
            // can't remove the node, add it and move on
            [newNodes addObject:next];
            current = next;
        }
        
        next = nextnext;
        
        if (ix < nodeCount) {
            nextnext = nodes_[(ix % nodes_.count)];
        } else {
            nextnext = nil;
        }
        
        ix++;
    }
    
    if (!closed_) {
        [newNodes addObject:next];
    }
    
    if (closed_) {
        // see if we should remove the first node
        current = [nodes_ lastObject];
        next = nodes_[0];
        nextnext = nodes_[1];
        
        if (WDCollinear(current.anchorPoint, current.outPoint, next.inPoint) &&
            WDCollinear(current.anchorPoint, next.inPoint, next.anchorPoint) &&
            WDCollinear(current.anchorPoint, next.anchorPoint, next.outPoint) &&
            WDCollinear(current.anchorPoint, next.anchorPoint, nextnext.inPoint) &&
            WDCollinear(current.anchorPoint, next.anchorPoint, nextnext.anchorPoint))
        {
            [newNodes removeObjectAtIndex:0];
        }
    }
    
    self.nodes = newNodes;
}

////////////////////////////////////////////////////////////////////////////////

- (NSMutableArray *) flattenedNodes
{
	NSMutableArray *flatNodes = [NSMutableArray array];

	NSInteger numNodes = closed_ ? nodes_.count : nodes_.count - 1;

	for (int i = 0; i < numNodes; i++)
	{
		WDBezierNode *a = nodes_[i];
		WDBezierNode *b = nodes_[(i+1) % nodes_.count];
		WDBezierSegment S = WDBezierSegmentMakeWithNodes(a, b);

		[flatNodes addObject:
		[WDBezierNode bezierNodeWithAnchorPoint:S.a_]];

		WDBezierSegmentSplitWithBlock(S,
		^BOOL(WDBezierSegment subSegment)
		{
			if (WDBezierSegmentIsFlat(subSegment, kDefaultFlatness))
			{
				[flatNodes addObject:
				[WDBezierNode bezierNodeWithAnchorPoint:subSegment.b_]];
				return NO;
			}
			return YES;
		});
	}

	return flatNodes;
}

////////////////////////////////////////////////////////////////////////////////

- (void) flatten
{
    self.nodes = [self flattenedNodes];
}

- (WDAbstractPath *) pathByFlatteningPath
{
    WDPath *flatPath = [[WDPath alloc] init];
    
    flatPath.nodes = [self flattenedNodes];
    
    return flatPath;
}

- (NSString *) nodeSVGRepresentation
{
    NSArray         *nodes = reversed_ ? [self reversedNodes] : nodes_;
    WDBezierNode    *node;
    NSInteger       numNodes = closed_ ? nodes.count + 1 : nodes.count;
    CGPoint         pt, prev_pt, in_pt, prev_out;
    NSMutableString *svg = [NSMutableString string];
    
    for(int i = 0; i < numNodes; i++) {
        node = nodes[(i % nodes.count)];
        
        if (i == 0) {
            pt = node.anchorPoint;
            [svg appendString:[NSString stringWithFormat:@"M%g%+g", pt.x, pt.y]];
        } else {
            pt = node.anchorPoint;
            in_pt = node.inPoint;
            
            if (prev_pt.x == prev_out.x && prev_pt.y == prev_out.y && in_pt.x == pt.x && in_pt.y == pt.y) {
            	[svg appendString:[NSString stringWithFormat:@"L%g%+g", pt.x, pt.y]];
            } else {
            	[svg appendString:[NSString stringWithFormat:@"C%g%+g%+g%+g%+g%+g",
                                   prev_out.x, prev_out.y, in_pt.x, in_pt.y, pt.x, pt.y]];
            }       
        }
        
        prev_out = node.outPoint;
        prev_pt = pt; 
    }
    
    if (closed_) {
        [svg appendString:@"Z"];
    }
    
    return svg;
}

- (id) copyWithZone:(NSZone *)zone
{       
    WDPath *path = [super copyWithZone:zone];
    
    path->nodes_ = [nodes_ mutableCopy];
    path->closed_ = closed_;
    path->reversed_ = reversed_;
    path->boundsDirty_ = YES;

    return path;
}

- (WDStrokeStyle *) effectiveStrokeStyle
{
    return self.superpath ? self.superpath.strokeStyle : self.strokeStyle;
}

- (void) addSVGArrowheadPath:(CGPathRef)pathRef toGroup:(WDXMLElement *)group
{
    WDAbstractPath  *inkpadPath = [WDAbstractPath pathWithCGPathRef:pathRef];
    WDStrokeStyle   *stroke = [self effectiveStrokeStyle];
    
    WDXMLElement *arrowPath = [WDXMLElement elementWithName:@"path"];
    [arrowPath setAttribute:@"d" value:[inkpadPath nodeSVGRepresentation]];
    [arrowPath setAttribute:@"fill" value:[stroke.color hexValue]];
    [group addChild:arrowPath];
}

- (void) addSVGArrowheadsToGroup:(WDXMLElement *)group
{
    WDStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    WDArrowhead *arrow = [WDArrowhead arrowheads][stroke.startArrow];
    if (arrow) {
        CGMutablePathRef pathRef = CGPathCreateMutable();
        [arrow addToMutablePath:pathRef position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
              useAdjustment:(stroke.cap == kCGLineCapButt)];
        [self addSVGArrowheadPath:pathRef toGroup:group];
        CGPathRelease(pathRef);
    }
    
    arrow = [WDArrowhead arrowheads][stroke.endArrow];
    if (arrow) {
        CGMutablePathRef pathRef = CGPathCreateMutable();
        [arrow addToMutablePath:pathRef position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
              useAdjustment:(stroke.cap == kCGLineCapButt)];
        [self addSVGArrowheadPath:pathRef toGroup:group];
        CGPathRelease(pathRef);
    }
}

//#define DEBUG_ATTACHMENTS YES

- (void) renderStrokeInContext:(CGContextRef)ctx
{
    WDStrokeStyle *stroke = [self effectiveStrokeStyle];
    
    if (!stroke.hasArrow) {
        [super renderStrokeInContext:ctx];
        return;
    }
    
#ifdef DEBUG_ATTACHMENTS
    // this will show the arrowhead overlapping the stroke if the stroke color is semi-transparent
    [super renderStrokeInContext:ctx];
#else
    // normally we want the stroke and arrowhead to appear unified, even with a semi-transparent stroke color
    CGContextAddPath(ctx, self.strokePathRef);
    [stroke applyInContext:ctx];
    
    CGContextReplacePathWithStrokedPath(ctx);
#endif
    CGContextSetFillColorWithColor(ctx, stroke.color.CGColor);
    
    WDArrowhead *arrow = [WDArrowhead arrowheads][stroke.startArrow];
    if (canFitStartArrow_ && arrow) {
        [arrow addArrowInContext:ctx position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
               useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
    
    arrow = [WDArrowhead arrowheads][stroke.endArrow];
    if (canFitEndArrow_ && arrow) {
        [arrow addArrowInContext:ctx position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
               useAdjustment:(stroke.cap == kCGLineCapButt)];
    }

    CGContextFillPath(ctx);
}

- (void) addElementsToOutlinedStroke:(CGMutablePathRef)outline
{
    WDStrokeStyle   *stroke = [self effectiveStrokeStyle];
    WDArrowhead     *arrow;
    
    if (![stroke hasArrow]) {
        // no arrows...
        return;
    }
    
    if ([stroke hasStartArrow]) {
        arrow = [WDArrowhead arrowheads][stroke.startArrow];
        [arrow addToMutablePath:outline position:arrowStartAttachment_ scale:stroke.width angle:arrowStartAngle_
              useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
    
    if ([stroke hasEndArrow]) {
        arrow = [WDArrowhead arrowheads][stroke.endArrow];
        [arrow addToMutablePath:outline position:arrowEndAttachment_ scale:stroke.width angle:arrowEndAngle_
              useAdjustment:(stroke.cap == kCGLineCapButt)];
    }
}

@end
