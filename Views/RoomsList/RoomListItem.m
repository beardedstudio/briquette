//
//  RoomListItem.m
//  briquette
//
//  Created by Dominic Dagradi on 12/24/10.
//  Copyright 2010 Bearded. All rights reserved.
//

#import "RoomListItem.h"


@implementation RoomListItem

+ (RoomListItem *)roomListItem {
  NSNib *nib = nil;
  nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(self) bundle:nil];
    
  NSArray *objects = nil;
  [nib instantiateNibWithOwner:nil topLevelObjects:&objects];
  for(id object in objects) {
    if([object isKindOfClass:self]) {
      return object;
    }
  }
  
  NSAssert1(NO, @"No view of class %@ found.", NSStringFromClass(self));
  return nil;
}


@end
