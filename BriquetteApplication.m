//
//  BriquetteApplication.m
//  briquette
//
//  Created by Dominic Dagradi on 5/26/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <MacRuby/MacRuby.h>
#import "BriquetteApplication.h"
#import "NSObject-Ruby.h"

@implementation BriquetteApplication

- (void) sendEvent:(NSEvent *)event {
  if ([event type] == NSKeyDown && [[[self keyWindow] title] caseInsensitiveCompare:@"Search Transcripts"] != NSOrderedSame) {
    
    unsigned flags = [event modifierFlags];
    if (flags & NSCommandKeyMask) {
      NSString *characters = [event characters];
      unichar character = [characters characterAtIndex:0];

      if(((flags & NSControlKeyMask) && (character == NSDownArrowFunctionKey || character == NSRightArrowFunctionKey)) || character == ']') {
        [(NSObject *)[[NSApplication sharedApplication] delegate] performRubySelector:@selector(selectNextRoom)];
        return;
      } 
      if(((flags & NSControlKeyMask) && (character == NSUpArrowFunctionKey || character == NSLeftArrowFunctionKey)) || character == '[') {
        [(NSObject *)[[NSApplication sharedApplication] delegate] performRubySelector:@selector(selectPreviousRoom)];
        return;
      }       
    }
  }
  [super sendEvent:event];
}

@end
