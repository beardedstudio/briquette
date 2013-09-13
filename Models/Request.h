//
//  Request.h
//  briquette
//
//  Created by Dominic Dagradi on 7/17/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface Request : ASIHTTPRequest {
  NSDictionary *responseHash;
}

@property (nonatomic, retain) NSDictionary *responseHash;

-(void)setCredentials:(id)site options:(NSDictionary *)options;

+(Request *)get:(NSString *)url delegate:(id)delegate callback:(NSString *)callback site:(id)site options:(NSDictionary *)options;
+(Request *)post:(NSString *)url content:(NSString *)content delegate:(id)delegate callback:(NSString *)callback site:(id)site options:(NSDictionary *)options;


@end
