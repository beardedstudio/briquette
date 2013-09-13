//
//  NetworkNotifier.h
//  briquette
//
//  Created by Dominic Dagradi on 5/6/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NetworkNotifier : NSObject {
  id delegate;
}

@property (nonatomic, retain) id delegate;

@end
