////////////////////////////////////////////////////////////////////////////////
/*  
	WDAdobeColorBook.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2011-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////

extern NSString *const WDAdobeColorBookIDKey;
extern NSString *const WDAdobeColorBookNameKey;
extern NSString *const WDAdobeColorBookPrefixKey;
extern NSString *const WDAdobeColorBookPostfixKey;
extern NSString *const WDAdobeColorBookDescriptionKey;
extern NSString *const WDAdobeColorBookColorCountKey;
extern NSString *const WDAdobeColorBookPageSizeKey;
extern NSString *const WDAdobeColorBookKeyIndexKey;
extern NSString *const WDAdobeColorBookColorTypeKey;
extern NSString *const WDAdobeColorBookColorListKey;

////////////////////////////////////////////////////////////////////////////////

NSDictionary *AdobeColorBookCreate(NSData *data);
bool AdobeColorBookIsLabColor(NSDictionary *colorBook);
int AdobeColorBookGetColorType(NSDictionary *colorBook);

bool AdobeColorBookData_IsLabColor(const Byte *dataPtr);
NSString *AdobeColorBookData_FetchName(const Byte *dataPtr);
NSString *AdobeColorBookData_FetchDescription(const Byte *dataPtr);
NSArray *AdobeColorBookData_FetchColors(const Byte *dataPtr);
uint16_t AdobeColorBookData_FetchPageSize(const Byte *dataPtr);

////////////////////////////////////////////////////////////////////////////////






