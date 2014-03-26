////////////////////////////////////////////////////////////////////////////////
/*  
	WDAdobeColorBook.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2011-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#include "WDAdobeColorBook.h"

////////////////////////////////////////////////////////////////////////////////
// Utility functions to fetch elements from big endian colorbook data

static uint16_t ColorBookData_FetchUInt16(const Byte *data)
{ return CFSwapInt16BigToHost(((uint16_t *)data)[0]); }

static uint32_t ColorBookData_FetchUInt32(const Byte *data)
{ return CFSwapInt32BigToHost(((uint32_t *)data)[0]); }

////////////////////////////////////////////////////////////////////////////////

NSString *ColorBookData_FetchString(const Byte *data)
{
	size_t total = ColorBookData_FetchUInt32(data); 
	return [[NSString alloc] initWithBytes:&data[4] 
	length:total*sizeof(unichar) encoding:NSUTF16BigEndianStringEncoding];
}

////////////////////////////////////////////////////////////////////////////////

NSString *ColorBookData_FetchCleanString(const Byte *data)
{
	NSString *name = ColorBookData_FetchString(data);
	
	// Remove precursor crap
	name = [[name componentsSeparatedByString:@"="] lastObject]; 
	// Remove quotes, always assume unquoted material
	name = [name stringByReplacingOccurrencesOfString:@"\"" withString:@""];
	// Replace copyright sign
	name = [name stringByReplacingOccurrencesOfString:@"^C" withString:@" ©"];
	// Replace trademark sign
	name = [name stringByReplacingOccurrencesOfString:@"^R" withString:@" ®"];
	
	return name;
}

////////////////////////////////////////////////////////////////////////////////

const Byte *ColorBookData_SkipString(const Byte *data)
{ return data + 4 + 2*ColorBookData_FetchUInt32(data); }

////////////////////////////////////////////////////////////////////////////////
// Create color entry string

NSString *ColorBookData_FetchEntry(const Byte *data)
{
	// Fetch color name
	NSString *name = ColorBookData_FetchCleanString(data);	
	data = ColorBookData_SkipString(data);
		
	float L = 100.0;
	float a = 0.0;
	float b = 0.0;
	
	if (name.length != 0)
	{
		// Skip color id
		data += 6;
		L = data[0]/2.55;
		a = data[1]-128;
		b = data[2]-128;
	}
	
	return [name stringByAppendingFormat:@", %.1f, %.1f, %.1f", L, a, b];
}

////////////////////////////////////////////////////////////////////////////////

const Byte *ColorBookData_SkipEntry(const Byte *data)
{ return ColorBookData_SkipString(data)+6+3; }

////////////////////////////////////////////////////////////////////////////////

NSArray *ColorBookData_FetchList
(const Byte *dataPtr, uint16_t count)
{
	NSMutableArray *colorList = [NSMutableArray array];
	for (int n=0; n!=count; n++)
	{
		NSString *colorEntry = 
		ColorBookData_FetchEntry(dataPtr);
		
		if (colorEntry != nil) 
		{ [colorList addObject:colorEntry]; }
		
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr += 6;
		dataPtr += 3; 
	}					
	
	return colorList;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark 
////////////////////////////////////////////////////////////////////////////////

bool ColorBookData_ValidHeader(const Byte *dataPtr)		
{
	if (dataPtr == nil) return false;
	
	uint32_t fileID = ColorBookData_FetchUInt32(dataPtr); dataPtr += 4;
	if (fileID != '8BCB') return false;

	uint16_t fileVersion = ColorBookData_FetchUInt16(dataPtr); dataPtr += 2;
	if (fileVersion != 1) return false;
	
	return true;
}

////////////////////////////////////////////////////////////////////////////////

const Byte *ColorBookData_SkipHeader(const Byte *dataPtr)
{ return dataPtr + 4 + 2; }

////////////////////////////////////////////////////////////////////////////////

uint16_t AdobeColorBookData_FetchColorType(const Byte *dataPtr)
{
	if (ColorBookData_ValidHeader(dataPtr))
	{
		dataPtr += 4;
		dataPtr += 2;
		dataPtr += 2;
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr += 2;
		dataPtr += 2;
		dataPtr += 2;
		return ColorBookData_FetchUInt16(dataPtr);
	}
	
	return (-1);
}

////////////////////////////////////////////////////////////////////////////////

bool AdobeColorBookData_IsLabColor(const Byte *dataPtr)
{ return AdobeColorBookData_FetchColorType(dataPtr)==7; }

////////////////////////////////////////////////////////////////////////////////

NSString *AdobeColorBookData_FetchName(const Byte *dataPtr)
{
	if (ColorBookData_ValidHeader(dataPtr))
	{
		dataPtr += 4;
		dataPtr += 2;
		dataPtr += 2;
		return ColorBookData_FetchCleanString(dataPtr);
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

NSString *AdobeColorBookData_FetchDescription(const Byte *dataPtr)
{
	if (ColorBookData_ValidHeader(dataPtr))
	{
		dataPtr += 4;
		dataPtr += 2;
		dataPtr += 2;
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		return ColorBookData_FetchCleanString(dataPtr);
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

uint16_t AdobeColorBookData_FetchPageSize(const Byte *dataPtr)
{ 
	if (ColorBookData_ValidHeader(dataPtr))
	{
		dataPtr += 4;
		dataPtr += 2;
		dataPtr += 2;
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr += 2;
		return ColorBookData_FetchUInt16(dataPtr);
	}
	
	return nil;	
}

////////////////////////////////////////////////////////////////////////////////

NSArray *AdobeColorBookData_FetchColors(const Byte *dataPtr)
{
	if (ColorBookData_ValidHeader(dataPtr))
	{
		dataPtr += 4;
		dataPtr += 2;
		dataPtr += 2;
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		dataPtr = ColorBookData_SkipString(dataPtr);
		uint16_t count = ColorBookData_FetchUInt16(dataPtr);
		dataPtr += 2;
		dataPtr += 2;
		dataPtr += 2;
		dataPtr += 2;
		return ColorBookData_FetchList(dataPtr, count);		
	}
	
	return nil;	
}

////////////////////////////////////////////////////////////////////////////////

NSString *const WDAdobeColorBookIDKey = @"AdobeColorBookID";
NSString *const WDAdobeColorBookNameKey = @"AdobeColorBookName";
NSString *const WDAdobeColorBookPrefixKey = @"AdobeColorBookPrefix";
NSString *const WDAdobeColorBookPostfixKey = @"AdobeColorBookPostfix";
NSString *const WDAdobeColorBookDescriptionKey = @"AdobeColorBookDescription";
NSString *const WDAdobeColorBookColorCountKey = @"AdobeColorBookColorCount";
NSString *const WDAdobeColorBookPageSizeKey = @"AdobeColorBookPageSize";
NSString *const WDAdobeColorBookKeyIndexKey = @"AdobeColorBookKeyIndex";
NSString *const WDAdobeColorBookColorTypeKey = @"AdobeColorBookColorType";
NSString *const WDAdobeColorBookColorListKey = @"AdobeColorBookColorList";

////////////////////////////////////////////////////////////////////////////////

NSDictionary *AdobeColorBookCreate(NSData *data)
{
	const Byte *dataPtr = [data bytes];
	if (!ColorBookData_ValidHeader(dataPtr)) return nil;

	// Skip header
	dataPtr += 4;
	dataPtr += 2;
	
	// Adobe BookID 
	uint16_t bookID = ColorBookData_FetchUInt16(dataPtr); 
	dataPtr += 2;
	
	// Name, Prefix, Postfix, Description
	NSString *name = ColorBookData_FetchString(dataPtr); 
	dataPtr = ColorBookData_SkipString(dataPtr);
	NSString *prefix = ColorBookData_FetchString(dataPtr); 
	dataPtr = ColorBookData_SkipString(dataPtr);
	NSString *postfix = ColorBookData_FetchString(dataPtr); 
	dataPtr = ColorBookData_SkipString(dataPtr);
	NSString *description = ColorBookData_FetchString(dataPtr); 
	dataPtr = ColorBookData_SkipString(dataPtr);
	
	// Count, pageSize, keyIndex, colorType
	uint16_t colorCount = ColorBookData_FetchUInt16(dataPtr); 
	dataPtr += 2;
	uint16_t pageSize = ColorBookData_FetchUInt16(dataPtr); 
	dataPtr += 2;
	uint16_t keyIndex = ColorBookData_FetchUInt16(dataPtr); 
	dataPtr += 2;
	uint16_t colorType = ColorBookData_FetchUInt16(dataPtr); 
	dataPtr += 2;
	
	NSArray *colorList = ColorBookData_FetchList(dataPtr, colorCount);
	
	// setValue:forKey:
	return @{
		WDAdobeColorBookIDKey : @(bookID), 
		WDAdobeColorBookNameKey : name,
		WDAdobeColorBookPrefixKey : prefix,
		WDAdobeColorBookPostfixKey : postfix,
		WDAdobeColorBookDescriptionKey : description,
		WDAdobeColorBookColorCountKey : @(colorCount),
		WDAdobeColorBookPageSizeKey : @(pageSize),
		WDAdobeColorBookKeyIndexKey : @(keyIndex),
		WDAdobeColorBookColorTypeKey : @(colorType),
		WDAdobeColorBookColorListKey : colorList
	};
}

////////////////////////////////////////////////////////////////////////////////

int AdobeColorBookGetColorType(NSDictionary *colorBook)
{ return [[colorBook valueForKey:WDAdobeColorBookColorTypeKey] intValue]; }

bool AdobeColorBookIsLabColor(NSDictionary *colorBook)
{ return AdobeColorBookGetColorType(colorBook) == 7; }

////////////////////////////////////////////////////////////////////////////////





