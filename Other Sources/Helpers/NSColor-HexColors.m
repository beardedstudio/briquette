//
//  NSColor-HexColors.m
//  briquette
//
//  Created by Dominic Dagradi on 3/4/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import "NSColor-HexColors.h"


@implementation NSColor(HexColors)

+ (NSColor*)colorWithHexColorString:(NSString*)inColorString
{
	NSColor* result    = nil;
	unsigned colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
  
	if (nil != inColorString)
	{
		NSScanner* scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode]; // ignore error
	}
	redByte   = (unsigned char)(colorCode >> 16);
	greenByte = (unsigned char)(colorCode >> 8);
	blueByte  = (unsigned char)(colorCode);     // masks off high bits
    
	result = [NSColor
            colorWithCalibratedRed:(CGFloat)(redByte/255.05)
            green:(CGFloat)(greenByte/255.0)
            blue:(CGFloat)(blueByte/255.0)
            alpha:1.0];
	return result;
}

@end
