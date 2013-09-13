//
//  NSColor-HexColors.h
//  briquette
//
//  Created by Dominic Dagradi on 3/4/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (HexColors)

+ (NSColor*)colorWithHexColorString:(NSString*)inColorString;

@end
