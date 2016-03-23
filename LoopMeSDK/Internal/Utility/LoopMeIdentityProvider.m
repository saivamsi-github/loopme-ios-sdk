//
//  LoopMeIdentityProvider.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 11/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <AdSupport/AdSupport.h>

#import "LoopMeIdentityProvider.h"
#import "LoopMeKeychain.h"
#import "LoopMeLogging.h"

static NSString * const kLoopMeKeychainServiceName = @"LoopMe";
static NSString * const kLoopMeKeychainAccountName = @"loopme";

@implementation LoopMeIdentityProvider

#pragma mark - Class Methods

+ (NSString *)uniqueIdentifier {
    return ([self advertisingTrackingEnabled]) ?
    [self advertisingTrackingDeviceIdentifier] :
    [self loopMeUniqueIdentifier];
}

+ (NSString *)advertisingTrackingDeviceIdentifier
{
    if ([LoopMeIdentityProvider deviceHasAdvertisingIdentifier]) {
        NSString *identifier = nil;
        identifier = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
        return [identifier uppercaseString];
    }
    
    return nil;
}

+ (BOOL)advertisingTrackingEnabled
{
    BOOL enabled = YES;

    if ([self deviceHasAdvertisingIdentifier]) {
        enabled = [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
    }

    return enabled;
}

+ (NSString *)loopMeUniqueIdentifier
{
    NSError *error = nil;
    NSString *identifier = [LoopMeKeychain passwordForService:kLoopMeKeychainServiceName account:kLoopMeKeychainAccountName error:&error];
    
    if (!identifier || [error code] == LoopMeKeychainErrorNotFound) {
        identifier = [self createUUID];
        [LoopMeKeychain setPassword:identifier forService:kLoopMeKeychainServiceName account:kLoopMeKeychainAccountName error:&error];
        LoopMeLogDebug(@"%@", error);
    }
    
    return identifier;
}

+ (NSString *)createUUID {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    
    return [NSString stringWithFormat:@"r_%@", uuidStr];
}

+ (BOOL)deviceHasAdvertisingIdentifier
{
    return !!NSClassFromString(@"ASIdentifierManager");
}

@end
