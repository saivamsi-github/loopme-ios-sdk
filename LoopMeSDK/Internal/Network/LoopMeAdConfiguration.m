//
//  LoopMeAdConfiguration.m
//  LoopMe
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.

#import "LoopMeGlobalSettings.h"
#import "LoopMeAdConfiguration.h"
#import "LoopMeLogging.h"
#import "LoopMeGlobalSettings.h"
#import "NSString+Encryption.h"

const int kLoopMeExpireTimeIntervalMinimum = 600;

// Events
const struct LoopMeTrackerNameStruct LoopMeTrackerName = {
    .moat = @"moat"
};

@interface LoopMeAdConfiguration ()

@property (nonatomic) NSArray *measurePartners;

@end

@implementation LoopMeAdConfiguration

#pragma mark - Life Cycle

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:kNilOptions
                                                                             error:&error];
        if (error) {
            LoopMeLogError(@"Failed to parse ad response, error: %@", error);
            return nil;
        }
        
        _adResponseHTMLString = responseDictionary[@"script"];
        [self mapAdConfigurationFromDictionary:responseDictionary];
    }
    return self;
}

- (NSDictionary *)adIdsForMOAT {
    if (!_adIdsForMOAT) {
    
        NSRange macros = [_adResponseHTMLString rangeOfString:@"macros"];
        NSRange package_ids = [_adResponseHTMLString rangeOfString:@"package_ids"];
        NSString *macrosString = [_adResponseHTMLString substringWithRange:NSMakeRange(macros.location + 8, package_ids.location - macros.location - 10)];
        
        NSDictionary *jsonMacroses = [NSJSONSerialization JSONObjectWithData:[macrosString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        
        _adIdsForMOAT = @{@"level1" : [jsonMacroses[kLoopMeAdvertiser] stringByRemovingPercentEncoding], @"level2" : [jsonMacroses[kLoopMeCampaign] stringByRemovingPercentEncoding], @"level3" : [jsonMacroses[kLoopMeLineItem] stringByRemovingPercentEncoding], @"level4" : [jsonMacroses[kLoopMeCreative] stringByRemovingPercentEncoding], @"slicer1" : [jsonMacroses[kLoopMeAPP] stringByRemovingPercentEncoding], @"slicer2" : @""};
    }
    return _adIdsForMOAT;
}

#pragma mark - Private

- (void)mapAdConfigurationFromDictionary:(NSDictionary *)dictionary {
    NSDictionary *settings = dictionary[@"settings"];
    
    if ([settings[@"format"] isEqualToString:@"banner"]) {
        _format = LoopMeAdFormatBanner;
    } else if ([settings[@"format"] isEqualToString:@"interstitial"]) {
        _format = LoopMeAdFormatInterstitial;
    }
    
    self.mraid = [[settings objectForKey:@"mraid"] boolValue];
    
    [[LoopMeGlobalSettings sharedInstance] setPreload25:[[settings objectForKey:@"preload25"] boolValue]];
    [[LoopMeGlobalSettings sharedInstance] setV360:[[settings objectForKey:@"v360"] boolValue]];
    
    _expirationTime = [settings[@"ad_expiry_time"] integerValue];
    if (_expirationTime < kLoopMeExpireTimeIntervalMinimum) {
        _expirationTime = kLoopMeExpireTimeIntervalMinimum;
    }
    
    if ([settings objectForKey:@"debug"]) {
        [LoopMeGlobalSettings sharedInstance].liveDebugEnabled = [settings[@"debug"] boolValue];
    }
    
    self.measurePartners = [settings objectForKey:@"measure_partners"];
    
    if ([settings[@"orientation"] isEqualToString:@"landscape"]) {
        _orientation = LoopMeAdOrientationLandscape;
    } else if ([settings[@"orientation"] isEqualToString:@"portrait"]) {
        _orientation = LoopMeAdOrientationPortrait;
    } else {
        _orientation = LoopMeAdOrientationUndefined;
    }
}

- (void)initAdIds {
    NSRange macros = [_adResponseHTMLString rangeOfString:@"macros"];
    NSRange package_ids = [_adResponseHTMLString rangeOfString:@"package_ids"];
    NSString *macrosString = [_adResponseHTMLString substringWithRange:NSMakeRange(macros.location + 8, package_ids.location - macros.location - 10)];
    
    NSDictionary *jsonMacroses = [NSJSONSerialization JSONObjectWithData:[macrosString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    NSString *advertiser = [[NSString alloc] initWithString:jsonMacroses[kLoopMeAdvertiser]];
    NSString *capmaign = [[NSString alloc] initWithString:jsonMacroses[kLoopMeCampaign]];
    NSString *lineItem = [[NSString alloc] initWithString:jsonMacroses[kLoopMeLineItem]];
    NSString *creative = [[NSString alloc] initWithString:jsonMacroses[kLoopMeCreative]];
    NSString *app = [[NSString alloc] initWithString:jsonMacroses[kLoopMeAPP]];

    _adIdsForMOAT = @{@"level1" : advertiser, @"level2" : capmaign, @"level3" : lineItem, @"level4" : creative, @"slicer1" : app, @"slicer2" : @""};
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Ad format: %@, orientation: %@, expires in: %ld seconds",
                   (self.format == LoopMeAdFormatBanner) ? @"banner" : @"interstitial",
                   (self.orientation == LoopMeAdOrientationPortrait) ? @"portrait" : @"landscape",
                   (long)self.expirationTime];

}

- (BOOL)useTracking:(NSString *)trakerName {
    return [self.measurePartners containsObject:trakerName];
}

@end
