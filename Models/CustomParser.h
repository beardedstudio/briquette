//
//  CustomParser.h
//  briquette
//
//  Created by Brett Bender on 7/6/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CustomParser : NSObject {

}
+ (NSMutableDictionary*) parse:(NSString *)str withError:(NSError **)error;
@end
