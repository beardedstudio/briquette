//
//  main.m
//  briquette
//
//  Created by Dominic Dagradi on 10/23/10.
//  Copyright Bearded 2010. All rights reserved.
//

#import <MacRuby/MacRuby.h>
#include "../External/validatereceipt.h"

const NSString * global_bundleVersion = @"1.3.1";
const NSString * global_bundleIdentifier = @"com.bearded.briquette";

int main(int argc, char *argv[])
{
  NSString *pathToReceipt;
  
  #ifdef USE_SAMPLE_RECEIPT
    pathToReceipt = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"receipt"];
  #else
    pathToReceipt = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
  #endif
//  if(!validateReceiptAtPath(pathToReceipt)){
//    exit(173);
//  }
  
  return macruby_main("rb_main.rb", argc, argv);
}
