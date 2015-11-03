//
//  LoopMeAdConfiguration.h
//  LoopMe
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, LoopMeAdOrientation) {
    LoopMeAdOrientationUndefined,
    LoopMeAdOrientationPortrait,
    LoopMeAdOrientationLandscape
};

typedef NS_ENUM (NSInteger, LoopMeAdFormat) {
    LoopMeAdFormatInterstitial,
    LoopMeAdFormatBanner
};

@interface LoopMeAdConfiguration : NSObject

- (instancetype)initWithData:(NSData *)data;

@property (nonatomic, assign) LoopMeAdFormat format;
@property (nonatomic, assign) LoopMeAdOrientation orientation;
@property (nonatomic, assign) NSInteger expirationTime;
@property (nonatomic, strong) NSString *adResponseHTMLString;

@end
