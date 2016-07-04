//
//  LoopMeInterstitial.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 6/21/12.
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import "LoopMeAdConfiguration.h"
#import "LoopMeDefinitions.h"
#import "LoopMeInterstitial.h"
#import "LoopMeAdManager.h"
#import "LoopMeTargeting.h"
#import "LoopMeGeoLocationProvider.h"
#import "LoopMeAdDisplayController.h"
#import "LoopMeInterstitialViewController.h"
#import "LoopMeError.h"
#import "LoopMeLogging.h"
#import "LoopMeGlobalSettings.h"
#import "LoopMeErrorEventSender.h"
#import "LoopMeAnalyticsProvider.h"

@interface LoopMeInterstitial ()
<
    LoopMeAdManagerDelegate,
    LoopMeAdDisplayControllerDelegate,
    LoopMeInterstitialViewControllerDelegate
>
@property (nonatomic, assign, getter = isLoading) BOOL loading;
@property (nonatomic, assign, getter = isReady) BOOL ready;
@property (nonatomic, strong) LoopMeAdConfiguration *adConfiguration;
@property (nonatomic, strong) LoopMeAdManager *adManager;
@property (nonatomic, strong) LoopMeAdDisplayController *adDisplayController;
@property (nonatomic, strong) LoopMeInterstitialViewController *adInterstitialViewController;
@property (nonatomic, strong) NSTimer *timeoutTimer;

@end

@implementation LoopMeInterstitial

#pragma mark - Life Cycle

- (void)dealloc
{
    [self unRegisterObserver];
    [_adManager invalidateTimers];
    [_adDisplayController stopHandlingRequests];
    _adDisplayController.delegate = nil;
}

- (instancetype)initWithAppKey:(NSString *)appKey
            delegate:(id<LoopMeInterstitialDelegate>)delegate
{
    if (!appKey) {
        LoopMeLogError(@"AppKey cann't be nil");
        return nil;
    }
    
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        LoopMeLogDebug(@"Block iOS versions less then 8.0");
        return nil;
    }
    
    if (self = [super init]) {
        _appKey = [appKey copy];
        _delegate = delegate;
        [self registerObserver];
        _adManager = [[LoopMeAdManager alloc] initWithDelegate:self];
        _adDisplayController = [[LoopMeAdDisplayController alloc] initWithDelegate:self];
        _adInterstitialViewController = [[LoopMeInterstitialViewController alloc] init];
        _adInterstitialViewController.delegate = self;
        LoopMeLogInfo(@"Interstitial is initialized with appKey %@", appKey);
        
        [LoopMeAnalyticsProvider sharedInstance];
    }
    return self;
}

- (void)setDoNotLoadVideoWithoutWiFi:(BOOL)doNotLoadVideoWithoutWiFi
{
    [LoopMeGlobalSettings sharedInstance].doNotLoadVideoWithoutWiFi = doNotLoadVideoWithoutWiFi;
}

#pragma mark - Class Methods

+ (LoopMeInterstitial *)interstitialWithAppKey:(NSString *)appKey
                                      delegate:(id<LoopMeInterstitialDelegate>)delegate
{
    NSMutableArray *interstitials = [[self class] sharedInterstitials];
    @synchronized(self) {
        // Look for existing interstitial based on the appKey
        LoopMeInterstitial *returnableInterstitial = nil;
        for (LoopMeInterstitial *currentInterstitial in interstitials) {
            if ([currentInterstitial.appKey isEqualToString:appKey]) {
                returnableInterstitial = currentInterstitial;
                returnableInterstitial.delegate = delegate;
                break;
            }
        }
        // Create a new interstitial instance for this appKey if one doesn't already exist.
        if (!returnableInterstitial) {
            returnableInterstitial = [[[self class] alloc] initWithAppKey:appKey
                                                                 delegate:delegate];
            [interstitials addObject:returnableInterstitial];
        }
        return returnableInterstitial;
    }
}

+ (NSMutableArray *)sharedInterstitials
{
    static NSMutableArray *sharedInterstitials;
    
    @synchronized(self) {
        if (!sharedInterstitials) {
            sharedInterstitials = [NSMutableArray array];
        }
    }
    return sharedInterstitials;
}

+ (void)removeSharedInterstitial:(LoopMeInterstitial *)interstitial
{
    if ([[[self class] sharedInterstitials] containsObject:interstitial]) {
        [interstitial dismissAnimated:NO];
        LoopMeLogInfo(@"Removing interstitial ad for appKey:%@", interstitial.appKey);
        [[[self class] sharedInterstitials] removeObject:interstitial];
    } else {
        LoopMeLogInfo(@"Interstitial ad for appKey:%@ not found", interstitial.appKey);
    }
}

#pragma mark - Private

- (void)unRegisterObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)registerObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)willResignActive:(NSNotification *)n
{
    [self dismissAnimated:NO];
}


- (void)failedLoadingAdWithError:(NSError *)error {
    self.loading = NO;
    self.ready = NO;
    [self invalidateTimer];
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitial:didFailToLoadAdWithError:)]) {
        [self.delegate loopMeInterstitial:self didFailToLoadAdWithError:error];
    }
}

- (void)timeOut {
    [self.adDisplayController stopHandlingRequests];
    [LoopMeErrorEventSender sendEventTo:[LoopMeGlobalSettings sharedInstance].errorLinkFormat withError:LoopMeEventErrorTypeTimeOut];
    [self failedLoadingAdWithError:[LoopMeError errorForStatusCode:LoopMeErrorCodeHTMLRequestTimeOut]];
}

- (void)invalidateTimer {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
}

#pragma mark - Public Mehtods

- (void)setServerBaseURL:(NSURL *)URL
{
    self.adManager.testServerBaseURL = URL;
}

- (void)loadAd
{
    [self loadAdWithTargeting:nil];
}

- (void)loadAdWithTargeting:(LoopMeTargeting *)targeting
{
    if (self.isLoading) {
        LoopMeLogInfo(@"Wait for previous loading ad process finish");
        return;
    }
    if (self.isReady) {
        LoopMeLogInfo(@"Ad already loaded and ready to be displayed");
        return;
    }
    self.loading = YES;
    self.ready = NO;
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(timeOut) userInfo:nil repeats:NO];
    [self.adManager loadAdWithAppKey:self.appKey targeting:targeting];
}

- (void)showFromViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.isReady) {
        LoopMeLogInfo(@"Ad isn't ready to be displayed");
        [[LoopMeLoggingSender sharedInstance] notReadyDisplay];
        return;
    }

    LoopMeLogDebug(@"Interstitial ad will appear");
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialWillAppear:)]) {
        [self.delegate loopMeInterstitialWillAppear:self];
    }
    [self.adManager invalidateTimers];
    [self.adInterstitialViewController setOrientation:self.adConfiguration.orientation];
    [self.adDisplayController displayAd];
    self.adDisplayController.visible = YES;
    [viewController presentViewController:self.adInterstitialViewController animated:animated completion:^{
        [self.adDisplayController layoutSubviews];
        LoopMeLogDebug(@"Interstitial ad did appear");
        if ([self.delegate respondsToSelector:@selector(loopMeInterstitialDidAppear:)]) {
            [self.delegate loopMeInterstitialDidAppear:self];
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated
{
    if (!self.adInterstitialViewController.presentingViewController) {
        return;
    }
    self.ready = NO;
    LoopMeLogDebug(@"Interstitial ad will disappear");
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialWillDisappear:)]) {
        [self.delegate loopMeInterstitialWillDisappear:self];
    }
    
    [self.adDisplayController closeAd];

    [self.adInterstitialViewController.presentingViewController dismissViewControllerAnimated:animated completion:^{
        LoopMeLogDebug(@"Interstitial ad did disappear");
        if ([self.delegate respondsToSelector:@selector(loopMeInterstitialDidDisappear:)]) {
            [self.delegate loopMeInterstitialDidDisappear:self];
        }
    }];
}

#pragma mark - LoopMeAdManagerDelegate

- (void)adManager:(LoopMeAdManager *)manager didReceiveAdConfiguration:(LoopMeAdConfiguration *)adConfiguration {
    
    if (!adConfiguration || adConfiguration.format != LoopMeAdFormatInterstitial) {
        NSString *errorMessage = @"Could not process ad: interstitial format expected.";
        LoopMeLogDebug(errorMessage);
        NSError *error = [LoopMeError errorForStatusCode:LoopMeErrorCodeIncorrectFormat];
        [self failedLoadingAdWithError:error];
        return;
    }
    self.adConfiguration = adConfiguration;
    [self.adDisplayController loadConfiguration:adConfiguration];
}

- (void)adManager:(LoopMeAdManager *)manager didFailToLoadAdWithError:(NSError *)error
{
    [self failedLoadingAdWithError:error];
}

- (void)adManagerDidExpireAd:(LoopMeAdManager *)manager
{
    self.ready = NO;
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialDidExpire:)]) {
        [self.delegate loopMeInterstitialDidExpire:self];
    }
}

#pragma mark - LoopMeInterstitialViewControllerDelegate

- (void)viewWillTransitionToSize:(CGSize)size {
    [self.adDisplayController layoutSubviewsToFrame:CGRectMake(0, 0, size.width, size.height)];
}

#pragma mark - LoopMeAdDisplayControllerDelegate

- (UIViewController *)viewControllerForPresentation
{
    return self.adInterstitialViewController;
}

- (UIView *)containerView
{
    return self.adInterstitialViewController.view;
}

- (void)adDisplayControllerDidFinishLoadingAd:(LoopMeAdDisplayController *)adDisplayController
{
    self.loading = NO;
    self.ready = YES;
    [self invalidateTimer];
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialDidLoadAd:)]) {
        [self.delegate loopMeInterstitialDidLoadAd:self];
    }
}

- (void)adDisplayController:(LoopMeAdDisplayController *)adDisplayController didFailToLoadAdWithError:(NSError *)error
{
    [self failedLoadingAdWithError:error];
}

- (void)adDisplayControllerDidReceiveTap:(LoopMeAdDisplayController *)adDisplayController
{
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialDidReceiveTap:)]) {
        [self.delegate loopMeInterstitialDidReceiveTap:self];
    }
}

- (void)adDisplayControllerWillLeaveApplication:(LoopMeAdDisplayController *)adDisplayController
{
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialWillLeaveApplication:)]) {
        [self.delegate loopMeInterstitialWillLeaveApplication:self];
    }
}

- (void)adDisplayControllerVideoDidReachEnd:(LoopMeAdDisplayController *)adDisplayController
{
    if ([self.delegate respondsToSelector:@selector(loopMeInterstitialVideoDidReachEnd:)]) {
        [self.delegate loopMeInterstitialVideoDidReachEnd:self];
    }
}

- (void)adDisplayControllerWillExpandAd:(LoopMeAdDisplayController *)adDisplayController
{
    
}

- (void)adDisplayControllerShouldCloseAd:(LoopMeAdDisplayController *)adDisplayController
{
    [self dismissAnimated:NO];
}

- (void)adDisplayControllerDidDismissModal:(LoopMeAdDisplayController *)adDisplayController {
    self.adDisplayController.visible = YES;
}

- (void)adDisplayControllerWillCollapse:(LoopMeAdDisplayController *)adDisplayController {
    
}

@end
