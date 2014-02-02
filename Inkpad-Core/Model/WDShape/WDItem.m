////////////////////////////////////////////////////////////////////////////////
/*
	WDItem
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDItem.h"
#import "WDUtilities.h"
#import "WDGLUtilities.h"

////////////////////////////////////////////////////////////////////////////////

static NSString *WDItemVersionKey = @"WDItemVersion";

static NSInteger WDItemVersion = 1;
static NSString *WDItemSizeKey = @"WDItemSize";
static NSString *WDItemTransformKey = @"WDItemTransform";

////////////////////////////////////////////////////////////////////////////////
@implementation WDItem
////////////////////////////////////////////////////////////////////////////////

@synthesize itemManager = mItemManager;

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self flushCache];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) itemWithFrame:(CGRect)frame
{ return [[self alloc] initWithFrame:frame]; }

- (id) initWithFrame:(CGRect)frame
{
	self = [super init];
	if (self != nil)
	{
		[self setFrame:frame];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{
	WDItem *item = [[[self class] allocWithZone:zone] init];
	if (item != nil)
	{
		item->mSize = self->mSize;
		item->mTransform = self->mTransform;
	}

	return item;
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:WDItemVersion forKey:WDItemVersionKey];
	[coder encodeCGSize:mSize forKey:WDItemSizeKey];
	[coder encodeCGAffineTransform:mTransform forKey:WDItemTransformKey];
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{
		mTransform = CGAffineTransformIdentity;

		if (![self readFromCoder:coder])
		{ self = nil; }
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) readFromCoder:(NSCoder *)coder
{
	// Always attempt to read regardless of version
//	NSInteger version = \
	[coder decodeIntegerForKey:WDItemVersionKey];

	if ([coder containsValueForKey:WDItemSizeKey])
	{ mSize = [coder decodeCGSizeForKey:WDItemSizeKey]; }

	if ([coder containsValueForKey:WDItemTransformKey])
	{ mTransform = [coder decodeCGAffineTransformForKey:WDItemTransformKey]; }

	return mSize.width > 0.0 && mSize.height > 0.0;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Parameters
////////////////////////////////////////////////////////////////////////////////

- (void) setSize:(CGSize)size
{
	if ((mSize.width!=size.width)||
		(mSize.height!=size.height))
	{
		mSize = size;
		[self flushSource];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setPosition:(CGPoint)P
{
	if ((mTransform.tx != P.x)||
		(mTransform.ty != P.y))
	{
		mTransform.tx = P.x;
		mTransform.ty = P.y;
		[self flushResult];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFrame:(CGRect)frame
{
	[self setPosition:(CGPoint){ CGRectGetMidX(frame), CGRectGetMidY(frame) }];
	[self setSize:frame.size];
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) transform
{ return mTransform; }

- (void) setTransform:(CGAffineTransform)T
{
	mTransform = T;
	[self flushResult];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (void) flushCache
{
	[self flushSource];
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushSource
{
	[self flushResult];
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushResult
{
	[self flushFramePath];
	[self flushFrameBounds];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Frame
////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceRect
{ return (CGRect){{-0.5*mSize.width, -0.5*mSize.height}, mSize }; }

////////////////////////////////////////////////////////////////////////////////

- (CGRect) frameBounds
{
	return
	mFrameBounds.size.width != 0 ||
	mFrameBounds.size.height != 0 ?
	mFrameBounds : (mFrameBounds =
	CGRectApplyAffineTransform([self sourceRect], mTransform));
}

////////////////////////////////////////////////////////////////////////////////

- (void) flushFrameBounds
{ mFrameBounds.size.width = mFrameBounds.size.height = 0.0; }

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) framePath
{
	return mFramePath ? mFramePath :
	(mFramePath = [self createFramePath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createFramePath
{ return CGPathCreateWithRect([self sourceRect], &mTransform); }

////////////////////////////////////////////////////////////////////////////////

- (void) flushFramePath
{
	if (mFramePath != nil)
	{
		CGPathRelease(mFramePath);
		mFramePath = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustFrame:(CGRect)frame
{
	// Allow item manager to prepare
	[[self itemManager] itemWillAdjust:self];

	// Set new frame
	[self setFrame:frame];

	// Allow item manager to respond
	[[self itemManager] itemDidAdjust:self];
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustTransform:(CGAffineTransform)T
{
	// Allow item manager to prepare
	[[self itemManager] itemWillAdjust:self];

	// Set new bounds
	[self setTransform:T];

	// Allow item manager to respond
	[[self itemManager] itemDidAdjust:self];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
// TODO: rename to applyTransform:

- (void) applyTransform:(CGAffineTransform)T
{
	T = CGAffineTransformConcat(mTransform, T);
	[self adjustTransform:T];
}

////////////////////////////////////////////////////////////////////////////////

- (void) glRenderHighLightWithTransform:(CGAffineTransform)transform
{
	WDGLRenderCGPathRefWithTransform([self framePath], transform);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






