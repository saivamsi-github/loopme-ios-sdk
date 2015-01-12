//
//  LoopMeBanner.h
//  LoopMeSDK
//
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LOOPME_AD_SIZE_320_50 CGSizeMake(320, 50)
#define LOOPME_AD_SIZE_300_250 CGSizeMake(300, 250)
#define LOOPME_AD_SIZE_728_90 CGSizeMake(728, 90)
#define LOOPME_AD_SIZE_160_600 CGSizeMake(160, 600)

@class LoopMeBanner;
@class LoopMeTargeting;

@protocol LoopMeBannerDelegate <NSObject>
@required
- (UIViewController *)viewControllerForPresentation;

@optional

- (void)loopMeBannerDidRecieveTap:(LoopMeBanner *)banner;
- (void)loopMeBannerWillLeaveApplication:(LoopMeBanner *)banner;
- (void)loopMeBanner:(LoopMeBanner *)banner
    didFailToLoadAdWithError:(NSError *)error;
- (void)loopMeBannerDidAppear:(LoopMeBanner *)banner;
- (void)loopMeBannerDidDisappear:(LoopMeBanner *)banner;

@end

@interface LoopMeBanner : NSObject

@property (nonatomic, assign) id<LoopMeBannerDelegate> delegate;
@property (nonatomic) LoopMeTargeting *targeting;
@property (nonatomic, assign) BOOL testMode;

+ (LoopMeBanner *)bannerWithAppKey:(NSString *)appKey
                          delegate:(id<LoopMeBannerDelegate>)delegate;
+ (LoopMeBanner *)bannerWithAppKey:(NSString *)appKey
                        targeting:(LoopMeTargeting *)targeting
                          delegate:(id<LoopMeBannerDelegate>)delegate;
- (void)showInView:(UIView *)view withFrame:(CGRect)frame;
- (void)hide;

@end
