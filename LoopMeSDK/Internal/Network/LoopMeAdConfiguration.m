//
//  LoopMeAdConfiguration.m
//  LoopMe
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.

#import "LoopMeAdConfiguration.h"
#import "LoopMeLogging.h"

const int kLoopMeExpireTimeIntervalMinimum = 600;

@implementation LoopMeAdConfiguration

#pragma mark - Life Cycle

- (instancetype)initWithData:(NSData *)data
{
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

#pragma mark - Private

- (void)mapAdConfigurationFromDictionary:(NSDictionary *)dictionary
{
    NSDictionary *settings = dictionary[@"settings"];
    
    if ([settings[@"format"] isEqualToString:@"banner"]) {
        _format = LoopMeAdFormatBanner;
    } else if ([settings[@"format"] isEqualToString:@"interstitial"]) {
        _format = LoopMeAdFormatInterstitial;
    }
    
    _expirationTime = [settings[@"ad_expiry_time"] integerValue];
    if (_expirationTime < kLoopMeExpireTimeIntervalMinimum) {
        _expirationTime = kLoopMeExpireTimeIntervalMinimum;
    }
    
    if ([settings[@"orientation"] isEqualToString:@"landscape"]) {
        _orientation = LoopMeAdOrientationLandscape;
    } else if ([settings[@"orientation"] isEqualToString:@"portrait"]) {
        _orientation = LoopMeAdOrienationPortrait;
    } else {
        _orientation = LoopMeAdOrientationUndefined;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Ad format: %@, orientation: %@, expires in: %ld seconds",
                   (self.format == LoopMeAdFormatBanner) ? @"banner" : @"interstitial",
                   (self.orientation == LoopMeAdOrienationPortrait) ? @"portrait" : @"landscape",
                   (long)self.expirationTime];

}
@end
