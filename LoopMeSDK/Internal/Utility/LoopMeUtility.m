//
//  LoopMeUtility.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2012 Ciklum. All rights reserved.
//

#import <AdSupport/AdSupport.h>

#import "LoopMeDefinitions.h"
#import "LoopMeReachability.h"
#import "LoopMeUtility.h"
#import "NSURL+LoopMeAdditions.h"

@implementation LoopMeUtility

+ (NSString *)storeItemIdentifierForURL:(NSURL *)URL
{
    NSString *itemIdentifier = nil;
    if ([URL.host hasSuffix:@"itunes.apple.com"]) {
        NSString *lastPathComponent = [[URL path] lastPathComponent];
        if ([lastPathComponent hasPrefix:@"id"]) {
            itemIdentifier = [lastPathComponent substringFromIndex:2];
        } else {
            itemIdentifier = (URL.lm_toDictionary)[@"id"];
        }
    } else if ([URL.host hasSuffix:@"phobos.apple.com"]) {
        itemIdentifier = (URL.lm_toDictionary)[@"id"];
    }
    
    NSCharacterSet *nonIntegers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if (itemIdentifier && itemIdentifier.length > 0 && [itemIdentifier rangeOfCharacterFromSet:nonIntegers].location == NSNotFound) {
        return itemIdentifier;
    }
    return nil;
}

@end

@implementation NSString (LoopMeAdditions)

- (NSString *)URLEncodedString
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                           (CFStringRef)self,
                                                                           NULL,
                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
                                                                           kCFStringEncodingUTF8));
    return result;
}

@end