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
@protocol WDStyleOptionsProtocol
- (void) initProperties;
- (void) copyPropertiesFrom:(id)src;
- (void) encodeWithCoder:(NSCoder *)coder;
- (void) decodeWithCoder:(NSCoder *)coder;
- (void) prepareCGContext:(CGContextRef)context scale:(CGFloat)scale;
@end
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
@interface WDStyleOptions : NSObject <WDStyleOptionsProtocol>

- (id) init;
- (id) initWithCoder:(NSCoder *)coder;
- (id) initWithPropertiesFrom:(id)src;
- (id) copyWithZone:(NSZone *)zone;

- (CGRect) resultAreaForRect:(CGRect)sourceRect;

@end
////////////////////////////////////////////////////////////////////////////////




