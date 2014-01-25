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

#include "WDGLVertexBuffer.h"

////////////////////////////////////////////////////////////////////////////////

WDGLVertexBuffer WDGLVertexBufferBegin(void)
{ return WDGLVertexBufferNULL; }

////////////////////////////////////////////////////////////////////////////////

void WDGLVertexBufferEnd(WDGLVertexBuffer *vertexBuffer)
{
	if (vertexBuffer != NULL)
	{
		if (vertexBuffer->data != NULL)
		{ free(vertexBuffer->data); }
		*vertexBuffer = WDGLVertexBufferBegin();
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferReallocPtr
	--------------------------
	Both initializes and extends the data ptr as necessary.
*/

static bool WDGLVertexBufferReallocPtr(WDGLVertexBuffer *vertexBuffer)
{
	GLuint limit = vertexBuffer->limit;

	// Extend in blocks
	limit += 256;
	// Compute new size
	size_t size = limit * sizeof(GLfloat);

	// Recreate
	void *src = vertexBuffer->data;
	void *dst = realloc(src, size);
	if (dst != NULL)
	{
		vertexBuffer->data = dst;
		vertexBuffer->limit = limit;
		return true;
	}

	return false;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferAdd
	-------------------
	Add (x,y) coordinates to buffer
	
	Beware that this code works because we add 2 values and
	extend by even sized blocks.
*/

bool WDGLVertexBufferAdd(WDGLVertexBuffer *vertexBuffer, GLfloat x, GLfloat y)
{
	GLuint count = vertexBuffer->count;
	GLuint limit = vertexBuffer->limit;

	// Check for space, realloc if necessary
	if ((count != limit)||
		WDGLVertexBufferReallocPtr(vertexBuffer))
	{
		// Add coordinates
		vertexBuffer->data[count++] = x;
		vertexBuffer->data[count++] = y;
		vertexBuffer->count = count;
		// Report success
		return true;
	}

	// Memory failure
	return false;
}

////////////////////////////////////////////////////////////////////////////////
/*
	WDGLVertexBufferDraw
	--------------------
	Transfer vertexdata to openGL 
	
	Currently resets count. This is generally the desired behavior.

	Work around:
		GLuint count = vertexBuffer->count;
		WDGLVertexBufferDraw(vertexBuffer, GL_...);
		vertexBuffer->count = count;
*/

void WDGLVertexBufferDraw(WDGLVertexBuffer *vertexBuffer, GLenum type)
{
	if (vertexBuffer->count != 0)
	{
		glVertexPointer(2, GL_FLOAT, 0, vertexBuffer->data);
		glDrawArrays(type, 0, vertexBuffer->count/2);

		vertexBuffer->count = 0;
	}
}

////////////////////////////////////////////////////////////////////////////////

void WDGLVertexBufferFlush(WDGLVertexBuffer *vertexBuffer)
{
	if (vertexBuffer->count != 0)
	{
		// Save last vector for potential re-use.
		vertexBuffer->data[0] = vertexBuffer->data[vertexBuffer->count-2];
		vertexBuffer->data[1] = vertexBuffer->data[vertexBuffer->count-1];
		// Reset count
		vertexBuffer->count = 0;
	}
}

////////////////////////////////////////////////////////////////////////////////




