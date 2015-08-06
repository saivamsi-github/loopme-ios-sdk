//
//  Nativevideo.m
//  LoopMeSDK
//
//  Created by Kogda Bogdan on 2/13/15.
//
//

#import "LoopMeAdView.h"
#import "LoopMeAdManager.h"
#import "LoopMeAdDisplayController.h"
#import "LoopMeAdConfiguration.h"
#import "LoopMeDefinitions.h"
#import "LoopMeError.h"
#import "LoopMeLogging.h"
#import "LoopMeMinimizedAdView.h"
#import "LoopMeGlobalSettings.h"

@interface LoopMeAdView ()
<
    LoopMeAdManagerDelegate,
    LoopMeAdDisplayControllerDelegate,
    LoopMeMinimizedAdViewDelegate
>
@property (nonatomic, strong) LoopMeAdManager *adManager;
@property (nonatomic, strong) LoopMeAdDisplayController *adDisplayController;
@property (nonatomic, strong) LoopMeMinimizedAdView *minimizedView;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, assign, getter = isLoading) BOOL loading;
@property (nonatomic, assign, getter = isReady) BOOL ready;
@property (nonatomic, assign, getter = isMinimized) BOOL minimized;
@property (nonatomic, assign, getter = isNeedsToBeDisplayedWhenReady) BOOL needsToBeDisplayedWhenReady;

/*
 * Update webView "visible" state is required on JS first time when ad appears on the screen,
 * further, we're ommiting sending "webView" states to JS but managing video ad. playback in-SDK
 */
@property (nonatomic, assign, getter = isVisibilityUpdated) BOOL visibilityUpdated;
@end

@implementation LoopMeAdView

#pragma mark - Initialization

- (void)dealloc
{
    [self unRegisterObservers];
    [_minimizedView removeFromSuperview];
    [_adDisplayController stopHandlingRequests];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                         frame:(CGRect)frame
                    scrollView:(UIScrollView *)scrollView
                      delegate:(id<LoopMeAdViewDelegate>)delegate

{
    self = [super init];
    if (self) {
        
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            LoopMeLogDebug(@"Block iOS versions less then 7.0");
            return nil;
        }
        
        _appKey = appKey;
        _delegate = delegate;
        _adManager = [[LoopMeAdManager alloc] initWithDelegate:self];
        _adDisplayController = [[LoopMeAdDisplayController alloc] initWithDelegate:self];
        _scrollView = scrollView;
        self.frame = frame;
        self.backgroundColor = [UIColor blackColor];
        [self registerObservers];
        LoopMeLogInfo(@"Ad view initialized with appKey: %@", appKey);
    }
    return self;
}

- (void)setMinimizedModeEnabled:(BOOL)minimizedModeEnabled {
    if (_minimizedModeEnabled != minimizedModeEnabled) {
        _minimizedModeEnabled = minimizedModeEnabled;
        if (_minimizedModeEnabled) {
            _minimizedView = [[LoopMeMinimizedAdView alloc] initWithDelegate:self];
            _minimizedView.backgroundColor = [UIColor blackColor];
            _minimizedView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            [[UIApplication sharedApplication].keyWindow addSubview:_minimizedView];
        } else {
            [self removeMinimizedView];
        }
    }
}

- (void)setDoNotLoadVideoWithoutWiFi:(BOOL)doNotLoadVideoWithoutWiFi
{
    [LoopMeGlobalSettings sharedInstance].doNotLoadVideoWithoutWiFi = doNotLoadVideoWithoutWiFi;
}

#pragma mark - Class Methods 

+ (LoopMeAdView *)adViewWithAppKey:(NSString *)appKey
                             frame:(CGRect)frame
                        scrollView:(UIScrollView *)scrollView
                          delegate:(id<LoopMeAdViewDelegate>)delegate
{
    return [[self alloc] initWithAppKey:appKey frame:frame scrollView:scrollView delegate:delegate];
}

+ (LoopMeAdView *)adViewWithAppKey:(NSString *)appKey
                             frame:(CGRect)frame
                          delegate:(id<LoopMeAdViewDelegate>)delegate
{
    return [LoopMeAdView adViewWithAppKey:appKey frame:frame scrollView:nil delegate:delegate];
}

#pragma mark - LifeCycle

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (!newSuperview) {
        [self closeAd];
    } else {
        if (!self.isReady)
            self.needsToBeDisplayedWhenReady = YES;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    if (self.superview && self.isReady)
        [self displayAd];
}

#pragma mark - Observering

- (void)unRegisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    
}

- (void)didBecomeActive:(NSNotification *)notification
{
    if (self.superview) {
        self.visibilityUpdated = NO;
        [self updateVisibility];
    }
}

- (void)didEnterBackground:(NSNotification *)notification
{
    self.adDisplayController.visible = NO;
}

#pragma mark - Public

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
    self.ready = NO;
    self.loading = YES;
    [self.adManager loadAdWithAppKey:self.appKey targeting:targeting];
}

- (void)setAdVisible:(BOOL)visible
{
    if (self.isReady) {

        self.adDisplayController.forceHidden = !visible;
        self.adDisplayController.visible = visible;
        
        if (self.isMinimizedModeEnabled && self.scrollView) {
            if (!visible) {
                [self toOriginalSize];
            } else {
                [self updateAdVisibilityInScrollView];
            }
        }
    }
}

/*
 * Don't set visible/hidden state during scrolling, causes issues on iOS 8.0 and up
 */
- (void)updateAdVisibilityInScrollView
{
    if (!self.superview) {
        return;
    }

    CGRect relativeToScrollViewAdRect = [self convertRect:self.bounds toView:self.scrollView];
    CGRect visibleScrollViewRect = CGRectMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    
    if (![self isRect:relativeToScrollViewAdRect outOfRect:visibleScrollViewRect]) {
        if (self.isMinimizedModeEnabled && self.minimizedView.superview) {
            [self updateAdVisibilityWhenScroll];
            [self minimize];
        }
    } else {
        [self toOriginalSize];
    }
    
    if (self.isMinimized) {
        return;
    }
    
    if ([self moreThenHalfOfRect:relativeToScrollViewAdRect visibleInRect:visibleScrollViewRect]) {
        [self updateAdVisibilityWhenScroll];
    } else {
        self.adDisplayController.visibleNoJS = NO;
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [self.minimizedView rotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation animated:YES];
    [self.minimizedView adjustFrame];
}

#pragma mark - Private

- (void)minimize
{
    if (!self.isMinimized && self.adDisplayController.isVisible) {
        self.minimized = YES;
        [self.minimizedView show];
        [self.adDisplayController moveView];
    }
}

- (void)toOriginalSize
{
    if (self.isMinimized) {
        self.minimized = NO;
        [self.minimizedView hide];
        [self.adDisplayController moveView];
    }
}

- (void)removeMinimizedView {
    [self.minimizedView removeFromSuperview];
    self.minimizedView = nil;
}

- (BOOL)moreThenHalfOfRect:(CGRect)rect visibleInRect:(CGRect)visibleRect
{
    return (CGRectContainsPoint(visibleRect, CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))));
}

- (BOOL)isRect:(CGRect)rect outOfRect:(CGRect)visibleRect
{
    return CGRectIntersectsRect(rect, visibleRect);
}

- (void)failedLoadingAdWithError:(NSError *)error
{
    self.loading = NO;
    self.ready = NO;
    if ([self.delegate respondsToSelector:@selector(loopMeAdView:didFailToLoadAdWithError:)]) {
        [self.delegate loopMeAdView:self didFailToLoadAdWithError:error];
    }
}

- (void)updateVisibility
{
    if (!self.scrollView) {
        self.adDisplayController.visible = YES;
    } else {
        [self performSelector:@selector(updateAdVisibilityInScrollView) withObject:nil afterDelay:0.1];
    }
}

- (void)updateAdVisibilityWhenScroll {
    if (!self.isVisibilityUpdated) {
        self.adDisplayController.visible = YES;
        self.visibilityUpdated = YES;
    } else {
        self.adDisplayController.visibleNoJS = YES;
    }
}

- (void)closeAd
{
    [self.minimizedView removeFromSuperview];
    [self.adDisplayController closeAd];
    self.ready = NO;
    self.loading = NO;
}

- (void)displayAd
{
    [self.adDisplayController displayAd];
    [self.adManager invalidateTimers];
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        return;
    }
    [self updateVisibility];
}

#pragma mark - LoopMeAdManagerDelegate

- (void)adManager:(LoopMeAdManager *)manager didReceiveAdConfiguration:(LoopMeAdConfiguration *)adConfiguration
{
    if (!adConfiguration || adConfiguration.format != LoopMeAdFormatBanner) {
        NSString *errorMessage = @"Could not process ad: interstitial format expected.";
        LoopMeLogDebug(errorMessage);
        [self failedLoadingAdWithError:[LoopMeError errorForStatusCode:LoopMeErrorCodeIncorrectFormat]];
        return;
    }
    [self.adDisplayController loadConfiguration:adConfiguration];
}

- (void)adManager:(LoopMeAdManager *)manager didFailToLoadAdWithError:(NSError *)error
{
    self.ready = NO;
    self.loading = NO;
    [self failedLoadingAdWithError:error];
}

- (void)adManagerDidExpireAd:(LoopMeAdManager *)manager
{
    self.ready = NO;
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewDidExpire:)]) {
        [self.delegate loopMeAdViewDidExpire:self];
    }
}

#pragma mark - LoopMeMinimizedAdViewDelegate

- (void)minimizedAdViewShouldRemove:(LoopMeMinimizedAdView *)minimizedAdView {
    [self toOriginalSize];
    [self.minimizedView removeFromSuperview];
    self.minimizedView = nil;
    [self updateAdVisibilityInScrollView];
}


#pragma mark - LoopMeAdDisplayControllerDelegate

- (UIView *)containerView
{
    if (self.isMinimized) {
        return self.minimizedView;
    }
    return self;
}

- (UIViewController *)viewControllerForPresentation
{
    return self.delegate.viewControllerForPresentation;
}

- (void)adDisplayControllerDidFinishLoadingAd:(LoopMeAdDisplayController *)adDisplayController
{
    self.loading = NO;
    self.ready = YES;
    if (self.isNeedsToBeDisplayedWhenReady) {
        self.needsToBeDisplayedWhenReady = NO;
        [self displayAd];
    }
    
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewDidLoadAd:)]) {
        [self.delegate loopMeAdViewDidLoadAd:self];
    }
}

- (void)adDisplayController:(LoopMeAdDisplayController *)adDisplayController didFailToLoadAdWithError:(NSError *)error
{
    [self failedLoadingAdWithError:error];
}

- (void)adDisplayControllerDidReceiveTap:(LoopMeAdDisplayController *)adDisplayController
{
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewDidReceiveTap:)]) {
        [self.delegate loopMeAdViewDidReceiveTap:self];
    }
}

- (void)adDisplayControllerWillLeaveApplication:(LoopMeAdDisplayController *)adDisplayController
{
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewWillLeaveApplication:)]) {
        [self.delegate loopMeAdViewWillLeaveApplication:self];
    }
}

- (void)adDisplayControllerVideoDidReachEnd:(LoopMeAdDisplayController *)adDisplayController
{
    [self performSelector:@selector(removeMinimizedView) withObject:nil afterDelay:1.0];
    
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewVideoDidReachEnd:)]) {
        [self.delegate loopMeAdViewVideoDidReachEnd:self];
    }
}

- (void)adDisplayControllerDidDismissModal:(LoopMeAdDisplayController *)adDisplayController
{
    self.visibilityUpdated = NO;
    [self updateVisibility];
}

- (void)adDisplayControllerShouldCloseAd:(LoopMeAdDisplayController *)adDisplayController
{
    [self closeAd];
}

@end
