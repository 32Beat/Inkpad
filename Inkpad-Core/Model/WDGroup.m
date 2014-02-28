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
	
	[self setElements:[coder decodeObjectForKey:WDGroupElementsKey]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setElements:(NSMutableArray *)elements
{
	if (elements_ != elements)
	{
		elements_ = elements;
		[elements_ makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
		[self size];

		[elements_ makeObjectsPerformSelector:@selector(setGroup:) withObject:self];
		[elements_ makeObjectsPerformSelector:@selector(setLayer:) withObject:self.layer];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) copyPropertiesFrom:(WDGroup *)srcGroup
{
	[super copyPropertiesFrom:srcGroup];
	[self setElements:
	[[NSMutableArray alloc] initWithArray:[srcGroup elements] copyItems:YES]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (CGRect) boundsForTransform:(CGAffineTransform)T
{
	CGRect R = CGRectNull;
	for (WDElement *element in self.elements)
	{
		WDQuad Q = WDQuadApplyTransform(element.frameQuad, T);
		R = CGRectUnion(R, WDQuadGetBounds(Q));
	}

	return R;
}

////////////////////////////////////////////////////////////////////////////////

- (CGSize) size
{
	if ((mSize.width == 0.0) &&
		(mSize.height == 0.0))
	{
		CGRect R = [self frameBounds];
		super.size = R.size;
		super.position = WDCenterOfRect(R);
	}

	return mSize;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSize:(CGSize)dstSize
{
	CGSize srcSize = self.size;
	CGFloat sx = srcSize.width != 0.0 ? dstSize.width / srcSize.width : 1.0;
	CGFloat sy = srcSize.height != 0.0 ? dstSize.height / srcSize.height : 1.0;
	CGFloat scale = MIN(fabs(sx), fabs(sy));

	CGPoint C = self.position;

	for (WDElement *element in self.elements)
	{ [element _applyScale:scale pivot:C]; }

	// Flush cache
	[super setSize:dstSize];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setPosition:(CGPoint)P
{
	CGVector delta =
	{ P.x - self.position.x, P.y - self.position.y };

	for (WDElement *element in self.elements)
	{ [element _applyMove:delta]; }

	[super setPosition:P];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setRotation:(CGFloat)degrees
{
	CGFloat delta = degrees - self.rotation;
	CGPoint C = self.position;

	for (WDElement *element in self.elements)
	{ [element _applyRotation:delta pivot:C]; }

	[super setRotation:degrees];
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
/*
- (NSSet *) transform:(CGAffineTransform)transform
{
	for (WDElement *element in elements_)
	{ [element transform:transform]; }

	return [super transform:transform];
}
*/
////////////////////////////////////////////////////////////////////////////////

- (void) setLayer:(WDLayer *)layer
{
	[super setLayer:layer];    
	[self.elements makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
}    

////////////////////////////////////////////////////////////////////////////////

- (void) renderOutline:(const WDRenderContext *)renderContext
{
	for (WDElement *element in self.elements)
	{ [element renderOutline:renderContext]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderContent:(const WDRenderContext *)renderContext
{
	[self beginTransparencyLayer:renderContext->contextRef];

	for (WDElement *element in self.elements)
	{ [element renderContent:renderContext]; }

	[self endTransparencyLayer:renderContext->contextRef];
}

////////////////////////////////////////////////////////////////////////////////

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	[self beginTransparencyLayer:ctx];

	for (WDElement *element in self.elements)
	{ [element renderInContext:ctx metaData:metaData]; }

	[self endTransparencyLayer:ctx];
}

////////////////////////////////////////////////////////////////////////////////

- (void) outlineInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
	for (WDElement *element in self.elements)
	{ [element outlineInContext:ctx metaData:metaData]; }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

- (CGRect) bounds
{
	CGRect bounds = CGRectNull;

	for (WDElement *element in self.elements)
	{ bounds = CGRectUnion([element bounds], bounds); }

	return bounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeFrameBounds
{
	CGRect bounds = CGRectNull;

	for (WDElement *element in self.elements)
	{ bounds = CGRectUnion([element frameBounds], bounds); }

	return bounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) computeStyleBounds
{
	CGRect bounds = CGRectNull;

	for (WDElement *element in self.elements)
	{ bounds = CGRectUnion([element styleBounds], bounds); }

	return bounds;
}

////////////////////////////////////////////////////////////////////////////////

- (CGRect) shadowBounds
{
	CGRect R = CGRectNull;

	// Combine result bounds of elements
	for (WDElement *element in self.elements)
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



- (BOOL) contentIntersectsRect:(CGRect)rect
{
	for (WDElement *element in [self.elements reverseObjectEnumerator]) {
		if ([element intersectsRect:rect]) {
			return YES;
		}
	}
	
	return NO;
}



- (void) glDrawContentWithTransform:(CGAffineTransform)T
{
	for (WDElement *object in self.elements)
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


@end
