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

static NSInteger WDItemMasterVersion = 1;
static NSString *WDItemMasterVersionKey = @"WDItemVersion";

static NSString *WDItemNameKey = @"WDItemName";
static NSString *WDItemVersionKey = @"WDItemVersion";
static NSString *WDItemSizeKey = @"WDItemSize";
static NSString *WDItemPositionKey = @"WDShapePosition";
static NSString *WDItemRotationKey = @"WDShapeRotation";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDItem
////////////////////////////////////////////////////////////////////////////////

@synthesize itemOwner = mOwner;

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self flushFramePath];
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
		item->mPosition = self->mPosition;
		item->mRotation = self->mRotation;
	}

	return item;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Encoding
////////////////////////////////////////////////////////////////////////////////

- (id) itemName
{ return NSStringFromClass([self class]); }

- (NSInteger) itemVersion
{ return 0; }

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:WDItemMasterVersion forKey:WDItemMasterVersionKey];

	[self encodeTypeWithCoder:coder];
	[self encodeSizeWithCoder:coder];
	[self encodePositionWithCoder:coder];
	[self encodeRotationWithCoder:coder];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeTypeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[self itemName] forKey:WDItemNameKey];
	[coder encodeInteger:[self itemVersion] forKey:WDItemVersionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeSizeWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGSize(mSize);
	[coder encodeObject:str forKey:WDItemSizeKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodePositionWithCoder:(NSCoder *)coder
{
	NSString *str = NSStringFromCGPoint(mPosition);
	[coder encodeObject:str forKey:WDItemPositionKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeRotationWithCoder:(NSCoder *)coder
{
	NSString *str = sizeof(mRotation) > 32 ?
	[[NSNumber numberWithDouble:mRotation] stringValue]:
	[[NSNumber numberWithFloat:mRotation] stringValue];
	[coder encodeObject:str forKey:WDItemRotationKey];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Decoding
////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{
		mSize = (CGSize){ 2.0, 2.0 };
		mPosition = (CGPoint){ 0.0, 0.0 };
		mRotation = 0.0;

		NSInteger version =
		[coder decodeIntegerForKey:WDItemMasterVersionKey];

		if (version == WDItemMasterVersion)
		{ }
		[self decodeWithCoder:coder];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) decodeWithCoder:(NSCoder *)coder
{
	[self decodeSizeWithCoder:coder];
	[self decodePositionWithCoder:coder];
	[self decodeRotationWithCoder:coder];

	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeSizeWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDItemSizeKey])
	{
		NSString *str = [coder decodeObjectForKey:WDItemSizeKey];
		if (str != nil) { mSize = CGSizeFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodePositionWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDItemPositionKey])
	{
		NSString *str = [coder decodeObjectForKey:WDItemPositionKey];
		if (str != nil) { mPosition = CGPointFromString(str); }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeRotationWithCoder:(NSCoder *)coder
{
	if ([coder containsValueForKey:WDItemRotationKey])
	{
		NSString *str = [coder decodeObjectForKey:WDItemRotationKey];
		if (str != nil)
		{
			mRotation = sizeof(mRotation)>32 ?
			[str doubleValue] : [str floatValue];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////
/*
	setSize
	-------
	Set size of content
*/

- (void) setSize:(CGSize)size
{
	if ((mSize.width!=size.width)||
		(mSize.height!=size.height))
	{
		mSize = size;
		[self updateCache];
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	setPosition
	-----------
	Set position of result shape
*/

- (void) setPosition:(CGPoint)P
{
	if ((mPosition.x != P.x)||
		(mPosition.y != P.y))
	{
		mPosition.x = P.x;
		mPosition.y = P.y;
		[self updateCache];
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	setRotation
	-----------
	Set rotation of result shape
*/

- (void) setRotation:(CGFloat)degrees
{
	if (mRotation != degrees)
	{
		mRotation = degrees;
		[self updateCache];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
/*
	setFrame
	--------
	Set size and position, reset rotation
*/

- (void) setFrame:(CGRect)frame
{
	[self setSize:frame.size];
	[self setPosition:(CGPoint){ CGRectGetMidX(frame), CGRectGetMidY(frame) }];
	[self setRotation:0.0];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) sourceRect
{
	if ([mContent isKindOfClass:[NSArray class]])
	{
		CGRect R = CGRectNull;
		for (id item in mContent)
		{ R = CGRectUnion(R, [item sourceRect]); }
		return R;
	}
	else
	if ([mContent isKindOfClass:[WDItem class]])
	{
		return [mContent sourceRect];
	}

	return (CGRect){ -0.5*mSize.width, -0.5*mSize.height, mSize.width, mSize.height };
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) frameRect
{ return CGRectApplyAffineTransform([self sourceRect], mTransform); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Frame Path
////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) framePath
{
	return mFramePath ? mFramePath :
	(mFramePath = [self createFramePath]);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPathRef) createFramePath
{
	return CGPathCreateWithRect([self sourceRect], &mTransform);
}

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
#pragma mark -
#pragma mark Cache
////////////////////////////////////////////////////////////////////////////////

- (void) updateCache
{
	[self updateTransform];
	/*
		if (mCachedSize != mSize)
		{
			update contents for size
			mCachedSize = mSize;
		}
	*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateTransform
{
	mTransform = [self computeTransform];
}

////////////////////////////////////////////////////////////////////////////////

- (CGAffineTransform) computeTransform
{
	CGAffineTransform T =
	{ 1.0, 0.0, 0.0, 1.0, mPosition.x, mPosition.y};

	if (mRotation != 0.0)
	{
		CGFloat angle = mRotation * M_PI / 180.0;
		T.a = cos(angle);
		T.b = sin(angle);
		T.c = -T.b;
		T.d = +T.a;
	}

	return T;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






