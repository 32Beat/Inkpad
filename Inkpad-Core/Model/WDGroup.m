////////////////////////////////////////////////////////////////////////////////
/*
	WDGroup.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDGroup.h"
#import "WDShadow.h"
#import "WDPickResult.h"

NSString *const WDGroupElementsKey = @"WDGroupElements";

////////////////////////////////////////////////////////////////////////////////
@implementation WDGroup
////////////////////////////////////////////////////////////////////////////////

@synthesize elements = elements_;

////////////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:elements_ forKey:WDGroupElementsKey];
}

////////////////////////////////////////////////////////////////////////////////

- (void)decodeWithCoder:(NSCoder *)coder
{
	[super decodeWithCoder:coder];
	
	elements_ = [coder decodeObjectForKey:WDGroupElementsKey];

	[elements_ makeObjectsPerformSelector:@selector(setOwner:) withObject:self];

	// have to do this since elements were not properly setting their groups prior to v1.3
	[elements_ makeObjectsPerformSelector:@selector(setGroup:) withObject:self];
}

////////////////////////////////////////////////////////////////////////////////

- (void) tossCachedColorAdjustmentData
{
	[super tossCachedColorAdjustmentData];
	[self.elements makeObjectsPerformSelector:@selector(tossCachedColorAdjustmentData)];
}

- (void) restoreCachedColorAdjustmentData
{
	[super restoreCachedColorAdjustmentData];
	[self.elements makeObjectsPerformSelector:@selector(restoreCachedColorAdjustmentData)];
}

- (void) registerUndoWithCachedColorAdjustmentData
{
	[super registerUndoWithCachedColorAdjustmentData];
	[self.elements makeObjectsPerformSelector:@selector(registerUndoWithCachedColorAdjustmentData)];
}

- (BOOL) canAdjustColor
{
	for (WDElement *element in elements_) {
		if ([element canAdjustColor]) {
			return YES;
		}
	}
	
	return [super canAdjustColor];
}

- (void) adjustColor:(WDColor * (^)(WDColor *color))adjustment scope:(WDColorAdjustmentScope)scope
{
	for (WDElement *element in self.elements) {
		[element adjustColor:adjustment scope:scope];
	}
}

- (NSSet *) transform:(CGAffineTransform)transform
{
	for (WDElement *element in elements_)
	{ [element transform:transform]; }

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setElements:(NSMutableArray *)elements
{
	elements_ = elements;
	
	[elements_ makeObjectsPerformSelector:@selector(setOwner:) withObject:self];

	[elements_ makeObjectsPerformSelector:@selector(setGroup:) withObject:self];
	[elements_ makeObjectsPerformSelector:@selector(setLayer:) withObject:self.layer];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setLayer:(WDLayer *)layer
{
	[super setLayer:layer];    
	[elements_ makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
}    

////////////////////////////////////////////////////////////////////////////////

- (void) renderOutline:(const WDRenderContext *)renderContext
{
	for (WDElement *element in elements_)
	{ [element renderOutline:renderContext]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderContent:(const WDRenderContext *)renderContext
{
	[self beginTransparencyLayer:renderContext->contextRef];

	for (WDElement *element in elements_)
	{ [element renderContent:renderContext]; }

	[self endTransparencyLayer:renderContext->contextRef];
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	[self beginTransparencyLayer:ctx];

	for (WDElement *element in elements_)
	{ [element renderInContext:ctx metaData:metaData]; }

	[self endTransparencyLayer:ctx];
}

////////////////////////////////////////////////////////////////////////////////

- (void) outlineInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	for (WDElement *element in elements_)
	{ [element outlineInContext:ctx metaData:metaData]; }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{
	CGRect bounds = CGRectNull;

	for (WDElement *element in elements_)
	{ bounds = CGRectUnion([element bounds], bounds); }

	return bounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeStyleBounds
{
	CGRect bounds = CGRectNull;

	for (WDElement *element in elements_)
	{ bounds = CGRectUnion([element styleBounds], bounds); }

	return bounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) shadowBounds
{
	CGRect R = CGRectNull;

	// Combine result bounds of elements
	for (WDElement *element in elements_)
	{ R = CGRectUnion([element styleBounds], R); }

	// Add expansion for shadow
	if (self.shadow != nil)
	{ R = [self.shadow expandRenderArea:R]; }

	return R;
}

////////////////////////////////////////////////////////////////////////////////
/*
- (CGRect) renderBounds
{
	CGRect R = CGRectNull;

	// Combine result bounds of elements
	for (WDElement *element in elements_)
	{ R = CGRectUnion([element renderBounds], R); }

	return [self expandRenderArea:R];
}
*/
////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////



- (BOOL) intersectsRect:(CGRect)rect
{
	for (WDElement *element in [elements_ reverseObjectEnumerator]) {
		if ([element intersectsRect:rect]) {
			return YES;
		}
	}
	
	return NO;
}



- (void) glDrawContentWithTransform:(CGAffineTransform)T
{
	for (WDElement *object in elements_)
	{ [object glDrawContentWithTransform:T]; }
}

////////////////////////////////////////////////////////////////////////////////

// OpenGL-based selection rendering

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
	for (WDElement *element in elements_) {
		[element drawOpenGLZoomOutlineWithViewTransform:viewTransform visibleRect:visibleRect];
	}
}

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
	for (WDElement *element in elements_) {
		[element drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];
	}
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
	for (WDElement *element in elements_) {
		[element drawOpenGLAnchorsWithViewTransform:viewTransform];
	}
}

- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform
{
	for (WDElement *element in elements_) {
		[element drawOpenGLAnchorsWithViewTransform:transform];
	}
}

- (WDPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
	flags = flags | kWDSnapEdges;
	
	for (WDElement *element in [elements_ reverseObjectEnumerator]) {
		WDPickResult *result = [element hitResultForPoint:pt viewScale:viewScale snapFlags:flags];
		
		if (result.type != kWDEther) {
			if (!(flags & kWDSnapSubelement)) {
				result.element = self;
			}
			return result;
		}
	}
	
	return [WDPickResult pickResult];
}

- (WDPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags
{
	if (flags & kWDSnapSubelement) {
		for (WDElement *element in [elements_ reverseObjectEnumerator]) {
			WDPickResult *result = [element snappedPoint:pt viewScale:viewScale snapFlags:flags];
			
			if (result.type != kWDEther) {
				return result;
			}
		}
	}
	
	return [WDPickResult pickResult];
}

- (void) addElementsToArray:(NSMutableArray *)array
{
	[super addElementsToArray:array];
	[elements_ makeObjectsPerformSelector:@selector(addElementsToArray:) withObject:array];
}

- (void) addBlendablesToArray:(NSMutableArray *)array
{
	[elements_ makeObjectsPerformSelector:@selector(addBlendablesToArray:) withObject:array];
}

- (NSSet *) inspectableProperties
{
	NSMutableSet *properties = [NSMutableSet set];
	
	// we can inspect anything one of our sub-elements can inspect
	for (WDElement *element in elements_) {
		[properties unionSet:element.inspectableProperties];
	}
	
	return properties;
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager
{
	if ([[super inspectableProperties] containsObject:property]) {
		[super setValue:value forProperty:property propertyManager:propertyManager]; 
	} else {
		for (WDElement *element in elements_) {
			[element setValue:value forProperty:property propertyManager:propertyManager];
		}
	}
}

- (id) valueForProperty:(NSString *)property
{
	id value = nil;
	
	if ([[super inspectableProperties] containsObject:property]) {
		return [super valueForProperty:property]; 
	}
	
	// return the value for the top most object that can inspect it
	for (WDElement *element in [elements_ reverseObjectEnumerator]) {
		value = [element valueForProperty:property];
		if (value) {
			break;
		}
	}
	
	return value;
}

- (WDXMLElement *) SVGElement
{
	WDXMLElement *group = [WDXMLElement elementWithName:@"g"];
	[self addSVGOpacityAndShadowAttributes:group];
	
	for (WDElement *element in elements_) {
		[group addChild:[element SVGElement]];
	}
	
	return group;
}

- (id) copyWithZone:(NSZone *)zone
{
	WDGroup *group = [super copyWithZone:zone];
	
	group->elements_ = [[NSMutableArray alloc] initWithArray:elements_ copyItems:YES];
	[group->elements_ makeObjectsPerformSelector:@selector(setGroup:) withObject:group];
	
	return group;
}

@end
