//
//  WDCurveFit.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2014 Steve Sprang
//

#import "FitCurves.h"
#import "WDBezierNode.h"
#import "WDBezierSegment.h"
#import "WDCurveFit.h"
#import "WDPath.h"
#import "WDUtilities.h"

@implementation WDCurveFit

+ (WDPath *) smoothPathForPoints:(NSArray *)inPoints error:(float)epsilon attemptToClose:(BOOL)shouldClose
{
    NSMutableArray  *points = [inPoints mutableCopy];
    CGPoint         unboxedPts[points.count];
    BOOL            closePath = NO;
    int             ix = 0;
    
    // transfer the wrapped CGPoints to an unboxed array
    for (NSValue *value in points) {
        unboxedPts[ix++] = [value CGPointValue];
    }
    
    // see if this path should be closed, and if so, average the first and last points
    if (shouldClose && points.count > 3) {
        CGPoint first = unboxedPts[0];
        CGPoint last = unboxedPts[points.count - 1];
        
        if (WDDistance(first, last) < (epsilon * 2)) {
            closePath = YES;
            unboxedPts[0] = WDAveragePoints(first, last);
            unboxedPts[points.count - 1] = unboxedPts[0];
        }
    }
    
    // finally, do the actual curve fitting!
    WDBezierSegment segments[points.count];
    int numSegments = FitCurve(segments, unboxedPts, (int) points.count, epsilon);
    
    // ... and turn those segments into an Inkpad path
    return [WDCurveFit pathFromSegments:segments numSegments:numSegments closePath:closePath];
}

//
// construct a node array from a sequence of bezier segments
//
+ (WDPath *) pathFromSegments:(WDBezierSegment *)segments
				  numSegments:(NSUInteger)numSegments
				    closePath:(BOOL)closePath
{
	NSMutableArray *nodes = [NSMutableArray array];

	WDBezierNode *node = [WDBezierNode
	bezierNodeWithAnchorPoint:segments[0].a_
					outPoint:segments[0].out_];

	if (closePath)
	node = [WDBezierNode
	bezierNodeWithAnchorPoint:segments[0].a_
					 outPoint:segments[0].out_
					 inPoint:segments[numSegments-1].in_];

	if (node != nil)
	[nodes addObject:node];

	for (int i = 1; i != numSegments; i++)
	{
		node = [WDBezierNode
		bezierNodeWithAnchorPoint:segments[i].a_
						outPoint:segments[i].out_
						inPoint:segments[i-1].in_];

		if (node != nil)
		[nodes addObject:node];
	}

	if (nodes.count < 2) {
		// degenerate path
		return nil;
	}

	if (closePath) {
		node = nodes[0];
		
		// fix up the control handles on the start/end node...
		// we want them to be collinear but preserve the original magnitudes
		
		CGPoint outDelta = WDSubtractPoints(node.outPoint, node.anchorPoint);
		CGPoint inDelta = WDSubtractPoints(node.inPoint, node.anchorPoint);
		
		CGPoint newIn = WDAveragePoints(inDelta, WDMultiplyPointScalar(outDelta, -1));
		newIn = WDScaleVector(newIn, WDMagnitude(inDelta));
		
		CGPoint newOut = WDAveragePoints(outDelta, WDMultiplyPointScalar(inDelta, -1));
		newOut = WDScaleVector(newOut, WDMagnitude(outDelta));
		
		nodes[0] = [WDBezierNode
		bezierNodeWithAnchorPoint:node.anchorPoint
						 outPoint:WDAddPoints(node.anchorPoint, newOut)
						  inPoint:WDAddPoints(node.anchorPoint, newIn)];
	}

	WDPath *path = [[WDPath alloc] init];
	path.nodes = nodes;
	path.closed = closePath;

	return path;
}

@end
