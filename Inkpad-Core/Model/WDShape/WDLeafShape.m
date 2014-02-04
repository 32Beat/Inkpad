////////////////////////////////////////////////////////////////////////////////
/*
	WDLeafShape.m
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2009-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import "WDLeafShape.h"
#import "WDUtilities.h"

////////////////////////////////////////////////////////////////////////////////
@implementation WDLeafShape
////////////////////////////////////////////////////////////////////////////////
/*
	Define shape in a 2x2 square centered around (0, 0)
	using normal math coordinates:
	(-1, -1) is bottom-left,
	(+1, +1) is top-right
	
	Write coordinate triplets for bezier nodes: 
	coordinate 1 is anchorpoint
	coordinate 2 is out vector relative to anchorpoint
	coordinate 3 is in vector relative to anchorpoint

	Use character "c" for circlefactor
*/

+ (NSString *) normalizedShape
{
	return @"{ \
	{  0.00, +1.00}, { 0,  0}, { 0,  0}, \
	{ -1.00,  0.00}, { 0, -c}, { 0, +c}, \
	{  0.00, -1.00}, { 0,  0}, { 0,  0}, \
	{ +1.00,  0.00}, { 0, +c}, { 0, -c}}";
}

+ (const CGPoint *) normalizedShape:(int *)count
{
	static CGPoint *P = nil;
	static long N = 0;

	if (P == nil)
	{
		NSString *str = [self normalizedShape];
		if (str != nil)
		{
			str = [str stringByReplacingOccurrencesOfString:@"c" withString:@"0.551915024494"];
			str = [str stringByReplacingOccurrencesOfString:@"{" withString:@""];
			str = [str stringByReplacingOccurrencesOfString:@"}" withString:@""];

			id data = [str componentsSeparatedByString:@","];

			N = [data count]/2;
			P = malloc(N * sizeof(CGPoint));
			if (P != nil)
			{
				for (int n=0; n!=N; n++)
				{
					P[n].x = [[data objectAtIndex:2*n+0] floatValue];
					P[n].y = [[data objectAtIndex:2*n+1] floatValue];
				}
			}
		}
	}

	*count = N/3;
	return P;
}

+ (id) bezierNodesWithRect:(CGRect)R
{
/*
	static const CGFloat c = kWDShapeCircleFactor;
	static const CGPoint srcShape[] = {
	{ 0.00,+1.00}, { 0,  0}, { 0, 0},
	{-1.00, 0.00}, { 0, -c}, { 0,+c},
	{ 0.00,-1.00}, { 0,  0}, { 0, 0},
	{+1.00, 0.00}, { 0, +c}, { 0,-c}};
*/
	int count = 0;
	const CGPoint *P = [self normalizedShape:&count];
	return [self bezierNodesWithShapeInRect:R
	normalizedPoints:P count:count];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////


