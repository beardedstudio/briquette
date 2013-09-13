//
//  CustomParser.m
//  briquette
//
//  Created by Brett Bender on 7/6/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import "CustomParser.h"
#import <YAJL/YAJL.h>

@implementation CustomParser
+ (NSMutableDictionary *)parse:(NSString *)str withError:(NSError **)error {	
  NSMutableDictionary *parsed;
  
  // MAGIC INVISIBLE CHARACTER REMOVE FUCKFUCKFUCK (replacing \u0003 with space. Campfire bug).
  // A regex would work great here if \u0003 is marked as whitespace...no regex in Cocoa though
  str = [str stringByReplacingOccurrencesOfString:@"" withString:@" "];
  
  parsed = [str yajl_JSONWithOptions:YAJLParserOptionsNone error:error];
  if (parsed == nil) {   
    parsed = [NSMutableDictionary dictionary];
  }
  
  return parsed;
}

@end
