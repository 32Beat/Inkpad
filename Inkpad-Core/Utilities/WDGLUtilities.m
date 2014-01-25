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
	GLPixelVector
	-------------
	The code in this file is meant for rendering on a pixelgrid,
	so our vertixes will be 2d vectors. Note that 
	OpenGL will always render the vertices as modeldata, 
	so we are never actually addressing pixels.
*/

#pragma align=packed

typedef struct
{
	GLfloat x;
	GLfloat y;
}
GLPixelVector;

#pragma align=reset
////////////////////////////////////////////////////////////////////////////////
/*
	MakePixelVector
	---------------
	OpenGL uses a diamond-exit rule to determine pixel activation. 
	In order to ensure correct pixel activation when drawing lines, 
	we sometimes need to readjust the endpoints of a line to fit 
	within the diamond of the desired pixel. This adjustment should 
	preferably be as small as possible, so that rendering a flattened 
	curve remains as smooth as possible.
	
	MakePixelVector creates an adjusted pixelvector from 2d coordinates.

	Note that this code assumes the OpenGL matrix stack is setup so that
	pixels fall between integral values. i.e.:
	pixel center = (0.5, 0.5)
	pixel bounds = (0.0, 0.0, 1.0, 1.0)
*/
////////////////////////////////////////////////////////////////////////////////

static inline GLPixelVector MakePixelVector(GLfloat x, GLfloat y)
{
//	return (GLPixelVector){floor(x),ceil(y)};

	// Compute desired pixel center
	CGFloat cx = floor(x)+0.5;
	CGFloat cy = floor(y)+0.5;

	// Compute offset to pixel center
	CGFloat dx = x - cx;
	CGFloat dy = y - cy;

	// Diagonal = dx+dy = 0.5
	CGFloat d = fabs(dx)+fabs(dy);

	// If beyond diagonal, then adjust
	if (d > (127.0/256.0))
	{
		CGFloat m = (127.0/256.0) / d;
		x = cx + m * (x - cx);
		y = cy + m * (y - cy);
	}

	return (GLPixelVector){x,y};
}

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
#pragma mark -
#pragma mark OpenGL Path rendering with WDGLVertexBuffer
////////////////////////////////////////////////////////////////////////////////

#include "WDGLVertexBuffer.h"

static WDGLVertexBuffer gVertexBuffer = WDGLVertexBufferNULL;

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferGetLastPoint
	----------------------------
	For our purposes we need a last-point strategy similar to Postscript
	
	The following two routines belong together:
	GetLastPoint returns the last point.
	DrawPath transfers the buffer to openGL and 
	stores the last point for potential re-use.
*/

static inline
CGPoint WDGLVertexBufferGetLastPoint(void)
{
	WDGLVertexBuffer *vertexBuffer = &gVertexBuffer;

	if (vertexBuffer->data == NULL)
	{ return CGPointZero; }

	GLuint index = vertexBuffer->count;
	if (index != 0) index -= 2;

	return (CGPoint){
	vertexBuffer->data[index+0],
	vertexBuffer->data[index+1] };
}

////////////////////////////////////////////////////////////////////////////////

void WDGLVertexBufferDrawPath(GLenum type)
{
	WDGLVertexBuffer *vertexBuffer = &gVertexBuffer;

	GLuint count = vertexBuffer->count;
	if (count != 0)
	{
		// Save last point
		GLfloat x = vertexBuffer->data[count-2];
		GLfloat y = vertexBuffer->data[count-1];

		// Transfer to openGL
		WDGLVertexBufferDraw(vertexBuffer, type);

		// Store last point
		vertexBuffer->data[0] = x;
		vertexBuffer->data[1] = y;
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferAddPoint
	------------------------
	Add CGPoint coordinates to vertexbuffer
	
	Note: not part of WDGLVertexBuffer file because:
	a) would make it mac OS specific,
	b) some locally specific processing
*/

void WDGLVertexBufferAddPoint(CGPoint P)
{ WDGLVertexBufferAdd(&gVertexBuffer, P.x, P.y); }

////////////////////////////////////////////////////////////////////////////////

static inline void WDGLVertexBufferAddLine(CGPoint P0, CGPoint P1)
{
	// Check if startpoint is required
	if (gVertexBuffer.count == 0)
	{ WDGLVertexBufferAddPoint(P0); }
	WDGLVertexBufferAddPoint(P1);
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferAddSegment
	--------------------------
	Add WDBezierSegment to vertexbuffer as flattened linestrip
	
	Uses _BezierSegmentIsLine to determine whether segment can be 
	approximated by a straight line between anchorpoint a_ and b_,
	otherwise recursively splits segment in left and right segments.
	
	Segment startpoint is added if and only if vertexbuffer is empty.
	(This check has little consequence for processing time, but makes 
	cleaner code at other locations)
*/

void WDGLVertexBufferAddSegment(WDBezierSegment S)
{
	// Check if startpoint is required
	if (gVertexBuffer.count == 0)
	{ WDGLVertexBufferAddPoint(S.a_); }

	WDBezierSegmentSplitWithBlock(S,
		^BOOL(WDBezierSegment subSegment)
		{
			if (WDBezierSegmentIsFlat(subSegment, kDefaultFlatness))
			{
				WDGLVertexBufferAddPoint(subSegment.b_);
				return NO;
			}
			return YES;
		});
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

static inline CGPoint _CGPointInterpolate(CGPoint p1, CGPoint p2, CGFloat r)
{ return (CGPoint){ p1.x+r*(p2.x-p1.x), p1.y+r*(p2.y-p1.y) }; }

////////////////////////////////////////////////////////////////////////////////

static void WDGLRenderCGPathElement
	(void *info, const CGPathElement *element)
{
	switch (element->type)
	{
		case kCGPathElementMoveToPoint:
			// If there is something to draw, draw as open path
			WDGLVertexBufferDrawPath(GL_LINE_STRIP);
			WDGLVertexBufferAddPoint(element->points[0]);
			break;

		case kCGPathElementAddLineToPoint:
			WDGLVertexBufferAddLine(
				WDGLVertexBufferGetLastPoint(),
				element->points[0]);
			break;


		case kCGPathElementAddQuadCurveToPoint:
			WDGLVertexBufferAddSegment(
				WDBezierSegmentMakeWithQuadPoints(
					WDGLVertexBufferGetLastPoint(),
					element->points[0],
					element->points[1]));
			break;

		case kCGPathElementAddCurveToPoint:
			WDGLVertexBufferAddSegment(
				(WDBezierSegment){
					WDGLVertexBufferGetLastPoint(),
					element->points[0],
					element->points[1],
					element->points[2] });
			break;


		case kCGPathElementCloseSubpath:
			WDGLVertexBufferAddPoint(
				WDGLVertexBufferGetLastPoint());
			break;
	}
}

////////////////////////////////////////////////////////////////////////////////

void WDGLRenderCGPathRef(CGPathRef pathRef)
{
	// Process path elements
	CGPathApply(pathRef, nil, &WDGLRenderCGPathElement);

	// Draw any data as open path
	WDGLVertexBufferDrawPath(GL_LINE_STRIP);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark OpenGL Line rendering
////////////////////////////////////////////////////////////////////////////////
/*
	WDGLLineFromPointToPoint
	------------------------
	Draw a single, individual line (not part of a segment)
*/

inline void WDGLLineFromPointToPoint(CGPoint a, CGPoint b)
{
	//glLineWidth(1.0);

    GLPixelVector vertexData[] = {
		MakePixelVector(a.x, a.y),
		MakePixelVector(b.x, b.y) };

	CopyVertexData(GL_LINES, &vertexData[0], 2);
}

////////////////////////////////////////////////////////////////////////////////


