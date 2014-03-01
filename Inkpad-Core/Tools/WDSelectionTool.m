//
//  WDSelectionTool.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDAbstractPath.h"
#import "WDBezierNode.h"
#import "WDCanvas.h"
#import "WDCanvasController.h"
#import "WDCompoundPath.h"
#import "WDDrawingController.h"
#import "WDFillTransform.h"
#import "WDPath.h"
#import "WDPropertyManager.h"
#import "WDSelectionTool.h"
#import "WDTextPath.h"
#import "WDUtilities.h"
#import "WDShape.h"
#import "WDShapeOptionsController.h"

@implementation WDSelectionTool

@synthesize groupSelect = groupSelect_;

- (BOOL) shouldAppendSelection
{ return groupSelect_; }



- (id) init
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	transform_ = CGAffineTransformIdentity;
	
	return self;
}

- (NSString *) iconName
{
	return (self.groupSelect ? @"groupSelect.png" : @"select.png");
}

- (void) flagsChangedInCanvas:(WDCanvas *)canvas
{
	if (!marqueeMode_) {
		return;
	}
	
	CGRect selectionRect;
	CGPoint currentPt = self.previousEvent.location;
	CGPoint initialPt = self.initialEvent.location;
	
	if (self.flags & WDToolOptionKey || self.flags & WDToolSecondaryTouch) {
		CGPoint delta = WDSubtractPoints(initialPt, currentPt);
		selectionRect = WDRectWithPoints(WDAddPoints(initialPt, delta), WDSubtractPoints(initialPt, delta));
	} else {
		selectionRect = WDRectWithPoints(initialPt, currentPt);
	}
	
	canvas.marquee = [NSValue valueWithCGRect:selectionRect];
	[canvas.drawingController selectObjectsInRect:selectionRect];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (void) selectWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	WDDrawingController *controller = canvas.drawingController;

	if (mTargetElement != nil)
	{
		if (mTargetElement == [controller singleSelection])
		{
			if (![self selectControlsWithEvent:event inCanvas:canvas])
			{
				[mTargetElement increaseEditMode];
				if ([mTargetElement isEditingContent]&&
					[mTargetElement isKindOfClass:[WDText class]])
				{
					[canvas.controller editTextObject:(WDText *)mTargetElement selectAll:NO];
				}
			}
		}
		else
		if (![controller isSelected:mTargetElement])
		{
			if (![self shouldAppendSelection])
			{ [controller deselectAllObjects]; }
			[controller selectObject:mTargetElement];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) selectControlsWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	if ([mTargetElement isEditingFrame]&&
		[self selectFrameControlsWithEvent:event inCanvas:canvas])
	{ return YES; }

	if ([mTargetElement isEditingContent]&&
		[self selectContentControlsWithEvent:event inCanvas:canvas])
	{ return YES; }

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) selectFrameControlsWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	// Define touch rect in document scale
	CGRect touchR = [event touchRectForViewScale:canvas.viewScale];

	NSInteger n = [mTargetElement findFrameControlIndexForRect:touchR];

	// Just need to report a hit, so editmode doesn't change
	return (n >= 0);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) selectContentControlsWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	// Define touch rect in document scale
	CGRect touchR = [event touchRectForViewScale:canvas.viewScale];

	id content = [mTargetElement findContentControlsInRect:touchR];
	if (content != nil)
	{
		if ([mTargetElement isKindOfClass:[WDPath class]])
		{
			WDDrawingController *controller = canvas.drawingController;
			if (![self shouldAppendSelection])
			{ [controller deselectAllNodes]; }
			[controller selectNode:[content anyObject]];
		}

		return YES;
	}

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) selectStyleControlsWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	// Define touch rect in document scale
//	CGRect touchR = [event touchRectForViewScale:canvas.viewScale];

	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) selectTextControlsWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	// Define touch rect in document scale
//	CGRect touchR = [event touchRectForViewScale:canvas.viewScale];

	return NO;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
- (void) __selectWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	WDDrawingController *controller = canvas.drawingController;

	if (mTargetElement != nil)
	{
		if (mTargetElement == [controller singleSelection])
		{
			if (![self selectControlsWithEvent:event inCanvas:canvas])
			{ [mTargetElement increaseEditMode]; }
		}
		else
		if (![controller isSelected:mTargetElement])
		{
			if (![self shouldAppendSelection])
			{ [controller deselectAllObjects]; }
			[controller selectObject:mTargetElement];
		}
	}

	return;


	activeNode_ = nil;
	activeTextHandle_ = kWDEther;
	activeGradientHandle_ = kWDEther;
	transformingNodes_ = NO;
	transformingHandles_ = NO;
	convertingNode_ = NO;
	transformingGradient_ = NO;
	transformingTextKnobs_ = NO;
	transformingTextPathStartKnob_ = NO;
	lastTappedObject_ = nil;
	
	WDPickResult *result = [controller objectUnderPoint:event.location viewScale:canvas.viewScale];
	
	if (!result || result.type == kWDEther) {
		// didn't hit anything: marquee mode!
		[canvas setToolOptionsView:nil];
		[controller deselectAllObjects];
		controller.propertyManager.ignoreSelectionChanges = YES;
		marqueeMode_ = YES;
		return;
	}
	
	WDElement *element = result.element;

	if (![controller isSelected:element])
	{
		WDPath *path = nil;
		
		if ([element isKindOfClass:[WDPath class]])
		{ path = (WDPath *) element; }
		
		if (!path || !path.superpath || (path.superpath && ![controller isSelected:path.superpath]))
		{
			//
			if (![self shouldAppendSelection])
			{ [controller deselectAllObjects]; }

			[controller selectObject:element];
			[element setEditMode:eWDEditModeFrame];
		}
		else
		if (path && path.superpath && [controller isSelected:path.superpath] && ![controller singleSelection])
		{
			lastTappedObject_ = path.superpath;
			objectWasSelected_ = YES;
		}
	}
	else if ([controller singleSelection])
	{
		[element setEditMode:eWDEditModeContent];
		// we have a single selection, and the hit element is already selected... it must be the single selection
	   
		if ([element isKindOfClass:[WDPath class]] && result.node)
		{
			nodeWasSelected_ = result.node.selected;
			activeNode_ = result.node;
			
			if (!nodeWasSelected_)
			{
				if (!self.groupSelect) {
					// only allow one node to be selected at a time
					[controller deselectAllNodes];
				}
				[controller selectNode:result.node];
			}
			
			if (event.count == 2) {
				// convert node mode, start transforming handles in pure reflection mode
				pointToMove_ = (result.type == kWDAnchorPoint) ? kWDOutPoint : result.type;
				pointToConvert_ = result.type;
				originalReflectionMode_ = WDReflect;
				transformingHandles_ = YES;
				convertingNode_ = YES;
			} else if (result.type == kWDInPoint || result.type == kWDOutPoint) {
				pointToMove_ = result.type;
				originalReflectionMode_ = activeNode_.reflectionMode;
				transformingHandles_ = YES;
			} else {
				// we're dragging a node, we should treat it as the snap point
				self.initialEvent.snappedLocation = result.node.anchorPoint;
				transformingNodes_ = YES;
			}
		} else if ([element isKindOfClass:[WDPath class]] && result.type == kWDEdge) {
			// only allow one node to be selected at a time
			[controller deselectAllNodes];
			
			if (event.count == 2 && [element conformsToProtocol:@protocol(WDTextRenderer)]) {
				[canvas.controller editTextObject:(WDText *)element selectAll:NO];
			}
		} else if ([element isKindOfClass:[WDStylable class]] && (result.type == kWDFillEndPoint || result.type == kWDFillStartPoint)) {
			activeGradientHandle_ = result.type;
			transformingGradient_ = YES;
		} else if ([element isKindOfClass:[WDTextPath class]] && (result.type == kWDTextPathStartKnob)) {
			activeTextPath_ = (WDTextPath *) element;
			transformingTextPathStartKnob_ = YES;
			[activeTextPath_ cacheOriginalStartOffset];
		} else if ([element isKindOfClass:[WDAbstractPath class]]) {
			if (result.type == kWDObjectFill) {
				[controller deselectAllNodes];
				
				if (event.count == 2 && [element conformsToProtocol:@protocol(WDTextRenderer)]) {
					[canvas.controller editTextObject:(WDText *)element selectAll:NO];
				}
			}
		} else if ([element isKindOfClass:[WDText class]]) {
			if (event.count == 2) {
				[canvas.controller editTextObject:(WDText *)element selectAll:NO];
			} else
				if (result.type == kWDLeftTextKnob || result.type == kWDRightTextKnob) {
				activeTextHandle_ = result.type;
				transformingTextKnobs_ = YES;
				[(WDText *)element cacheTransformAndWidth];
			}
		}
	} else {
		lastTappedObject_ = element;
		objectWasSelected_ = [controller isSelected:result.element];
	}
}
*/

/*
	If touching air, start marque mode,
	otherwise wait for next event
	if next event is end,
		change editmode
	else
	if next event is move,
		if editmode = frame, move element (adjust selectionTransform)
		if editmode = content, move content (adjust displayNodes)
*/
- (void) beginWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	WDDrawingController *controller = canvas.drawingController;

	// reset mode
	marqueeMode_ = NO;

	// reset transform
	transform_ = CGAffineTransformIdentity;

	// Define touch rect in document scale
	CGRect touchR = [event touchRectForViewScale:canvas.viewScale];

	if (![mTargetElement intersectsRect:touchR])
	{
		// Ask controller to find first element with intersecting stylebounds
		mTargetElement = [controller findElementInRect:touchR];
		// TODO: redirect to include editingmode mask
	}

	if (mTargetElement != nil)
	{
		mTargetCenter = [mTargetElement frameCenter];
		mTargetControlIndex = [mTargetElement findFrameControlIndexForRect:touchR];
	}
	

	if (mTargetElement == nil)
	{
		[canvas setToolOptionsView:nil];
		[controller deselectAllObjects];
		controller.propertyManager.ignoreSelectionChanges = YES;
		marqueeMode_ = YES;
	}

}

////////////////////////////////////////////////////////////////////////////////

- (void) moveWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	if (marqueeMode_)
	{
		[self moveMarqueWithEvent:event inCanvas:canvas];
	}
	else
	if ([mTargetElement isEditingNone])
	{
		canvas.transforming = YES;
		canvas.transformingNode = NO;
		[self moveSelectionWithEvent:event inCanvas:canvas];
	}
	else
	if ([mTargetElement isEditingFrame])
	{
		canvas.transforming = NO;
		canvas.transformingNode = NO;
		[self moveFrameWithEvent:event inCanvas:canvas];
	}
	else
	if ([mTargetElement isEditingContent])
	{
		canvas.transforming = NO;
		canvas.transformingNode = YES;

		[self moveContentWithEvent:event inCanvas:canvas];
	}



/*
	CGPoint initialSnapped = self.initialEvent.snappedLocation;
	CGPoint currentPt = event.location;
	CGPoint snapped = event.snappedLocation;
	CGPoint delta;

	else
	if (transformingNodes_)
	{
		canvas.transforming = canvas.transformingNode = YES;
		delta = WDSubtractPoints(snapped, initialSnapped);
	
		if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
			delta = WDConstrainPoint(delta);
		}
		
		transform_ = CGAffineTransformMakeTranslation(delta.x, delta.y);

		WDPath *path = (WDPath *) [canvas.drawingController singleSelection];

		path.displayNodes = [path anyNodesSelected] ?
		[path nodesWithSelectionTransform:transform_]:
		[path nodesWithTransform:transform_];

		path.displayClosed = path.closed;
		[canvas invalidateSelectionView];
	}
	else
	if (transformingHandles_)
	{
		canvas.transforming = canvas.transformingNode = YES;
		
		WDBezierNodeReflectionMode reflect = (self.flags & WDToolOptionKey || self.flags & WDToolSecondaryTouch ? WDIndependent : originalReflectionMode_);
		
		replacementNode_ = [activeNode_ moveControlHandle:(int)pointToMove_ toPoint:snapped reflectionMode:reflect];
		replacementNode_.selected = YES; 

		WDPath *path = (WDPath *) [canvas.drawingController singleSelection];

		NSMutableArray *newNodes = [NSMutableArray array];
		
		for (WDBezierNode *node in path.nodes)
		{ [newNodes addObject:node == activeNode_ ? replacementNode_ : node]; }

		path.displayNodes = newNodes;
		path.displayClosed = path.closed;
		[canvas invalidateSelectionView];
	}
	else
	if (transformingGradient_)
	{
		canvas.transforming = YES;
		canvas.transformingNode = YES;
		
		WDPath *path = (WDPath *) [canvas.drawingController.selectedObjects anyObject];
		if (activeGradientHandle_ == kWDFillStartPoint) {
			path.displayFillTransform = [path.fillTransform transformWithTransformedStart:snapped];
		} else {
			path.displayFillTransform = [path.fillTransform transformWithTransformedEnd:snapped];
		}
		
		[canvas invalidateSelectionView];
	} else if (transformingTextKnobs_) {
		canvas.transforming = YES;
		
		WDText *text = (WDText *) [canvas.drawingController singleSelection];
		[text moveHandle:activeTextHandle_ toPoint:snapped];
		
		[canvas invalidateSelectionView];
	} else if (transformingTextPathStartKnob_) {
		WDTextPath *path = (WDTextPath *) [canvas.drawingController.selectedObjects anyObject];
		[path moveStartKnobToNearestPoint:currentPt]; 
		[canvas invalidateSelectionView];
	} else { 
		// transform selected
		canvas.transforming = YES;
		canvas.transformingNode = [canvas.drawingController selectedNodes].count;
		
		delta = WDSubtractPoints(currentPt, initialSnapped);
		
		if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
			delta = WDConstrainPoint(delta);
		}
		
		if ([canvas.drawing snapFlags] & kWDSnapGrid) {
			delta = [self offsetSelection:delta inCanvas:canvas];
		}
		
		transform_ = CGAffineTransformMakeTranslation(delta.x, delta.y);
		[canvas transformSelection:transform_];
	}
*/
}




- (void) moveMarqueWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	CGPoint P0 = self.initialEvent.location;
	CGPoint P1 = event.location;

	if (self.flags & WDToolSecondaryTouch || self.flags & WDToolOptionKey)
	{
		P0 = WDSubtractPoints(P0, WDSubtractPoints(P1, P0));
	}

	CGRect selectionRect = WDRectWithPoints(P0, P1);

	canvas.marquee = [NSValue valueWithCGRect:selectionRect];
	[canvas.drawingController selectObjectsInRect:selectionRect];

	WDElement *target = [canvas.drawingController singleSelection];
	if (target != nil)
	{
		//[target setEditMode:eWDEditModeContent];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) moveSelectionWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	CGPoint srcP = self.initialEvent.snappedLocation;
	CGPoint dstP = event.location;

	CGPoint delta = WDSubtractPoints(dstP, srcP);

	if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch)
	{ delta = WDConstrainPoint(delta); }

	if ([canvas.drawing snapFlags] & kWDSnapGrid)
	{ delta = [self offsetSelection:delta inCanvas:canvas]; }

	transform_ = CGAffineTransformMakeTranslation(delta.x, delta.y);
	[canvas transformSelection:transform_];
}

////////////////////////////////////////////////////////////////////////////////

- (void) moveFrameWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	if (mTargetControlIndex < 0)
		[self moveSelectionWithEvent:event inCanvas:canvas];
	else
		[self moveFrameControlWithEvent:event inCanvas:canvas];
}

////////////////////////////////////////////////////////////////////////////////

- (void) moveFrameControlWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	CGPoint C = mTargetCenter;
	CGPoint P0 = [mTargetElement frameControlPointAtIndex:mTargetControlIndex];
	CGPoint P1 = event.snappedLocation;

	P0 = WDSubtractPoints(P0, C);
	P1 = WDSubtractPoints(P1, C);

	CGPoint delta = WDSubtractPoints(P1, P0);

	if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
		delta = WDConstrainPoint(delta);
	}

	// Move frame control
	[mTargetElement adjustFrameControlWithIndex:mTargetControlIndex delta:delta];
}

////////////////////////////////////////////////////////////////////////////////

- (void) moveContentWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	CGPoint srcP = self.initialEvent.snappedLocation;
	CGPoint dstP = event.snappedLocation;

	CGPoint delta = WDSubtractPoints(dstP, srcP);

	if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
		delta = WDConstrainPoint(delta);
	}

	transform_ = CGAffineTransformMakeTranslation(delta.x, delta.y);

	if ([mTargetElement isKindOfClass:[WDPath class]])
	{
		WDPath *path = (WDPath *)mTargetElement;

		path.displayNodes = [path anyNodesSelected] ?
		[path nodesWithSelectionTransform:transform_]:
		[path nodesWithTransform:transform_];

		path.displayClosed = path.closed;
		[canvas invalidateSelectionView];
	}
}

////////////////////////////////////////////////////////////////////////////////

/*
	Perhaps move to canvas...

	TestPath could also have additional options: 
	- start of text, alignment etc...
	
	updateOptionsDialog...?
*/
- (void) updateToolOptionsForCanvas:(WDCanvas *)canvas
{
	WDDrawingController *drawingMgr = canvas.drawingController;
	if (drawingMgr != nil)
	{
		id selectedObject = drawingMgr.singleSelection;
		if ((selectedObject != nil)&&
			[selectedObject isKindOfClass:[WDShape class]]&&
			[selectedObject shapeOptions] != WDShapeOptionsNone)
		{
			if ([mOptionsController shape] != selectedObject)
			{
				mOptionsController =
				[WDShapeOptionsController shapeControllerWithShape:selectedObject];
				[canvas setToolOptionsView:[mOptionsController view]];
			}
		}
		else
		{
			[canvas setToolOptionsView:nil];
			mOptionsController = nil;
		}
	}
}

- (void) endWithEvent:(WDEvent *)event inCanvas:(WDCanvas *)canvas
{
	if (!self.moved)
	{
		[self selectWithEvent:event inCanvas:canvas];
		[self updateToolOptionsForCanvas:canvas];
		canvas.drawingController.propertyManager.ignoreSelectionChanges = NO;
		return;
	}

	if (marqueeMode_) {
		marqueeMode_ = NO;
		canvas.marquee = nil;
		[self updateToolOptionsForCanvas:canvas];
		canvas.drawingController.propertyManager.ignoreSelectionChanges = NO;
		return;
	}


	canvas.transforming = canvas.transformingNode = NO;
	
	if (transformingGradient_) {
		if (self.moved) {
			WDPath *path = ((WDPath *) [canvas.drawingController singleSelection]);
			
			path.fillTransform = path.displayFillTransform;
			path.displayFillTransform = nil;
		}
	} else if (transformingNodes_) {
		if (!self.moved && nodeWasSelected_) {
			[canvas.drawingController deselectNode:activeNode_];;
		} else if (self.moved) {
			// apply the transform to the drawing
			[canvas.drawingController transformSelection:transform_];
			[canvas transformSelection:CGAffineTransformIdentity];
			transform_ = CGAffineTransformIdentity;
		}
	} else if (convertingNode_ && !self.moved) {
		WDPath *path = ((WDPath *) [canvas.drawingController singleSelection]);
		
		WDBezierNode *node = [path convertNode:activeNode_ whichPoint:(int)pointToConvert_];
		[canvas.drawingController deselectNode:activeNode_];
		[canvas.drawingController selectNode:node];
	} else if (transformingHandles_ && replacementNode_) {
		WDPath *path = ((WDPath *) [canvas.drawingController singleSelection]);
		path.displayNodes = nil;
		NSMutableArray *newNodes = [NSMutableArray array];
		
		for (WDBezierNode *node in path.nodes) {
			if (node == activeNode_) {
				[newNodes addObject:replacementNode_];
			} else {
				[newNodes addObject:node];
			}
		}
		
		[canvas.drawingController selectNode:replacementNode_];
		replacementNode_ = nil;
		path.nodes = newNodes;
	}  else if (transformingTextPathStartKnob_) {
		[activeTextPath_ registerUndoWithCachedStartOffset];
		activeTextPath_ = nil;
	} else if (transformingTextKnobs_) {
		WDText *text = (WDText *) [canvas.drawingController singleSelection];
		[text registerUndoWithCachedTransformAndWidth];
	} else {
		if (self.moved) {
			// apply the transform to the drawing
			[canvas.drawingController transformSelection:transform_];
			[canvas transformSelection:CGAffineTransformIdentity];
			transform_ = CGAffineTransformIdentity;
		} else if (self.groupSelect && lastTappedObject_ && objectWasSelected_) {
			[canvas.drawingController deselectObject:lastTappedObject_];
		}  
	}
}





- (NSValue *) snapCorner:(CGPoint)pt inCanvas:(WDCanvas *)canvas
{
	WDPickResult *result = [canvas.drawingController snappedPoint:pt viewScale:canvas.viewScale snapFlags:kWDSnapGrid];
	
	if (result.snapped) {
		CGPoint delta = WDSubtractPoints(result.snappedPoint, pt);
		return [NSValue valueWithCGPoint:delta];
	}
	
	return nil;
}

- (CGPoint) offsetSelection:(CGPoint)originalDelta inCanvas:(WDCanvas *)canvas
{
	CGRect selectionBounds =
	CGRectOffset([canvas.drawingController selectionBounds], originalDelta.x, originalDelta.y);
	NSMutableArray  *deltas = [NSMutableArray array];
	CGPoint         delta;
	
	// snap each corner and see which has the smallest delta
	
	CGPoint ul = CGPointMake(CGRectGetMinX(selectionBounds), CGRectGetMinY(selectionBounds));
	[deltas addObject:[self snapCorner:ul inCanvas:canvas]];
	
	CGPoint ur = CGPointMake(CGRectGetMaxX(selectionBounds), CGRectGetMinY(selectionBounds));
	[deltas addObject:[self snapCorner:ur inCanvas:canvas]];
	
	CGPoint lr = CGPointMake(CGRectGetMaxX(selectionBounds), CGRectGetMaxY(selectionBounds));
	[deltas addObject:[self snapCorner:lr inCanvas:canvas]];
	
	CGPoint ll = CGPointMake(CGRectGetMinX(selectionBounds), CGRectGetMaxY(selectionBounds));
	[deltas addObject:[self snapCorner:ll inCanvas:canvas]];
	
	delta = [deltas[0] CGPointValue];
	for (NSValue *value in deltas) {
		CGPoint test = [value CGPointValue];
		if (WDDistance(test, CGPointZero) < WDDistance(delta, CGPointZero)) {
			delta = test;
		}
	}
	
	return WDAddPoints(delta, originalDelta);
}





@end
