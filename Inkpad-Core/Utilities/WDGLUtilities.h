////////////////////////////////////////////////////////////////////////////////
/*  
	WDGLVertexBuffer
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2011-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#if TARGET_OS_IPHONE
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#else 
#import <OpenGL/gl.h>
#endif

////////////////////////////////////////////////////////////////////////////////

void WDGLFillRect(CGRect R);
void WDGLStrokeRect(CGRect R);
void WDGLStrokeRectWithSize(CGRect R, CGFloat size);

////////////////////////////////////////////////////////////////////////////////

void WDGLSetMarkerDefaultsForScale(CGFloat scale);

void WDGLFillSquareMarker(CGPoint P);
void WDGLStrokeSquareMarker(CGPoint P);
void WDGLFillCircleMarker(CGPoint P);
void WDGLStrokeCircleMarker(CGPoint P);
void WDGLFillDiamondMarker(CGPoint P);
void WDGLStrokeDiamondMarker(CGPoint P);

////////////////////////////////////////////////////////////////////////////////

void WDGLLineFromPointToPoint(CGPoint a, CGPoint b);

void WDGLRenderCGPathRef(CGPathRef pathRef);

#include "WDBezierSegment.h"
void WDGLVertexBufferAddSegment(WDBezierSegment S);
void WDGLVertexBufferDrawData(GLenum type);

////////////////////////////////////////////////////////////////////////////////



