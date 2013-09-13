//
//  StreamHelper.m
//  briquette
//
//  Created by Dominic Dagradi on 2/8/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import "StreamHelper.h"


@implementation StreamHelper

+ (NSURLCredential *)credentialForChallenge:(NSURLAuthenticationChallenge *)challenge {
  return [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
}

@end
