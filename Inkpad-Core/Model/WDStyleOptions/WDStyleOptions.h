////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleOptions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
/*
	WDStyleOptions objects are controller objects for internal dictionaries. 

*/
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@interface WDStyleOptions : NSObject <NSCoding>
{
	id mContainer;
}

+ (id) styleOptionsWithContainer:(NSDictionary *)container;
- (id) initWithContainer:(NSDictionary *)container;
- (id) initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder:(NSCoder *)coder;
// Stuffs mOptions with className as key in current coder context


- (BOOL) containsValueForKey:(id)key;
- (id) valueForKey:(id)key;
- (void) setValue:(id)value forKey:(id)key;
- (void) setStyleOptions:(WDStyleOptions *)options;

- (CGRect) renderAreaForRect:(CGRect)sourceRect;
+ (CGRect) renderAreaForRect:(CGRect)sourceRect withOptions:(id)options;

+ (void) applyOptions:(NSDictionary *)container inContext:(CGContextRef)context;
- (void) applyInContext:(CGContextRef)context;

@end
////////////////////////////////////////////////////////////////////////////////




