//
//  LoopMeIdentityProvider.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 11/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <AdSupport/AdSupport.h>

#import "LoopMeIdentityProvider.h"

#define LOOOPME_UNIQUE_IDENTIFIER_KEY @"com.loopmemedia.identifier"

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
    NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:LOOOPME_UNIQUE_IDENTIFIER_KEY];
    if (!identifier) {
        CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
        NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
        CFRelease(uuidObject);
        
        identifier = [NSString stringWithFormat:@"r_%@", uuidStr];
        [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:LOOOPME_UNIQUE_IDENTIFIER_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return identifier;
}

+ (BOOL)deviceHasAdvertisingIdentifier
{
    return !!NSClassFromString(@"ASIdentifierManager");
}

@end
