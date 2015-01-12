//
//  LoopMeInterstitial.h
//  LoopMeSDK
//
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoopMeInterstitial;
@class LoopMeTargeting;
@protocol LoopMeInterstitialDelegate <NSObject>

/*
 * It is highly recomended to load ad again when interstitial ad is expired.
 */
- (void)loopMeInterstitialDidExpire:(LoopMeInterstitial *)interstitial;

@optional
- (void)loopMeInterstitialWillAppear:(LoopMeInterstitial *)interstitial;
- (void)loopMeInterstitialDidAppear:(LoopMeInterstitial *)interstitial;
- (void)loopMeInterstitialWillDisappear:(LoopMeInterstitial *)interstitial;
- (void)loopMeInterstitialDidDisappear:(LoopMeInterstitial *)interstitial;

- (void)loopMeInterstitialDidLoadAd:(LoopMeInterstitial *)interstitial;
- (void)loopMeInterstitial:(LoopMeInterstitial *)interstitial didFailToLoadAdWithError:(NSError *)error;

- (void)loopMeInterstitialDidReceiveTap:(LoopMeInterstitial *)interstitial;
- (void)loopMeInterstitialWillLeaveApplication:(LoopMeInterstitial *)interstitial;

- (void)loopMeInterstitialVideoDidReachEnd:(LoopMeInterstitial *)interstitial;

@end

@interface LoopMeInterstitial : NSObject

@property (nonatomic, assign) id<LoopMeInterstitialDelegate> delegate;
@property (nonatomic, strong) LoopMeTargeting *targeting;
@property (nonatomic, strong, readonly) NSString *appKey;
@property (nonatomic, readonly, getter = isReady) BOOL ready;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;
@property (nonatomic, assign) BOOL testMode;

+ (LoopMeInterstitial *)interstitialWithAppKey:(NSString *)appKey
                                      delegate:(id<LoopMeInterstitialDelegate>)delegate;

+ (NSMutableArray *)sharedInterstitials;
+ (void)removeSharedInterstitial:(LoopMeInterstitial *)interstitial;

/*
 * Use this method to load ads before using -showFromViewController, 
 * we also would reccomend to trigger it in -loopMeInterstitialDidDisappear delegate method to keep content up-to-date.
 */
- (void)loadAd;
- (void)loadAdWithTargeting:(LoopMeTargeting *)targeting;

- (void)showFromViewController:(UIViewController *)viewController;
@end