//
//  LoopMeServerURLBuilder.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//
#import <AdSupport/AdSupport.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "LoopMeDefinitions.h"
#import "LoopMeIdentityProvider.h"
#import "LoopMeReachability.h"
#import "LoopMeServerURLBuilder.h"
#import "LoopMeTargeting.h"
#import "LoopMeUtility.h"
#import "LoopMeGeoLocationProvider.h"

NSString * const kLoopMeAPIURL = @"http://loopme.me/api/loopme/ads/v3";
NSString * const kLoopMeInterfaceOrientationPortrait = @"p";
NSString * const kLoopMeInterfaceOrientationLandscape = @"l";

@implementation LoopMeServerURLBuilder

#pragma mark - Class Methods

+ (NSURL *)URLWithAppKey:(NSString *)appKey
{
    return [LoopMeServerURLBuilder URLWithAppKey:appKey targeting:nil
                                         baseURL:[NSURL URLWithString:kLoopMeAPIURL]];
}

+ (NSURL *)URLWithAppKey:(NSString *)appKey
               targeting:(LoopMeTargeting *)targeting
{
    return [LoopMeServerURLBuilder URLWithAppKey:appKey targeting:targeting
                                         baseURL:[NSURL URLWithString:kLoopMeAPIURL]];
}

+ (NSURL *)URLWithAppKey:(NSString *)appKey
               targeting:(LoopMeTargeting *)targeting
                 baseURL:(NSURL *)baseURL
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"ak"] = appKey;
    parameters[@"vt"] = [self parameterForUniqueIdentifier];
    parameters[@"av"] = [self parameterForApplicationVersion];
    parameters[@"or"] = [self parameterForOrientation];
    parameters[@"tz"] = [self parameterForTimeZone];
    parameters[@"lng"] = [self parameterForLanguage];
    parameters[@"cn"] = [self parameterForConnectionType];
    parameters[@"dnt"] = [self parameterForDNT];
    parameters[@"sv"] = [NSString stringWithFormat:@"%@", LOOPME_SDK_VERSION];
    parameters[@"mr"] = @"0";

    if (targeting) {
        if (targeting.keywordsParameter)
            parameters[@"keywords"] = targeting.keywordsParameter;
        if (targeting.yearOfBirth)
            parameters[@"yob"] = targeting.yearOfBirthParameter;
        if (targeting.genderParameter)
            parameters[@"gender"] = targeting.genderParameter;
    }
    
    if ([[LoopMeGeoLocationProvider sharedProvider] isLocationUpdateEnabled] && [[LoopMeGeoLocationProvider sharedProvider] isValidLocation:[LoopMeGeoLocationProvider sharedProvider].location]) {
        parameters[@"lat"] = [NSString stringWithFormat:@"%0.4f", (float)[LoopMeGeoLocationProvider sharedProvider].location.coordinate.latitude];
        parameters[@"lon"] = [NSString stringWithFormat:@"%0.4f", (float)[LoopMeGeoLocationProvider sharedProvider].location.coordinate.longitude];
    }
    
    NSString *parametersString = [self buildParameters:parameters];
    NSURL *URL = [NSURL URLWithString:parametersString relativeToURL:baseURL];
    return URL;
}

+ (NSString *)parameterForUniqueIdentifier
{
    return [LoopMeIdentityProvider uniqueIdentifier];
}

+ (NSString *)parameterForLanguage
{
    return [NSLocale preferredLanguages][0];
}

+ (NSString *)parameterForOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return UIInterfaceOrientationIsPortrait(orientation) ?
                    kLoopMeInterfaceOrientationPortrait :
                    kLoopMeInterfaceOrientationLandscape;
}

+ (NSString *)parameterForTimeZone
{
    static NSDateFormatter *formatter;
    @synchronized(self) {
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
        }
    }
    [formatter setDateFormat:@"Z"];
    NSDate *today = [NSDate date];
    return [formatter stringFromDate:today];
}

+ (NSString *)parameterForConnectionType
{
    return [NSString stringWithFormat:@"%lu", (long)[[LoopMeReachability reachabilityForLocalWiFi] connectionType]];
}

+ (NSString *)parameterForApplicationVersion
{
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

+ (NSString *)parameterForDNT
{
    return ([LoopMeIdentityProvider advertisingTrackingEnabled] ? @"0" : @"1");
}

+ (NSString *)buildParameters:(NSMutableDictionary *)parameters
{
    NSMutableString *parametersString = [[NSMutableString alloc] init];
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [parametersString appendFormat:@"%@=%@&", [self escapeString:key], [self escapeString:value]];
    }];
    return  [@"?" stringByAppendingString:[parametersString substringToIndex:[parametersString length]-1]];
}

+ (NSString *)escapeString:(NSString*)string
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                    (CFStringRef)string,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
    return (__bridge_transfer NSString *)urlString;
}

@end
