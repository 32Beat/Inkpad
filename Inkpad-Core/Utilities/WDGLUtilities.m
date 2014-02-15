////////////////////////////////////////////////////////////////////////////////
/*  
	WDGLUtilities
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2011-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDGLUtilities.h"

////////////////////////////////////////////////////////////////////////////////
/*
	CopyVertexData
	--------------
	Transfer VertexData as 2D coordinates to OpenGL
	
		type
		OpenGL begin mode, e.g. GL_POINTS, GL_LINES etc
		
		vertexData
		Pointer to 2d vertices
		
		count
		Number of 2d vertices
*/

static inline void CopyVertexData
(GLenum type, const GLvoid *vertexData, GLsizei count)
{
	glVertexPointer(2, GL_FLOAT, 0, vertexData);
	glDrawArrays(type, 0, count);
}

#define mCopyVertexArray(t, array) \
CopyVertexData(t, array, sizeof(array)/(2*sizeof(GLfloat)))

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL Shape rendering
////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLFillRect
	-------------
	Fill rect bounds
*/

static inline void _WDGLFillRect(CGRect R)
{
	// Fetch coordinates
	CGFloat minX = CGRectGetMinX(R);
	CGFloat minY = CGRectGetMinY(R);
	CGFloat maxX = CGRectGetMaxX(R);
	CGFloat maxY = CGRectGetMaxY(R);

	// Prepare triangle fan
	GLfloat vertexData[] = {
		minX, minY,
		maxX, minY,
		maxX, maxY,
		minX, maxY
	};

	// Tranfer to openGL
	mCopyVertexArray(GL_TRIANGLE_FAN, vertexData);
}

////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLStrokeRectWithSize
	-----------------------
	Stroke rect by drawing sized border inside rect bounds.
	If partial overlap is desired, adjust rect prior to call.
*/

static inline void _WDGLStrokeRectWithSize(CGRect R, CGFloat size)
{
	// Fetch coordinates
	CGFloat minX = CGRectGetMinX(R);
	CGFloat minY = CGRectGetMinY(R);
	CGFloat maxX = CGRectGetMaxX(R);
	CGFloat maxY = CGRectGetMaxY(R);

	// Prepare triangle strip
	GLfloat vertexData[] = {
		minX, minY,
		minX+size, minY+size,
		maxX, minY,
		maxX-size, minY+size,
		maxX, maxY,
		maxX-size, maxY-size,
		minX, maxY,
		minX+size, maxY-size,
		minX, minY,
		minX+size, minY+size };

	// Transfer to openGL
	mCopyVertexArray(GL_TRIANGLE_STRIP, vertexData);
}

////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLFillDiamond
	----------------
	Fill diamond by drawing triangles using rect edge
*/

static inline void _WDGLFillDiamond(CGRect R)
{
	// Fetch center
	CGFloat midX = CGRectGetMidX(R);
	CGFloat midY = CGRectGetMidY(R);

	// Fetch coordinates
	CGFloat minX = CGRectGetMinX(R);
	CGFloat minY = CGRectGetMinY(R);
	CGFloat maxX = CGRectGetMaxX(R);
	CGFloat maxY = CGRectGetMaxY(R);

	// Prepare triangle fan
	GLfloat vertexData[] = {
		midX, maxY,
		minX, midY,
		midX, minY,
		maxX, midY
	};

	// Transfer to openGL
	mCopyVertexArray(GL_TRIANGLE_FAN, vertexData);
}

////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLStrokeDiamondWithSize
	--------------------------
	Stroke diamond by drawing sized border inside edge
*/

static inline void _WDGLStrokeDiamondWithSize(CGRect R, CGFloat size)
{
	// Fetch center
	CGFloat midX = CGRectGetMidX(R);
	CGFloat midY = CGRectGetMidY(R);
	// Fetch coordinates
	CGFloat minX = CGRectGetMinX(R);
	CGFloat minY = CGRectGetMinY(R);
	CGFloat maxX = CGRectGetMaxX(R);
	CGFloat maxY = CGRectGetMaxY(R);

	// Adjust for diagonal size
	size *= 1.414213562373095;

	// Prepare triangle strip
	GLfloat vertexData[] = {
		midX, maxY,
		midX, maxY-size,
		minX, midY,
		minX+size, midY,
		midX, minY,
		midX, minY+size,
		maxX, midY,
		maxX-size, midY,
		midX, maxY,
		midX, maxY-size
	};

	// Tranfer to openGL
	mCopyVertexArray(GL_TRIANGLE_STRIP, vertexData);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	We like a circle to be symmetric, so we compute the number of segments 
	based on flatness constraint for a single quadrant:
	1. Compute circumference = 2.0*M_PI*radius
	2. Quadrant size = circumference / 4.0
	3. Quadrant segments = Quadrant size / flatness
	4. Total segments = 4 * Quadrant segments
*/

static inline GLsizei CircleSegmentsForRadius(float radius, float flatness)
{
	// Compute circumference
	float c = 2.0*M_PI*radius;
	// Compute number of segments
	return 4.0 * round((c / 4.0) / flatness);
}

////////////////////////////////////////////////////////////////////////////////

static inline void CircleSetSegments
(GLfloat *vertexData, CGPoint center, float radius, long n)
{
	// Compute step transform (use max precision)
	double da = 2.0 * M_PI / n;
	double dx = cos(da);
	double dy = sin(da);
	double x, nx = radius;
	double y, ny = 0;
	// Loop for all segments
	for (; n!=0; n--)
	{
		// Set startpoint
		*vertexData++ = center.x + (x = nx);
		*vertexData++ = center.y + (y = ny);
		// Compute next coordinates
		nx = x*dx - y*dy;
		ny = x*dy + y*dx;
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	CircleSetSegmentsForSizedStroke
	-------------------------------
	Compute coordinates for trianglestrip inside circle edge
*/

static inline void CircleSetSegmentsForSizedStroke
(GLfloat *vertexData, CGPoint center, float radius, float size, long n)
{
	// Compute step transform (use max precision)
	double da = 2.0 * M_PI / n;
	double dx = cos(da);
	double dy = sin(da);
	double x, nx = radius;
	double y, ny = 0;
	double r = (radius-size)/radius;

	GLfloat *dstPtr = vertexData;
	// Loop for all segments
	for (; n!=0; n--)
	{
		// Set top point
		*dstPtr++ = center.x + (x = nx);
		*dstPtr++ = center.y + (y = ny);
		// Set bottom point
		*dstPtr++ = center.x + r * x;
		*dstPtr++ = center.y + r * y;

		// Compute next coordinates
		nx = x*dx - y*dy;
		ny = x*dy + y*dx;
	}

	// Repeat start
	*dstPtr++ = vertexData[0];
	*dstPtr++ = vertexData[1];
	*dstPtr++ = vertexData[2];
	*dstPtr++ = vertexData[3];
}

////////////////////////////////////////////////////////////////////////////////

static inline CGPoint CircleGetCenter(CGRect R)
{ return (CGPoint){CGRectGetMidX(R), CGRectGetMidY(R)}; }

static inline CGFloat CircleGetRadius(CGRect R)
{ return 0.5 * MIN(R.size.width, R.size.height); }

////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLFillCircle
	---------------
	Fill circle by triangle fan using circle edge as boundary
*/

static inline void _WDGLFillCircle(CGRect R)
{
	CGPoint center = CircleGetCenter(R);
	CGFloat radius = CircleGetRadius(R);

	// Compute number of segments
	GLsizei n = CircleSegmentsForRadius(radius, 3.0);

	// (center + segments startcoordinates + closing coordinate of last segment)
	GLsizei totalPoints = 1+n+1;

	// Prepare triangle fan
	GLfloat *vertexData = malloc(totalPoints*2*sizeof(GLfloat));

	// Set center
	vertexData[0] = center.x;
	vertexData[1] = center.y;

	// Set segment startpoints
	CircleSetSegments(&vertexData[2], center, radius, n);

	// Final segment endpoint = first segment startpoint
	vertexData[2*(1+n)+0] = vertexData[2];
	vertexData[2*(1+n)+1] = vertexData[3];

	// Transfer trianglefan to openGL
	CopyVertexData(GL_TRIANGLE_FAN, vertexData, totalPoints);

	// Release memory
    free(vertexData);
}

////////////////////////////////////////////////////////////////////////////////
/*
	_WDGLStrokeCircleWithSize
	-------------------------
	Stroke circle by drawing sized border inside circle edge
*/

static inline void _WDGLStrokeCircleWithSize(CGRect R, CGFloat size)
{
	CGPoint center = CircleGetCenter(R);
	CGFloat radius = CircleGetRadius(R);

	// Compute number of segments
	GLsizei n = CircleSegmentsForRadius(radius, 3.0);

	// 2 starting points for each segment + 2 closing points
	GLsizei totalPoints = 2*(n+1);

	// allocate memory
	GLfloat *vertexData = malloc(totalPoints*2*sizeof(GLfloat));

	// Prepare triangle strip
	CircleSetSegmentsForSizedStroke(vertexData, center, radius, size, n);

	// Transfer to openGL
	CopyVertexData(GL_TRIANGLE_STRIP, vertexData, totalPoints);

	// Release memory
	free(vertexData);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	WDGLPrepareRect
	---------------
	Adjust cornerpoints to enclosing boundaries,

	This is generally the desired behavior, specifically:
	selection rectangles drag properly, and pagebounds show
	inclusive pixels.
*/

static inline CGRect WDGLPrepareRect(CGRect R)
{
	CGFloat x = R.origin.x;
	CGFloat y = R.origin.y;
	CGFloat w = R.size.width;
	CGFloat h = R.size.height;
//*
	w += x;
	h += y;
	x = floor(x);
	y = floor(y);
	w = ceil(w);
	h = ceil(h);
	w -= x;
	h -= y;
//*/
	if (w < 1.0) w = 1.0;
	if (h < 1.0) h = 1.0;

	return (CGRect){ x, y, w, h };
}

////////////////////////////////////////////////////////////////////////////////

inline void WDGLFillRect(CGRect R)
{ _WDGLFillRect(WDGLPrepareRect(R)); }

inline void WDGLStrokeRect(CGRect R)
{ _WDGLStrokeRectWithSize(WDGLPrepareRect(R), 1.0); }

inline void WDGLStrokeRectWithSize(CGRect R, CGFloat size)
{ _WDGLStrokeRectWithSize(WDGLPrepareRect(R), size); }

////////////////////////////////////////////////////////////////////////////////

void WDGLStrokeLine(CGPoint a, CGPoint b)
{
	GLfloat vertexData[] = {
		a.x, a.y,
		b.x, b.y };

	CopyVertexData(GL_LINES, &vertexData[0], 2);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL Markers
////////////////////////////////////////////////////////////////////////////////
/*
	Markers are shapes meant to mark positions of points.
	
	To draw a marker we use a center point and a radius.
	The center point is moved to the nearest pixelcenter, 
	the radius is adjusted to pixelbounds.
	
	A radius is used because markers should preferably have odd pixelsize, 
	this allows them to be placed symmetrically on the grid.
	
	A default radius and strokesize are available. They can be set to 
	accommodate different scalefactors of the openGL backing layer.
*/
////////////////////////////////////////////////////////////////////////////////

#define kDefaultMarkerRadius 	5
#define kDefaultMarkerStroke 	1

static long gMarkerRadius = kDefaultMarkerRadius;
static long gMarkerStroke = kDefaultMarkerStroke;

////////////////////////////////////////////////////////////////////////////////

void WDGLSetMarkerDefaultsForScale(CGFloat scale)
{
	gMarkerRadius = ceil(kDefaultMarkerRadius * scale);
	gMarkerStroke = ceil(kDefaultMarkerStroke * scale);

	glPointSize(gMarkerStroke);
	glLineWidth(gMarkerStroke);
}

////////////////////////////////////////////////////////////////////////////////

long WDGLMarkerGetDefaultRadius(void)
{ return gMarkerRadius; }

void WDGLMarkerSetDefaultRadius(long pixels)
{ gMarkerRadius = pixels > 0 ? pixels : kDefaultMarkerRadius; }

////////////////////////////////////////////////////////////////////////////////

long WDGLMarkerGetDefaultStroke(void)
{ return gMarkerStroke; }

void WDGLMarkerSetDefaultStroke(long pixels)
{ gMarkerStroke = pixels > 0 ? pixels : kDefaultMarkerStroke; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	To accommodate even and odd strokesizes, 
	centerpoint should actually be adjusted by:
	1.0 - 0.5*(gMarkerStroke&0x01);
	
	This works fine for rectangles, but other markers would need
	different drawing to fit even bounds symmetrically.
*/

static inline CGRect WDGLMarkerBounds(CGPoint P)
{
	CGFloat midX = floor(P.x) + 0.5;
	CGFloat midY = floor(P.y) + 0.5;
	CGFloat r = gMarkerRadius + 0.5;
	return (CGRect){ midX-r, midY-r, r+r, r+r };
}

////////////////////////////////////////////////////////////////////////////////

void WDGLFillSquareMarker(CGPoint P)
{ _WDGLFillRect(WDGLMarkerBounds(P)); }

void WDGLStrokeSquareMarker(CGPoint P)
{ _WDGLStrokeRectWithSize(WDGLMarkerBounds(P), gMarkerStroke); }

////////////////////////////////////////////////////////////////////////////////

void WDGLFillDiamondMarker(CGPoint P)
{ _WDGLFillDiamond(WDGLMarkerBounds(P)); }

void WDGLStrokeDiamondMarker(CGPoint P)
{ _WDGLStrokeDiamondWithSize(WDGLMarkerBounds(P), gMarkerStroke); }

////////////////////////////////////////////////////////////////////////////////

inline void WDGLFillCircleMarker(CGPoint P)
{ _WDGLFillCircle(WDGLMarkerBounds(P)); }
//{ _WDGLStrokeCircleWithSize(WDGLMarkerBounds(P), gMarkerStroke); }

inline void WDGLStrokeCircleMarker(CGPoint P)
{ _WDGLStrokeCircleWithSize(WDGLMarkerBounds(P), gMarkerStroke); }

////////////////////////////////////////////////////////////////////////////////

void WDGLDrawOverflowMarker(CGPoint P)
{
	CGFloat r = gMarkerRadius + 0.5 - 2*gMarkerStroke;
	P.x = floor(P.x) + 0.5;
	P.y = floor(P.y) + 0.5;

	GLfloat vertexData[] = {
		P.x-r, P.y,
		P.x+r, P.y,
		P.x, P.y-r,
		P.x, P.y+r };

	glLineWidth(1.0);
	mCopyVertexArray(GL_LINES, vertexData);
	glLineWidth(gMarkerStroke);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL Path rendering with WDGLVertexBuffer
////////////////////////////////////////////////////////////////////////////////

#include "WDGLVertexBuffer.h"

static WDGLVertexBuffer gVertexBuffer = WDGLVertexBufferNULL;
static CGPoint gLastPoint = (CGPoint){0.0, 0.0};

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLQueueAddPoint
	-----------------
	Add CGPoint coordinates to global vertex queue
*/

void WDGLQueueAddPoint(CGPoint P)
{
	WDGLVertexBufferAdd(&gVertexBuffer, P.x, P.y);
	gLastPoint = P;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLQueueAddLine
	----------------
	Add line coordinates to global vertex queue
	
	Adds startpoint if and only if queue is empty
*/

void WDGLQueueAddLine(CGPoint P0, CGPoint P1)
{
	// Check if startpoint is required
	if (gVertexBuffer.count == 0)
	{ WDGLQueueAddPoint(P0); }

	WDGLQueueAddPoint(P1);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLQueueAddSegment
	-------------------
	Add WDBezierSegment to global vertexbuffer as flattened linestrip
	
	Adds startpoint if and only if queue is empty
*/

void WDGLQueueAddSegment(WDBezierSegment S)
{
	// Check if startpoint is required
	if (gVertexBuffer.count == 0)
	{ WDGLQueueAddPoint(S.a_); }

	// Start recursive segmentation
	WDBezierSegmentSplitWithBlock(S,
		^BOOL(WDBezierSegment subSegment)
		{
			// If not flat enough, split further
			if (!WDBezierSegmentIsFlat(&subSegment, kDefaultFlatness))
			{ return YES; }

			// Otherwise add line to point
			WDGLQueueAddPoint(subSegment.b_);
			// Stop segmentation of subsegment
			return NO;
		});
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLQueueFlush
	--------------
	Transfer queued vertexdata to openGL
*/

void WDGLQueueFlush(GLenum type)
{
	if (gVertexBuffer.count != 0)
	{
		//type = GL_POINTS;
		WDGLVertexBufferDraw(&gVertexBuffer, type);

		if (type == GL_LINE_LOOP)
		{
			gLastPoint.x = gVertexBuffer.data[0];
			gLastPoint.y = gVertexBuffer.data[1];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

static void WDGLRenderCGPathElement
	(void *info, const CGPathElement *element)
{
	switch (element->type)
	{
		case kCGPathElementMoveToPoint:
			// If there is something to draw, draw as open path
			WDGLQueueFlush(GL_LINE_STRIP);
			WDGLQueueAddPoint(element->points[0]);
			break;

		case kCGPathElementAddLineToPoint:
			WDGLQueueAddLine(
				gLastPoint,
				element->points[0]);
			break;


		case kCGPathElementAddQuadCurveToPoint:
			WDGLQueueAddSegment(
				WDBezierSegmentMakeWithQuadPoints(
					gLastPoint,
					element->points[0],
					element->points[1]));
			break;

		case kCGPathElementAddCurveToPoint:
			WDGLQueueAddSegment(
				(WDBezierSegment){
					gLastPoint,
					element->points[0],
					element->points[1],
					element->points[2] });
			break;


		case kCGPathElementCloseSubpath:
			WDGLQueueFlush(GL_LINE_LOOP);
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

static void WDGLRenderCGPathElementWithTransform
	(void *info, const CGPathElement *element)
{
	const CGAffineTransform *T = (CGAffineTransform *)info;

	switch (element->type)
	{
		case kCGPathElementMoveToPoint:
			// If there is something to draw, draw as open path
			WDGLQueueFlush(GL_LINE_STRIP);
			WDGLQueueAddPoint(
			CGPointApplyAffineTransform(element->points[0],*T));
			break;

		case kCGPathElementAddLineToPoint:
			WDGLQueueAddLine(
				gLastPoint,
				CGPointApplyAffineTransform(element->points[0],*T));
			break;


		case kCGPathElementAddQuadCurveToPoint:
			WDGLQueueAddSegment(
				WDBezierSegmentMakeWithQuadPoints(
					gLastPoint,
					CGPointApplyAffineTransform(element->points[0],*T),
					CGPointApplyAffineTransform(element->points[1],*T)));
			break;

		case kCGPathElementAddCurveToPoint:
			WDGLQueueAddSegment(
				(WDBezierSegment){
					gLastPoint,
					CGPointApplyAffineTransform(element->points[0],*T),
					CGPointApplyAffineTransform(element->points[1],*T),
					CGPointApplyAffineTransform(element->points[2],*T)});
			break;


		case kCGPathElementCloseSubpath:
			WDGLQueueFlush(GL_LINE_LOOP);
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

void WDGLRenderCGPathRef
	(CGPathRef pathRef, const CGAffineTransform *T)
{
	if (pathRef != nil)
	{
		// Process path elements
		CGPathApply(pathRef, (void *)T, T != nil ?
		&WDGLRenderCGPathElementWithTransform:
		&WDGLRenderCGPathElement);

		// Draw any data as open path
		WDGLQueueFlush(GL_LINE_STRIP);
	}
}

////////////////////////////////////////////////////////////////////////////////

static void WDGLRenderCGPathElementMarker
	(void *info, const CGPathElement *element)
{
	const CGAffineTransform *T = (CGAffineTransform *)info;

	switch (element->type)
	{
		case kCGPathElementMoveToPoint:
			WDGLFillCircleMarker(T==nil?element->points[0]:
			CGPointApplyAffineTransform(element->points[0],*T));
			break;

		case kCGPathElementAddLineToPoint:
			WDGLFillCircleMarker(T==nil?element->points[0]:
			CGPointApplyAffineTransform(element->points[0],*T));
			break;


		case kCGPathElementAddQuadCurveToPoint:
			WDGLFillCircleMarker(T==nil?element->points[1]:
			CGPointApplyAffineTransform(element->points[1],*T));
			break;

		case kCGPathElementAddCurveToPoint:
			WDGLFillCircleMarker(T==nil?element->points[2]:
			CGPointApplyAffineTransform(element->points[2],*T));
			break;


		case kCGPathElementCloseSubpath:
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

void WDGLRenderCGPathRefMarkers(CGPathRef pathRef, const CGAffineTransform *T)
{
	if (pathRef != nil)
	{
		// Process path elements
		CGPathApply(pathRef, (void *)T, &WDGLRenderCGPathElementMarker);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Quad Rendering
////////////////////////////////////////////////////////////////////////////////

void WDGLDrawQuadStroke(WDQuad Q, const CGAffineTransform *T)
{
	if (T != nil)
	{ Q = WDQuadApplyTransform(Q, *T); }
	WDGLQueueAddPoint(Q.P[0]);
	WDGLQueueAddPoint(Q.P[1]);
	WDGLQueueAddPoint(Q.P[2]);
	WDGLQueueAddPoint(Q.P[3]);
	WDGLQueueFlush(GL_LINE_LOOP);
}

////////////////////////////////////////////////////////////////////////////////

void WDGLDrawQuadMarkers(WDQuad Q, const CGAffineTransform *T)
{
	if (T != nil)
	{ Q = WDQuadApplyTransform(Q, *T); }
	WDGLFillCircleMarker(Q.P[0]);
	WDGLFillCircleMarker(Q.P[1]);
	WDGLFillCircleMarker(Q.P[2]);
	WDGLFillCircleMarker(Q.P[3]);
}

////////////////////////////////////////////////////////////////////////////////






