////////////////////////////////////////////////////////////////////////////////
/*
	WDText.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_MAC
#import <UIKit/UIKit.h>
#endif

#import <CoreText/CoreText.h>
#import "WDStylable.h"
#import "WDTextRenderer.h"

@class WDStrokeStyle;

@protocol WDPathPainter;

////////////////////////////////////////////////////////////////////////////////
/*
	Since Apple seems confused about its alignment, 
	might as well define a proper set, so we only have to translate once.
	
	Note that we will eventually introduce WDTextOptions & WDFontOptions 
	where this should also find its place...
*/

typedef enum WDTextAlignment
{
	kWDTextAlignDefault = 0, // script default
	kWDTextAlignLeft,
	kWDTextAlignCenter,
	kWDTextAlignRight,
	kWDTextAlignJustified
}
WDTextAlignment;
////////////////////////////////////////////////////////////////////////////////



@interface WDText : WDStylable <NSCoding, NSCopying, WDTextRenderer>
{
	// Cache
	CGPathRef mTextPath;

//	float               width_;
	CGAffineTransform   transform_;

	WDTextAlignment     alignment_;
	NSString            *fontName_;
	float               fontSize_;
	
	CGMutablePathRef    pathRef_;
	
	BOOL                needsLayout_;
	NSMutableArray      *glyphs_;
	CGRect              styleBounds_;
	
	NSString            *cachedText_;
	CGAffineTransform   cachedTransform_;
	float               cachedWidth_;
	BOOL                cachingWidth_;	
}

@property (nonatomic, strong) NSString *text;

@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) WDTextAlignment alignment;
@property (nonatomic, readonly) CGRect naturalBounds;
//@property (nonatomic, readonly) CTFontRef fontRef;
@property (nonatomic, readonly, strong) NSAttributedString *attributedString;


- (CGFloat) width;
- (void) setWidth:(CGFloat)width;

- (void) registerUndoWithCachedTransformAndWidth;
/*
- (void) setFontName:(NSString *)fontName;
- (void) setFontSize:(float)fontSize;

+ (float) minimumWidth;
- (void) moveHandle:(NSUInteger)handle toPoint:(CGPoint)pt;


- (void) cacheTransformAndWidth;

// an array of WDPath objects representing each glyph in the text object
- (NSArray *) outlines;

- (void) drawOpenGLTextOutlinesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;

- (void) setFontNameQuiet:(NSString *)fontName;
- (void) setFontSizeQuiet:(float)fontSize;
- (void) setTextQuiet:(NSString *)text;
- (void) setTransformQuiet:(CGAffineTransform)transform;
- (void) setWidthQuiet:(float)width;
*/
@end




