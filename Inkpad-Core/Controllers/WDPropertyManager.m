////////////////////////////////////////////////////////////////////////////////
/*
	WDPropertyManager.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDAbstractPath.h"
#import "WDColor.h"
#import "WDDrawingController.h"
#import "WDFontManager.h"
#import "WDGradient.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"
#import "WDShadow.h"

NSString *const WDInkpadUserDefaultsKey = @"WDInkpadUserDefaults";

NSString *WDInvalidPropertiesNotification = @"WDInvalidPropertiesNotification";

NSString *const WDActiveBlendChangedNotification = @"WDActiveBlendChangedNotification";
NSString *const WDActiveShadowChangedNotification = @"WDActiveShadowChangedNotification";
NSString *const WDActiveStrokeChangedNotification = @"WDActiveStrokeChangedNotification";

NSString *WDActiveFillChangedNotification = @"WDActiveFillChangedNotification";
NSString *WDInvalidPropertiesKey = @"WDInvalidPropertiesKey";

@interface WDPropertyManager (private)
- (BOOL) propertyAffectsActiveShadow:(NSString *)property;
- (BOOL) propertyAffectsActiveStroke:(NSString *)property;
@end

@implementation WDPropertyManager

@synthesize drawingController = drawingController_;
@synthesize ignoreSelectionChanges = ignoreSelectionChanges_;


- (WDStrokeStyle *) activeStrokeStyle
{ return nil; }
- (WDStrokeStyle *) defaultStrokeStyle
{ return nil; }

- (id<WDPathPainter>) activeFillStyle
{ return nil; }
- (id<WDPathPainter>) defaultFillStyle
{ return nil; }

- (WDShadow *) activeShadow
{ return nil; }
- (WDShadow *) defaultShadow
{ return nil; }

////////////////////////////////////////////////////////////////////////////////

- (id) init
{
	self = [super init];

	if (self != nil)
	{
		mCachedDefaults = [[self loadCachedDefaults] mutableCopy];
		if (mCachedDefaults == nil)
		{ mCachedDefaults = [NSMutableDictionary new]; }

		invalidProperties_ = [NSMutableSet new];

		// see if the default font has been uninstalled
		if (![[WDFontManager sharedInstance]
				validFont:[self defaultValueForProperty:WDFontNameProperty]])
		{ [self setDefaultValue:@"Helvetica" forProperty:WDFontNameProperty]; }
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// transfer our cached defaults to the real defaults
	[self saveCachedDefaults];
}

////////////////////////////////////////////////////////////////////////////////

- (void) saveCachedDefaults
{
	if (mCachedDefaults.count != 0)
	{
		NSData *data =
		[NSKeyedArchiver archivedDataWithRootObject:mCachedDefaults];
		if (data != nil)
		{
			[[NSUserDefaults standardUserDefaults]
			setObject:data forKey:WDInkpadUserDefaultsKey];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *) loadCachedDefaults
{
	NSData *data = [[NSUserDefaults standardUserDefaults]
	objectForKey:WDInkpadUserDefaultsKey];
	return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDrawingController:(WDDrawingController *)drawingController
{
	drawingController_ = drawingController;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(propertyChanged:)
												 name:WDPropertyChangedNotification
											   object:drawingController_.drawing];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(propertiesChanged:)
												 name:WDPropertiesChangedNotification
											   object:drawingController_.drawing];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(selectionChanged:)
												 name:WDSelectionChangedNotification
											   object:drawingController_];
}

////////////////////////////////////////////////////////////////////////////////

- (void) addToInvalidProperties:(NSString *)property
{
	if ([invalidProperties_ containsObject:property]) {
		return;
	}
	
	[invalidProperties_ addObject:property];
	
	if ([self propertyAffectsActiveShadow:property]) {
		[invalidProperties_ addObject:WDShadowVisibleProperty];
	}
	
	if ([self propertyAffectsActiveStroke:property]) {
		[invalidProperties_ addObject:WDStrokeVisibleProperty];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(invalidateProperties:) object:nil];
	[self performSelector:@selector(invalidateProperties:) withObject:nil afterDelay:0];
}

- (void) invalidateProperties:(id)obj
{
	// the default value for each property comes from the topmost selected object that has that property
	for (NSString *property in invalidProperties_) {
		for (WDElement *element in [[drawingController_ orderedSelectedObjects] reverseObjectEnumerator]) {
			if ([element valueForProperty:property]) {
				[self setDefaultValue:[element valueForProperty:property] forProperty:property];
				break;
			}
		}
	}

	// Send out invalidProperties_
	[[NSNotificationCenter defaultCenter]
	postNotificationName:WDInvalidPropertiesNotification
	object:self userInfo:@{WDInvalidPropertiesKey : invalidProperties_}];

	// Reset invalid properties
	invalidProperties_ = [NSMutableSet new];
}

- (void) propertiesChanged:(NSNotification *)aNotification
{
	NSDictionary    *dictionary = aNotification.userInfo;
	NSSet           *properties = dictionary[WDPropertiesKey];
	
	if (![properties isSubsetOfSet:invalidProperties_]) {
		[invalidProperties_ unionSet:properties];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(invalidateProperties:) object:nil];
		[self performSelector:@selector(invalidateProperties:) withObject:nil afterDelay:0];
	}
}

- (void) propertyChanged:(NSNotification *)aNotification
{
	NSDictionary    *dictionary = aNotification.userInfo;
	NSString        *property = dictionary[WDPropertyKey];
	
	if (![invalidProperties_ containsObject:property]) {
		[invalidProperties_ addObject:property];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(invalidateProperties:) object:nil];
		[self performSelector:@selector(invalidateProperties:) withObject:nil afterDelay:0];
	}
}

- (void) selectionChanged:(NSNotification *)aNotification
{
	if (ignoreSelectionChanges_) {
		return;
	}
	
	NSArray *selected = [drawingController_ orderedSelectedObjects];
	
	WDElement *topSelected = [selected lastObject];
	
	if (topSelected) {
		for (NSString *property in [topSelected inspectableProperties]) {
			[self setDefaultValue:[topSelected valueForProperty:property] forProperty:property];
		}
	
		[invalidProperties_ addObjectsFromArray:[[topSelected inspectableProperties] allObjects]];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(invalidateProperties:) object:nil];
		[self performSelector:@selector(invalidateProperties:) withObject:nil afterDelay:0];
	}
}

- (void) setIgnoreSelectionChanges:(BOOL)ignore
{
	ignoreSelectionChanges_ = ignore;
	
	if (!ignore) {
		// find out what's changed while we were ignoring
		[self selectionChanged:nil];
	}
}

- (BOOL) propertyAffectsActiveShadow:(NSString *)property
{
	static NSSet *shadowProperties = nil;
	
	if (!shadowProperties) {
		shadowProperties = [NSSet setWithObjects:
			WDOpacityProperty,
			WDShadowColorProperty,
			WDShadowAngleProperty,
			WDShadowOffsetProperty,
			WDShadowRadiusProperty,
			WDShadowVisibleProperty, nil];
	}
	
	return [shadowProperties containsObject:property];
}

- (BOOL) propertyAffectsActiveStroke:(NSString *)property
{
	static NSSet *strokeProperties = nil;
	
	if (!strokeProperties) {
		strokeProperties = [NSSet setWithObjects:WDStrokeColorProperty, WDStrokeCapProperty, WDStrokeJoinProperty,
							WDStrokeWidthProperty, WDStrokeVisibleProperty, WDStrokeDashPatternProperty,
							WDStartArrowProperty, WDEndArrowProperty, nil];
	}
	
	return [strokeProperties containsObject:property];
}

- (void) setDefaultValue:(id)value forProperty:(NSString *)property
{
	if ((property != nil)&&(value != nil))
	{ mCachedDefaults[property] = value; }

	static NSDictionary *prop2note = nil;
	if (prop2note == nil)
	{
		prop2note = @{
		WDBlendOptionsKey : WDActiveBlendChangedNotification,
		WDShadowOptionsKey : WDActiveShadowChangedNotification,
		WDStrokeOptionsKey : WDActiveStrokeChangedNotification,
		WDFillOptionsKey : WDActiveFillChangedNotification };
	}

	[[NSNotificationCenter defaultCenter]
		postNotificationName:prop2note[property]
		object:self userInfo:nil];
	return;
}

////////////////////////////////////////////////////////////////////////////////

- (id) defaultValueForProperty:(id)key
{
	return [mCachedDefaults valueForKey:key];
}

- (id) activeValueForKey:(id)key
{
	if (self.drawingController.singleSelection)
	{ return [self.drawingController.singleSelection valueForProperty:key]; }
	return [self defaultValueForProperty:key];
}


- (WDFillOptions *) activeFillOptions
{ return [self activeValueForKey:WDFillOptionsKey]; }

- (WDFillOptions *)defaultFillOptions
{ return [self defaultValueForProperty:WDFillOptionsKey]; }

- (WDStrokeOptions *) activeStrokeOptions
{ return [self activeValueForKey:WDStrokeOptionsKey]; }

- (WDStrokeOptions *)defaultStrokeOptions
{ return [self defaultValueForProperty:WDStrokeOptionsKey]; }

- (WDShadowOptions *) activeShadowOptions
{ return [self activeValueForKey:WDShadowOptionsKey]; }

- (WDShadowOptions *)defaultShadowOptions
{ return [self defaultValueForProperty:WDShadowOptionsKey]; }

- (WDBlendOptions *) activeBlendOptions
{ return [self activeValueForKey:WDBlendOptionsKey]; }

- (WDBlendOptions *)defaultBlendOptions
{ return [self defaultValueForProperty:WDBlendOptionsKey]; }



/*
- (id<WDPathPainter>) activeFillStyle
{
	id value = [self defaultValueForProperty:WDFillProperty];
	
	if ([value isEqual:[NSNull null]]) {
		return nil;
	}
	
	return value;
}

- (id<WDPathPainter>) defaultFillStyle
{
	id value = [self defaultValueForProperty:WDFillProperty];
	
	if ([value isEqual:[NSNull null]]) {
		return nil;
	}
	
	return value;
}
*/
@end
