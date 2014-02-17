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

- (id) initWithDelegate:(id<WDStyleOptionsDelegate>)delegate
{
	self = [super init];
	if (self != nil)
	{
		mDelegate = delegate;
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) decodeContainerWithCoder:(NSCoder *)coder
{
	NSString *classNameKey = NSStringFromClass([self class]);
	if ([coder containsValueForKey:classNameKey])
	{ mContainer = [coder decodeObjectForKey:classNameKey]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) encodeContainerWithCoder:(NSCoder *)coder
{
	if (mContainer != nil)
	[coder encodeObject:mContainer forKey:NSStringFromClass([self class])];
}

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

- (void) _setOptions:(WDStyleOptions *)options
{ [self setValue:options forKey:NSStringFromClass([options class])]; }

////////////////////////////////////////////////////////////////////////////////

- (void) setOptions:(WDStyleOptions *)options
{
	[mDelegate styleOptions:self willSetOptions:options];
	[self _setOptions:options];
	[mDelegate styleOptions:self didSetOptions:options];
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) renderAreaForRect:(CGRect)sourceRect
{ return sourceRect; }

////////////////////////////////////////////////////////////////////////////////

- (void) prepareCGContext:(CGContextRef)context
{
	for (id options in [mContainer objectEnumerator])
	{ [options prepareCGContext:context]; }
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






