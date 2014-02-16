////////////////////////////////////////////////////////////////////////////////
/*
	WDBlendStyle.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDBlendStyle.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////

const NSString *WDBlendStyleOptionsKey = @"WDBlendStyle";
const NSString *WDBlendStyleModeKey = @"WDBlendStyleMode";
const NSString *WDBlendStyleOpacityKey = @"WDBlendStyleOpacity";

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@implementation WDBlendStyle
////////////////////////////////////////////////////////////////////////////////

- (void) applyInContext:(CGContextRef)context
{
	if (context != nil)
	{
		CGContextSetBlendMode(context, [self blendMode]);
		CGContextSetAlpha(context, [self opacity]);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGBlendMode) blendMode
{
	return [self containsValueForKey:WDBlendStyleModeKey]?
	[[self valueForKey:WDBlendStyleModeKey] intValue] : kCGBlendModeNormal;
}

- (void) setBlendMode:(CGBlendMode)blendMode
{ [self setValue:[NSNumber numberWithInt:blendMode] forKey:WDBlendStyleModeKey]; }

////////////////////////////////////////////////////////////////////////////////

- (CGFloat)opacity
{
	return [self containsValueForKey:WDBlendStyleOpacityKey]?
	[[self valueForKey:WDBlendStyleOpacityKey] doubleValue] : 1.0;
}

- (void) setOpacity:(CGFloat)opacity
{ [self setValue:NSNumberFromCGFloat(opacity) forKey:WDBlendStyleOpacityKey]; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



