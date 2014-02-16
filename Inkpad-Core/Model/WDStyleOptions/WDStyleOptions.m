////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleOptions
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDStyleOptions.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDStyleOptions
////////////////////////////////////////////////////////////////////////////////

+ (id) styleOptionsWithContainer:(NSDictionary *)container
{ return [[self alloc] initWithContainer:container]; }

- (id) initWithContainer:(id)container
{
	self = [super init];
	if (self != nil)
	{
		mContainer = container;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self != nil)
	{
		NSString *classNameKey = NSStringFromClass([self class]);
		if ([coder containsValueForKey:classNameKey])
		{ mContainer = [coder decodeObjectForKey:classNameKey]; }
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeWithCoder:(NSCoder *)coder
{
	if (mContainer != nil)
	[coder encodeObject:mContainer forKey:NSStringFromClass([self class])];
}

////////////////////////////////////////////////////////////////////////////////

/*
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
*/
////////////////////////////////////////////////////////////////////////////////

- (id) container
{ return mContainer ? mContainer : (mContainer = [NSMutableDictionary new]); }

- (id) mutableContainer
{
	return [[self container] isKindOfClass:[NSMutableDictionary class]] ?
	mContainer : (mContainer = [mContainer mutableCopy]);
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) containsValueForKey:(id)key
{ return [[self container] containsValueForKey:key]; }

- (id) valueForKey:(id)key
{ return [[self container] valueForKey:key]; }

- (void) setValue:(id)value forKey:(id)key
{ [[self mutableContainer] setValue:value forKey:key]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setStyleOptions:(WDStyleOptions *)options
{ [self setValue:options forKey:NSStringFromClass([options class])]; }

////////////////////////////////////////////////////////////////////////////////
/*
	sub options are considered immutable, so we simply return a default object
	which is how the options are rendered.
	caller must always store adjusted sub options for changes to take effect.
*/
- (id) styleOptionsForKey:(id)key
{
	id options = [self valueForKey:key];
	if (options == nil)
	{
		options = [NSClassFromString(key) new];
	}

	return options;
}

////////////////////////////////////////////////////////////////////////////////

+ (CGRect) renderAreaForRect:(CGRect)sourceRect withOptions:(id)options
{ return [[self styleOptionsWithContainer:options] renderAreaForRect:sourceRect]; }

- (CGRect) renderAreaForRect:(CGRect)sourceRect
{ return sourceRect; }

////////////////////////////////////////////////////////////////////////////////

+ (void) applyOptions:(NSDictionary *)container inContext:(CGContextRef)context
{
	if (container != nil)
	{ [[self styleOptionsWithContainer:container] applyInContext:context]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) applyInContext:(CGContextRef)context
{
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






