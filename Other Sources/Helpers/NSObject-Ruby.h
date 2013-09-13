//
//  NSObject-Ruby.h
//  briquette
//
//  Created by Dominic Dagradi on 7/21/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (Ruby)
  -(id) performRubySelector:(SEL)selector;
@end
