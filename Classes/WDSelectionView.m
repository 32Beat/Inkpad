//
//  WDSelectionView.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDBezierNode.h"
#import "WDCanvas.h"
#import "WDDrawingController.h"
#import "WDDrawing.h"
#import "WDElement.h"
#import "WDGLUtilities.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDShape.h"

#import "WDSelectionTool.h"
#import "WDSelectionView.h"
#import "WDToolManager.h"
#import "WDUtilities.h"
#import "UIColor_Additions.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDSelectionView
////////////////////////////////////////////////////////////////////////////////

@synthesize canvas = mCanvas;
@synthesize context = mContext;

////////////////////////////////////////////////////////////////////////////////

+ (Class) layerClass
{ return [CAEAGLLayer class]; }

////////////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{    
	self = [super initWithFrame:frame];
	if (!self) return nil;

	/*
		Document draws downward:
		(0, 0) = top left corner
		positive y values move down

		OpenGL draws upward:
		(0, 0) = bottom left
		positive y values move up

		For rounding (floor, round, ceil) to be synchronized 
		between our pixel coordinates and the OpenGL engine,
		we can NOT apply a flip transform to coordinates prior
		to sending them to the OpenGL driver. 
		
		We will therefore draw "upside down" and let core animation 
		apply a flip transform to the backingstore.
	*/
	[self setTransform:(CGAffineTransform){ 1, 0, 0, -1, 0, 0}];

	// Prepare the GL layer
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	eaglLayer.opaque = NO;
	eaglLayer.drawableProperties =
	@{kEAGLDrawablePropertyRetainedBacking: @NO,
	kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};


	// Prepare OpenGL context, actual backing will be allocated in -reshapeFramebuffer
	mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	if (!mContext || ![EAGLContext setCurrentContext:mContext]) {
		return nil;
	}
	// Create OpenGL FrameBuffer & RenderBuffer references
	glGenFramebuffersOES(1, &mFrameBufferID);
	glGenRenderbuffersOES(1, &mRenderBufferID);
	// Set as targets in current context
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, mFrameBufferID);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, mRenderBufferID);
	// Attach renderbuffer to framebuffer
	glFramebufferRenderbufferOES
	(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mRenderBufferID);

	glClearColor(0, 0, 0, 0);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnableClientState(GL_VERTEX_ARRAY);

///////////////////////////////
/*
	We just want fast, 
	aliased outlines.
*/
///////////////////////////////
/*
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_MULTISAMPLE);
	glEnable(GL_DITHER);
/*/
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_MULTISAMPLE);
	glDisable(GL_DITHER);
//*/
///////////////////////////////

	self.userInteractionEnabled = NO;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.contentMode = UIViewContentModeCenter;

	// Adjust for screen
	[self setContentScaleFactor:[UIScreen mainScreen].scale];
//	[self setContentScaleFactor:1.0/16.0];
//	[self setContentScaleFactor:1];

	// Ensure zooming produces actual pixels
	[[self layer] setMagnificationFilter:kCAFilterNearest];
/*
	To speed up rendering, we may set the layer scalefactor to a 
	lower value than the screen scalefactor.

	If the layer scalefactor is 1.0
	and the screen scalefactor is 2.0,
	the layer will be enlarged by CoreAnimation. 
	
	It will use smooth interpolation by default which is not 
	the desired behavior. kCAFilterNearest tells it to use nearest neighbor.
*/

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setContentScaleFactor:(CGFloat)r
{
	[super setContentScaleFactor:r];

	// Adjust default marker radius
	WDGLSetMarkerDefaultsForScale(r);
}

////////////////////////////////////////////////////////////////////////////////

- (void)reshapeFramebuffer
{
	// Allocate color buffer backing based on the current layer size
	[mContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];

	glGetRenderbufferParameterivOES
	(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &mBackingWidth);
	glGetRenderbufferParameterivOES
	(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &mBackingHeight);

	// Setup corresponding transforms
	[EAGLContext setCurrentContext:mContext];

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	// Match model to view, since we provide pixelcoordinates
	// Note: can not flip Y here because of rounding synchronization
	glOrthof(0, mBackingWidth, 0, mBackingHeight, -1, 1);
	glViewport(0, 0, mBackingWidth, mBackingHeight);
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) convertRectFromCanvas:(CGRect)rect
{
	rect.origin = WDSubtractPoints(rect.origin, [mCanvas visibleRect].origin);
	rect = CGRectApplyAffineTransform(rect, self.canvas.canvasTransform);

	return rect;
}

////////////////////////////////////////////////////////////////////////////////

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return self.superview;
}

- (void) renderMarqueWithTransform:(CGAffineTransform)T
{
	CGRect R = [self.canvas.marquee CGRectValue];

	R = CGRectApplyAffineTransform(R, T);

	glColor4f(0, 0, 0, 0.333f);
	WDGLFillRect(R);

	glColor4f(0, 0, 0, 0.75f);
	WDGLStrokeRect(R);
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) pageRect
{ return (CGRect){ {0,0}, mCanvas.drawing.dimensions }; }

- (CGRect) pageRectWithTransform:(CGAffineTransform)T
{
	CGRect R = [self pageRect];
	return CGRectApplyAffineTransform(R, T);
}

////////////////////////////////////////////////////////////////////////////////

- (CGSize) effectiveGridSpacing:(CGAffineTransform)T
{
	float srcSize = self.drawing.gridSpacing;
	float dstSizeX = srcSize * T.a;
	float dstSizeY = srcSize * T.d;

	if (dstSizeX < 10.0)
	{ dstSizeX *= ceil(10.0/dstSizeX); }
	if (dstSizeY < 10.0)
	{ dstSizeY *= ceil(10.0/dstSizeY); }

	return (CGSize){ dstSizeX, dstSizeY };
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderGridWithTransform:(CGAffineTransform)T
{
	CGSize gridSpacing = [self effectiveGridSpacing:T];
	CGRect pageR = [self pageRectWithTransform:T];
	CGRect viewR = [self bounds];

	// Only draw lines in the portion of the document that's actually visible
	CGRect visibleRect = CGRectIntersection(pageR, viewR);
	if (CGRectIsEmpty(visibleRect)) {
		// if there's no intersection, bail early
		return;
	}


	double startX = visibleRect.origin.x - pageR.origin.x;
	double startY = visibleRect.origin.y - pageR.origin.y;

	startX = floor(startX/gridSpacing.width);
	startY = floor(startY/gridSpacing.height);

	startX = pageR.origin.x + startX * gridSpacing.width;
	startY = pageR.origin.y + startY * gridSpacing.height;

	CGPoint a, b;

	GLfloat k = 0.8;
	glColor4f(k, k, k, 1.0);

	float minX = CGRectGetMinX(visibleRect);
	float minY = CGRectGetMinY(visibleRect);
	float maxX = CGRectGetMaxX(visibleRect);
	float maxY = CGRectGetMaxY(visibleRect);

	minX = floor(minX);
	minY = floor(minY);
	maxX = ceil(maxX);
	maxY = ceil(maxY);

	float x = startX;
	while (x < maxX)
	{
		a.x = floor(x) + 0.5;
		a.y = minY;
		b.x = floor(x) + 0.5;
		b.y = maxY;

		WDGLStrokeLine(a, b);
		x += gridSpacing.width;
	}

	float y = startY;
	while (y < maxY)
	{
		a.x = minX;
		a.y = floor(y) + 0.5;
		b.x = maxX;
		b.y = floor(y) + 0.5;

		WDGLStrokeLine(a, b);
		y += gridSpacing.height;
	}
}


////////////////////////////////////////////////////////////////////////////////

- (void) renderPageWithTransform:(CGAffineTransform)T
{
	CGRect pageR = [self pageRectWithTransform:T];

	pageR = CGRectInset(pageR, -1, -1);

	float gray = [mCanvas effectiveBackgroundGray];
	glClearColor(gray, gray, gray, 1);
	glClear(GL_COLOR_BUFFER_BIT);
//	glClearColor(0, 0, 0, 1);

	glColor4f(1, 1, 1, 1);
	WDGLFillRect(pageR);

	if (self.canvas.drawing.showGrid)
	{ [self renderGridWithTransform:T]; }

	glColor4f(0, 0, 0, 1);
	WDGLStrokeRect(pageR);
}

////////////////////////////////////////////////////////////////////////////////

// Replace the implementation of this method to do your own custom drawing
- (void) drawView
{
#ifdef WD_DEBUG
	NSDate *date = [NSDate date];
#endif

	[EAGLContext setCurrentContext:mContext];
	glClear(GL_COLOR_BUFFER_BIT);

	// Fetch source rect
	CGRect srcR = [self pageRect];
	if (CGRectIsEmpty(srcR))
	{ return; }

	// Get canvas transform
	CGAffineTransform T = self.canvas.canvasTransform;

	// Compute result rect (in view)
	CGRect dstR = CGRectApplyAffineTransform(srcR, T);

	// Scale for layer if necessary
	float scaleFactor = [self contentScaleFactor];
	if (scaleFactor != 1.0)
	{
		dstR.origin.x *= scaleFactor;
		dstR.origin.y *= scaleFactor;
		dstR.size.width *= scaleFactor;
		dstR.size.height *= scaleFactor;
	}

	// dstR now represents pixelcoordinates: compute integral
	dstR.origin.x = round(dstR.origin.x);
	dstR.origin.y = round(dstR.origin.y);
	dstR.size.width = round(dstR.size.width);
	dstR.size.height = round(dstR.size.height);

	// Recompute transform based on integral pixelgrid bounds
	CGFloat sx = dstR.size.width / srcR.size.width;
	CGFloat sy = dstR.size.height / srcR.size.height;
	// Offset to top left in upside-down pixels
	CGFloat tx = CGRectGetMinX(dstR);
	CGFloat ty = mBackingHeight - CGRectGetMaxY(dstR);

	T = (CGAffineTransform){ sx, 0, 0, sy, tx, ty };

//	[self renderPageWithTransform:T];


	if (mCanvas.isZooming) {
		[self renderPageWithTransform:T];
		
		if (self.canvas.drawing.showGrid) {
			[self renderGridWithTransform:T];
		}
		
		CGRect visibleRect = self.canvas.visibleRect;
		for (WDLayer *l in self.canvas.drawing.layers) {
			if (l.hidden) {
				continue;
			}
			
			[l.highlightColor openGLSet];
			
			for (WDElement *e in [l elements]) {
				[e drawOpenGLZoomOutlineWithViewTransform:T visibleRect:visibleRect];
			}
		}
		
		[mContext presentRenderbuffer:GL_RENDERBUFFER_OES];
		return;
	}


	WDDrawingController *drawController = self.canvas.drawingController;

	// Assume selectionTransform applies to entire object(s)
	CGAffineTransform combined =
	CGAffineTransformConcat(self.canvas.selectionTransform, T);

	/*
		Note: adjusted nodes are stored in WDPath->displayNodes
		WDPath will always draw displaynodes if available
	*/

	// Draw outline for selected objects
	for (WDElement *object in drawController.selectedObjects)
	{
		[object.layer.highlightColor glSet];
		[(id)object glDrawWithTransform:combined];
	}

	// Or draw object being constructed
	if (self.canvas.shapeUnderConstruction)
	{
		[[UIColor blackColor] glSet];
		[self.canvas.shapeUnderConstruction glDrawWithTransform:combined];
	}

	// marquee?
	if (self.canvas.marquee)
	{ [self renderMarqueWithTransform:T]; }

/*
	if (singleSelection && !self.canvas.transforming && !self.canvas.transformingNode) {
		if ([[WDToolManager sharedInstance].activeTool isKindOfClass:[WDSelectionTool class]]) {
			[singleSelection drawTextPathControlsWithViewTransform:T viewScale:self.canvas.viewScale];
		}
	}

	// draw all object outlines, using the selection transform if applicable
	for (WDElement *e in controller.selectedObjects) {
		[e drawOpenGLHighlightWithTransform:self.canvas.selectionTransform viewTransform:T];
	}

	// if we're not transforming, draw filled anchors on all paths
	if (!self.canvas.transforming && !singleSelection) {        
		for (WDElement *e in controller.selectedObjects) {
			[e drawOpenGLAnchorsWithViewTransform:T];
		}
	}

	if (controller.tempDisplayNode) {
		[controller.tempDisplayNode drawGLWithViewTransform:T color:controller.drawing.activeLayer.highlightColor mode:kWDBezierNodeRenderSelected];
	}

	if ((!self.canvas.transforming || self.canvas.transformingNode) && singleSelection) {
		[singleSelection drawOpenGLHandlesWithTransform:self.canvas.selectionTransform viewTransform:T];
		
		if ([[WDToolManager sharedInstance].activeTool isKindOfClass:[WDSelectionTool class]]) {
			[singleSelection drawGradientControlsWithViewTransform:T];
		}
	}

	if (self.canvas.shapeUnderConstruction) {
		[self.canvas.shapeUnderConstruction drawOpenGLHighlightWithTransform:CGAffineTransformIdentity viewTransform:T];
	}

//	[self renderPageWithTransform:T];
*/

#ifdef WD_DEBUG
    NSLog(@"SelectionView preptime: %f", -[date timeIntervalSinceNow]);
#endif

    [mContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews
{
	[self reshapeFramebuffer];
	[self drawView];
}

- (void)dealloc
{        
    if ([EAGLContext currentContext] == mContext) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (WDDrawing *) drawing
{
    return self.canvas.drawing;
}

@end
