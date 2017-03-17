//
//  LoopMeInterstitialManager.h
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoopMeAdConfiguration;
@class LoopMeInterstitial;
@class LoopMeAdManager;
@class LoopMeTargeting;

extern const struct LoopMeIntegrationTypeStruct {
    __unsafe_unretained NSString *normal;
    __unsafe_unretained NSString *mopub;
    __unsafe_unretained NSString *admob;
    __unsafe_unretained NSString *fyber;
    __unsafe_unretained NSString *unity;
    __unsafe_unretained NSString *adobeAir;
} LoopMeIntegrationType;

@protocol LoopMeAdManagerDelegate;

@interface LoopMeAdManager : NSObject

@property (nonatomic, weak) id<LoopMeAdManagerDelegate> delegate;
@property (nonatomic, strong) NSURL *testServerBaseURL;
@property (nonatomic, assign, readonly, getter = isLoading) BOOL loading;

- (instancetype)initWithDelegate:(id<LoopMeAdManagerDelegate>)delegate;
- (void)loadAdWithAppKey:(NSString *)appKey targeting:(LoopMeTargeting *)targeting
         integrationType:(NSString *)integrationType adSpotSize:(CGSize)size;
- (void)invalidateTimers;

@end

@protocol LoopMeAdManagerDelegate <NSObject>

- (void)adManager:(LoopMeAdManager *)manager didFailToLoadAdWithError:(NSError *)error;
- (void)adManager:(LoopMeAdManager *)manager didReceiveAdConfiguration:(LoopMeAdConfiguration *)adConfiguration;
- (void)adManagerDidExpireAd:(LoopMeAdManager *)manager;

@end
