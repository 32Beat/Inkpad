//
//  WDShapeTool.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//


#import "WDAbstractPath.h"
#import "WDBezierNode.h"
#import "WDCanvas.h"
#import "WDDrawing.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPath.h"
#import "WDPropertyManager.h"
#import "WDShapeTool.h"
#import "WDUtilities.h"

#import "WDShape.h"
#import "WDRectangleShape.h"
#import "WDOvalShape.h"
#import "WDStarShape.h"
#import "WDPieShape.h"
#import "WDLeafShape.h"
#import "WDHeartShape.h"
#import "WDDiamondShape.h"
#import "WDSpadesShape.h"
#import "WDClubsShape.h"

NSString *WDShapeToolStarInnerRadiusRatio = @"WDShapeToolStarInnerRadiusRatio";
NSString *WDShapeToolStarPointCount = @"WDShapeToolStarPointCount";
NSString *WDShapeToolPolygonSideCount = @"WDShapeToolPolygonSideCount";
NSString *WDShapeToolRectCornerRadius = @"WDShapeToolRectCornerRadius";
NSString *WDDefaultShapeTool = @"WDDefaultShapeTool";
NSString *WDShapeToolSpiralDecay = @"WDShapeToolSpiralDecay";

@implementation WDShapeTool

@synthesize shapeMode = shapeMode_;

- (NSString *) iconName
{
    NSArray *imageNames = @[
	@"rect.png",
	@"oval.png",
	@"star.png",
	@"polygon.png",
	@"spiral.png",
	@"line.png",
	@"oval.png",
	@"line.png",
	@"oval.png",
	@"line.png",
	@"oval.png",
	@"line.png"
	];
    
    return imageNames[shapeMode_];
}

- (id) init
{
    self = [super init];

    if (!self) {
        return nil;
    }
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	starInnerRadiusRatio_ = [defaults floatForKey:WDShapeToolStarInnerRadiusRatio];
	starInnerRadiusRatio_ = WDClamp(0.05, 2.0, starInnerRadiusRatio_);

	numStarPoints_ = (int) [defaults integerForKey:WDShapeToolStarPointCount];
	numPolygonPoints_ = (int) [defaults integerForKey:WDShapeToolPolygonSideCount];
	rectCornerRadius_ = [defaults floatForKey:WDShapeToolRectCornerRadius];
	decay_ = [defaults floatForKey:WDShapeToolSpiralDecay];

    return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (id) tools
{
	return @[
	[WDShapeTool rectangleTool],
	[WDShapeTool ovalTool],
	[WDShapeTool starTool],
	[WDShapeTool polygonTool],
	[WDShapeTool spiralTool],
	[WDShapeTool lineTool],
	[WDShapeTool pacmanTool],
	[WDShapeTool leafTool],
	[WDShapeTool heartTool],
	[WDShapeTool diamondTool],
	[WDShapeTool spadesTool],
	[WDShapeTool clubsTool]
	];
}

////////////////////////////////////////////////////////////////////////////////

+ (id) rectangleTool
{ return [self shapeToolWithMode:WDShapeModeRectangle]; }

+ (id) ovalTool
{ return [self shapeToolWithMode:WDShapeModeOval]; }

+ (id) starTool
{ return [self shapeToolWithMode:WDShapeModeStar]; }

+ (id) polygonTool
{ return [self shapeToolWithMode:WDShapeModePolygon]; }

+ (id) lineTool
{ return [self shapeToolWithMode:WDShapeModeLine]; }

+ (id) spiralTool
{ return [self shapeToolWithMode:WDShapeModeSpiral]; }

+ (id) leafTool
{ return [self shapeToolWithMode:WDShapeModeLeaf]; }

+ (id) heartTool
{ return [self shapeToolWithMode:WDShapeModeHeart]; }

+ (id) diamondTool
{ return [self shapeToolWithMode:WDShapeModeDiamond]; }

+ (id) spadesTool
{ return [self shapeToolWithMode:WDShapeModeSpades]; }

+ (id) clubsTool
{ return [self shapeToolWithMode:WDShapeModeClubs]; }

+ (id) pacmanTool
{ return [self shapeToolWithMode:WDShapeModePie]; }

////////////////////////////////////////////////////////////////////////////////

+ (id) shapeToolWithMode:(WDShapeMode)mode
{ return [[self alloc] initWithMode:mode]; }

- (id) initWithMode:(WDShapeMode)mode
{
	self = [super init];
	if (self != nil)
	{
		shapeMode_ = mode;

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		starInnerRadiusRatio_ = [defaults floatForKey:WDShapeToolStarInnerRadiusRatio];
		starInnerRadiusRatio_ = WDClamp(0.05, 2.0, starInnerRadiusRatio_);

		numStarPoints_ = (int) [defaults integerForKey:WDShapeToolStarPointCount];
		numPolygonPoints_ = (int) [defaults integerForKey:WDShapeToolPolygonSideCount];
		rectCornerRadius_ = [defaults floatForKey:WDShapeToolRectCornerRadius];
		decay_ = [defaults floatForKey:WDShapeToolSpiralDecay];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////


- (BOOL) isDefaultForKind
{
    NSNumber *defaultShape = [[NSUserDefaults standardUserDefaults] valueForKey:WDDefaultShapeTool];
    return (shapeMode_ == [defaultShape intValue]) ? YES : NO;
}

- (void) activated
{
    [[NSUserDefaults standardUserDefaults] setValue:@(shapeMode_) forKey:WDDefaultShapeTool];
}

- (WDPath *) pathWithPoint:(CGPoint)pt constrain:(BOOL)constrain
{
	CGPoint initialPoint = self.initialEvent.snappedLocation;

	if (shapeMode_ == WDShapeModeRectangle)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDRectangleShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeOval)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDOvalShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeLeaf)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDLeafShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeHeart)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDHeartShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeDiamond)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDDiamondShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeSpades)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDSpadesShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeClubs)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDClubsShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeStar)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDStarShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModePie)
	{
		CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
		return [WDPieShape shapeWithFrame:rect];
	}
	else
	if (shapeMode_ == WDShapeModeLine)
	{
		if (constrain) {
			CGPoint delta = WDConstrainPoint(WDSubtractPoints(pt, initialPoint));
			pt = WDAddPoints(initialPoint, delta);
		}
		
		return [WDPath pathWithStart:initialPoint end:pt];
	}
	else
	if (shapeMode_== WDShapeModePolygon)
	{
		NSMutableArray  *nodes = [NSMutableArray array];
		CGPoint         delta = WDSubtractPoints(pt, initialPoint);
		float           angle, x, y, theta = M_PI * 2 / numPolygonPoints_;
		float           radius = WDDistance(initialPoint, pt);
		float           offsetAngle = atan2(delta.y, delta.x);
		
		for(int i = 0; i < numPolygonPoints_; i++) {
			angle = theta * i + offsetAngle;
			
			x = cos(angle) * radius;
			y = sin(angle) * radius;
			
			[nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:CGPointMake(x + initialPoint.x, y + initialPoint.y)]];
		}
		
		WDPath *path = [[WDPath alloc] init];
		path.nodes = nodes;
		path.closed = YES;
		return path;
	}
	else
	if (shapeMode_ == WDShapeModeSpiral) {
		float       radius = WDDistance(pt, initialPoint);
		CGPoint     delta = WDSubtractPoints(pt, initialPoint);
		float       offsetAngle = atan2(delta.y, delta.x) + M_PI;
		int         segments = 20;
		float       b = 1.0f - (decay_ / 100.f);
		float       a = radius / pow(M_E, b * segments * M_PI_4);
		
		NSMutableArray  *nodes = [NSMutableArray array];
		
		for (int segment = 0; segment <= segments; segment++) {
			float t = segment * M_PI_4;
			float f = a * pow(M_E, b * t);
			float x = f * cos(t);
			float y = f * sin(t);
			
			CGPoint P3 = CGPointMake(x, y);
			
			// derivative
			float t0 = t - M_PI_4;
			float deltaT = (t - t0) / 3;
			
			float xPrime = a*b*pow(M_E,b*t)*cos(t) - a*pow(M_E,b*t)*sin(t);
			float yPrime = a*pow(M_E,b*t)*cos(t) + a*b*pow(M_E,b*t)*sin(t);
			
			CGPoint P2 = WDSubtractPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
			CGPoint P1 = WDAddPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
			
			[nodes addObject:[WDBezierNode
			bezierNodeWithAnchorPoint:P3 outPoint:P1 inPoint:P2]];
		}
		
		WDPath *path = [[WDPath alloc] init];
		path.nodes = nodes;
		
		CGAffineTransform transform = CGAffineTransformMakeTranslation(initialPoint.x, initialPoint.y);
		transform = CGAffineTransformRotate(transform, offsetAngle);
		
		[path transform:transform];
		return path;
	}

	return nil;
}

- (BOOL) createsObject
{
    return YES;
}

- (BOOL) constrain
{
    return ((self.flags & WDToolShiftKey) || (self.flags & WDToolSecondaryTouch)) ? YES : NO;
}

- (void)moveWithEvent:(WDEvent *)theEvent inCanvas:(WDCanvas *)canvas
{
    if (!self.moved) {
        [canvas.drawingController deselectAllObjects];
    }
    
    WDPath  *temp = [self pathWithPoint:theEvent.snappedLocation constrain:[self constrain]];
    
	canvas.shapeUnderConstruction = temp;

}

- (void)endWithEvent:(WDEvent *)theEvent inCanvas:(WDCanvas *)canvas
{    
	if (self.moved)
	{
		if (!CGPointEqualToPoint(self.initialEvent.snappedLocation, theEvent.snappedLocation))
		{
			WDStylable *item =
			[self pathWithPoint:theEvent.snappedLocation constrain:[self constrain]];

			WDPropertyManager *pm = canvas.drawingController.propertyManager;
			[item setBlendOptions:[pm activeBlendOptions]];
			[item setShadowOptions:[pm activeShadowOptions]];
			[item setStrokeOptions:[pm activeStrokeOptions]];

			[canvas.drawing addObject:item];
			[canvas.drawingController selectObject:item];
		}
		
		canvas.shapeUnderConstruction = nil;
	}
}

- (void) flagsChangedInCanvas:(WDCanvas *)canvas
{
    WDPath  *temp = [self pathWithPoint:self.previousEvent.snappedLocation constrain:[self constrain]];
    canvas.shapeUnderConstruction = temp;
}

#if TARGET_OS_IPHONE
- (void) updateOptionsSettings
{
    if (shapeMode_ == WDShapeModeRectangle) {
        int displayRadius = round(rectCornerRadius_);
        optionsValue_.text = [NSString stringWithFormat:@"%d pt", displayRadius];
        optionsSlider_.value = rectCornerRadius_;
    } else if (shapeMode_ == WDShapeModePolygon) {
        optionsValue_.text = [NSString stringWithFormat:@"%d", numPolygonPoints_];
        optionsSlider_.value = numPolygonPoints_;
    } else if (shapeMode_ == WDShapeModeStar) {
        optionsValue_.text = [NSString stringWithFormat:@"%d", numStarPoints_];
        optionsSlider_.value = numStarPoints_;
    } else if (shapeMode_ == WDShapeModeSpiral) {
        optionsValue_.text = [NSString stringWithFormat:@"%d%%", decay_];
        optionsSlider_.value = decay_;
    }
}

- (IBAction) takeFinalSliderValueFrom:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (shapeMode_ == WDShapeModeRectangle) {
        rectCornerRadius_ = optionsSlider_.value;
        [defaults setFloat:rectCornerRadius_ forKey:WDShapeToolRectCornerRadius];
    } else if (shapeMode_ == WDShapeModePolygon) {
        numPolygonPoints_ = optionsSlider_.value;
        [defaults setInteger:numPolygonPoints_ forKey:WDShapeToolPolygonSideCount];
    } else if (shapeMode_ == WDShapeModeStar) {
        numStarPoints_ = optionsSlider_.value;
        [defaults setInteger:numStarPoints_ forKey:WDShapeToolStarPointCount];
    } else if (shapeMode_ == WDShapeModeSpiral) {
        decay_ = optionsSlider_.value;
        [defaults setInteger:decay_ forKey:WDShapeToolSpiralDecay];
    }
    
    [self updateOptionsSettings];
}

- (IBAction) takeSliderValueFrom:(id)sender
{
    if (shapeMode_ == WDShapeModeRectangle) {
        rectCornerRadius_ = optionsSlider_.value;
    } else if (shapeMode_ == WDShapeModePolygon) {
        numPolygonPoints_ = optionsSlider_.value;
    } else if (shapeMode_ == WDShapeModeStar) {
        numStarPoints_ = optionsSlider_.value;
    } else if (shapeMode_ == WDShapeModeSpiral) {
        decay_ = optionsSlider_.value;
    }
    
    [self updateOptionsSettings];
}

- (IBAction)increment:(id)sender
{
    optionsSlider_.value = optionsSlider_.value + 1;
    [optionsSlider_ sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)decrement:(id)sender
{
    optionsSlider_.value = optionsSlider_.value - 1;
    [optionsSlider_ sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (UIView *) optionsView
{
	// Editing only available after placement
	return nil;

    if (shapeMode_ == WDShapeModeOval || shapeMode_ == WDShapeModeLine) {
        // no options for these guys
        return nil;
    }
    
    if (!optionsView_) {
        [[NSBundle mainBundle] loadNibNamed:@"ShapeOptions" owner:self options:nil];
        [self configureOptionsView:optionsView_];
        
        if (shapeMode_ == WDShapeModeRectangle) {
            optionsSlider_.minimumValue = 0;
            optionsSlider_.maximumValue = 100;
        } else if (shapeMode_ == WDShapeModePolygon) {
            optionsSlider_.minimumValue = 3;
            optionsSlider_.maximumValue = 20;
        } else if  (shapeMode_ == WDShapeModeStar) {
            optionsSlider_.minimumValue = 3;
            optionsSlider_.maximumValue = 50;
        } else if  (shapeMode_ == WDShapeModeSpiral) {
            optionsSlider_.minimumValue = 10;
            optionsSlider_.maximumValue = 99;
        }
        optionsSlider_.exclusiveTouch = YES;
        
        if (shapeMode_ == WDShapeModeRectangle) {
            optionsTitle_.text = NSLocalizedString(@"Corner Radius", @"Corner Radius");
        } else if (shapeMode_ == WDShapeModePolygon) {
            optionsTitle_.text = NSLocalizedString(@"Number of Sides", @"Number of Sides");
        } else if (shapeMode_ == WDShapeModeStar) {
            optionsTitle_.text = NSLocalizedString(@"Number of Points", @"Number of Points");
        } else if (shapeMode_ == WDShapeModeSpiral) {
            optionsTitle_.text = NSLocalizedString(@"Decay", @"Decay");
        }
    }
    
    [self updateOptionsSettings];
    
    return optionsView_;
}

#endif

@end
