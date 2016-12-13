//
//  LoopMeIdentityProvider.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 11/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <AdSupport/AdSupport.h>

#import "LoopMeIdentityProvider.h"
#import "LoopMeLogging.h"

@implementation LoopMeIdentityProvider

#pragma mark - Class Methods

+ (NSString *)advertisingTrackingDeviceIdentifier
{
    NSString *identifier = nil;
    identifier = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
    if (![ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled) {
        identifier = @"00000000-0000-0000-0000-000000000000";
    }
    return [identifier uppercaseString];
}

+ (BOOL)advertisingTrackingEnabled
{
    BOOL enabled = YES;

    if ([self deviceHasAdvertisingIdentifier]) {
        enabled = [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
    }

    return enabled;
}

+ (BOOL)deviceHasAdvertisingIdentifier
{
    return !!NSClassFromString(@"ASIdentifierManager");
}

@end
