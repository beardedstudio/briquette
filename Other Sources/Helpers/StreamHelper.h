//
//  StreamHelper.h
//  briquette
//
//  Created by Dominic Dagradi on 2/8/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StreamHelper : NSObject {

}

+ (NSURLCredential *)credentialForChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
