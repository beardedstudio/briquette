//
//  Request.m
//  briquette
//
//  Created by Dominic Dagradi on 7/17/11.
//  Copyright 2011 Bearded. All rights reserved.
//

#import "Request.h"
#import "NSObject-Ruby.h"
#import "CustomParser.h"

@implementation Request

@synthesize responseHash;

- (id)initWithURL:(NSURL *)_url {
  responseHash = [NSDictionary dictionary];
  
  self = [super initWithURL:_url];
  return self;
}

- (void)startSynchronous {
  self.shouldAttemptPersistentConnection = false;
  [super startSynchronous];
}

- (void)async:(id)sender selector:(NSString *)selector {
  self.shouldAttemptPersistentConnection = false;
  self.delegate = sender;
  self.didFinishSelector = NSSelectorFromString(selector);
  self.didFailSelector = NSSelectorFromString(selector);
  [self startAsynchronous];
}

- (void)handleStreamComplete {
  NSString *string = [self responseString];
  if (string == nil || [string isEqualToString:@""]) {
    if (responseStatusCode != 200 && responseStatusCode != 201) {
      NSLog(@"Response string was empty with error %d: %@", responseStatusCode, self.url.absoluteString);
    }
  } else {
    NSError *error = nil;
    self.responseHash = [CustomParser parse:string withError:&error];
    if (self.responseHash == nil) {
      self.responseHash = [NSDictionary dictionary];
    }
  }  

  [super handleStreamComplete];
}

-(void)setCredentials:(id)site options:(NSDictionary *)options {
  NSString *_username = @"";
  NSString *_password = @"";
  
  if (site != nil) {
    _username = [site performRubySelector:@selector(token)];
    _password = @"x";
  } else {
    if ([options valueForKey:@"username"]) {
      _username = [options valueForKey:@"username"];
    }
    if ([options valueForKey:@"password"]) {
      _password = [options valueForKey:@"password"];      
    }
  } 

  [self addBasicAuthenticationHeaderWithUsername:_username andPassword:_password];
}

+(Request *)get:(NSString *)urlString delegate:(id)delegate callback:(NSString *)callback site:(id)site options:(NSDictionary *)options {

  NSURL *url;
  if (site == nil) {
    url = [NSURL URLWithString:urlString];
  } else {
    NSString *baseURL = [site performRubySelector:@selector(baseURL)];
    url = [NSURL URLWithString:[baseURL stringByAppendingString:urlString]];
  }
    
  Request *request = [[Request alloc] initWithURL:url];
  [request addRequestHeader:@"Content-Type" value:@"application/json"];
  [request setCredentials:site options:options];
  
  if (delegate != nil) {
    [request async:delegate selector:callback];
  } else {
    [request startSynchronous];
  }
  
  return request;  
}

+(Request *)post:(NSString *)urlString content:(NSString *)content delegate:(id)delegate callback:(NSString *)callback site:(id)site options:(NSDictionary *)options {
  
  NSURL *url;
  if (site == nil) {
    url = [NSURL URLWithString:urlString];
  } else {
    NSString *baseURL = [site performRubySelector:@selector(baseURL)];
    url = [NSURL URLWithString:[baseURL stringByAppendingString:urlString]];
  }
  
  Request *request = [[Request alloc] initWithURL:url];
  [request addRequestHeader:@"Content-Type" value:@"application/json"];
  [request setCredentials:site options:options];

  [request setRequestMethod:@"POST"];
  if ([options valueForKey:@"method"] != nil) {
    [request setRequestMethod:[options valueForKey:@"method"]];
  }
  
  [request appendPostData:[content dataUsingEncoding:NSUTF8StringEncoding]];
  
  if (delegate != nil) {
    [request async:delegate selector:callback];
  } else {
    [request startSynchronous];
  }
  
  return request;  
}

@end
