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

- (id) init
{
	self = [super init];
	if (self != nil)
	{ [self initProperties]; }

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithCoder:(NSCoder *)coder
{
	self = [self init];

	if (self != nil)
	{ [self decodeWithCoder:coder]; }

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) initWithPropertiesFrom:(id)src
{
	self = [self init];

	if (self != nil)
	{ [self takePropertiesFrom:src]; }

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (id) copyWithZone:(NSZone *)zone
{ return [[[self class] alloc] initWithPropertiesFrom:self]; }

////////////////////////////////////////////////////////////////////////////////

- (void) initProperties {}

- (void) takePropertiesFrom:(id)src {}

- (void) encodeWithCoder:(NSCoder *)coder {}

- (void) decodeWithCoder:(NSCoder *)coder {}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) resultAreaForRect:(CGRect)sourceRect
{ return sourceRect; }

- (void) prepareCGContext:(CGContextRef)context {}
////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////






