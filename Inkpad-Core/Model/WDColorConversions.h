////////////////////////////////////////////////////////////////////////////////
/*
	WDColorConversions.h
	Inkpad

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.

	Project Copyright (c) 2008-2014 Steve Sprang
*/
////////////////////////////////////////////////////////////////////////////////

#import <CoreGraphics/CoreGraphics.h>

////////////////////////////////////////////////////////////////////////////////

void HSVtoRGB(CGFloat h, CGFloat s, CGFloat v, CGFloat *rgb);
void RGBtoHSV(CGFloat r, CGFloat g, CGFloat b, CGFloat *hsv);

void SRGBtoXYZ(CGFloat r, CGFloat g, CGFloat b, CGFloat *xyz);
void XYZtoSRGB(CGFloat X, CGFloat Y, CGFloat Z, CGFloat *rgb);

void XYZtoLAB(CGFloat X, CGFloat Y, CGFloat Z, CGFloat *lab);
void LABtoXYZ(CGFloat L, CGFloat a, CGFloat b, CGFloat *xyz);

void LABtoLCH(CGFloat L, CGFloat a, CGFloat b, CGFloat *lch);
void LCHtoLAB(CGFloat L, CGFloat C, CGFloat H, CGFloat *lab);

////////////////////////////////////////////////////////////////////////////////

