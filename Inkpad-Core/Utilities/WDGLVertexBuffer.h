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
#pragma once
#ifndef __WDGLVERTEXBUFFER__
#define __WDGLVERTEXBUFFER__
#ifdef __cplusplus
extern "C" {
#endif
////////////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <stdbool.h>
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#include <OpenGLES/ES1/gl.h>
#else 
#include <OpenGL/gl.h>
#endif

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBuffer
	----------------
	Auto-extending vertex buffer 
	
	Usage indication:
	
		// Initialize
		WDGLVertexBuffer vertexBuffer = WDGLVertexBufferBegin();
		
		// Add points as necessary
		WDGLVertexBufferAdd(&vertexBuffer, x, y);
		WDGLVertexBufferAdd(&vertexBuffer, x, y);
		WDGLVertexBufferAdd(&vertexBuffer, x, y);
		...
		
		// Draw using a "BeginMode" constant (GL_POINTS etc)
		WDGLVertexBufferDraw(&vertexBuffer, GL_...);

		// Free internal memory
		WDGLVertexBufferEnd(&vertexBuffer);


	Alternatively, initialization can be achieved as shown below
	which allows global declarations:
		
		WDGLVertexBuffer vertexBuffer = mWDGLVertexBufferNULL;
*/

typedef struct
{
	GLuint 	count;
	GLuint 	limit;
	GLfloat *data;
}
WDGLVertexBuffer;

#define WDGLVertexBufferNULL 	((WDGLVertexBuffer){ 0, 0, NULL })
////////////////////////////////////////////////////////////////////////////////

WDGLVertexBuffer WDGLVertexBufferBegin(void);
bool WDGLVertexBufferAdd(WDGLVertexBuffer *vertexBuffer, GLfloat x, GLfloat y);
void WDGLVertexBufferDraw(WDGLVertexBuffer *vertexBuffer, GLenum type);
void WDGLVertexBufferEnd(WDGLVertexBuffer *vertexBuffer);

////////////////////////////////////////////////////////////////////////////////
#ifdef __cplusplus
}
#endif
#endif
////////////////////////////////////////////////////////////////////////////////






