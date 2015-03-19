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

NSString * const TEST_APP_KEY_MPU = @"test_mpu";

@interface LoopMeAdView ()
<
    LoopMeAdManagerDelegate,
    LoopMeAdDisplayControllerDelegate
>
@property (nonatomic, strong) LoopMeAdManager *adManager;
@property (nonatomic, strong) LoopMeAdDisplayController *adDisplayController;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, assign, getter = isLoading) BOOL loading;
@property (nonatomic, assign, getter = isReady) BOOL ready;

@end

@implementation LoopMeAdView

#pragma mark - Initialization

- (void)dealloc
{
    [self unRegisterObservers];
    [_adDisplayController stopHandlingRequests];
}

- (instancetype)initWithAppKey:(NSString *)appKey
                         frame:(CGRect)frame
                    scrollView:(UIScrollView *)scrollView
                      delegate:(id<LoopMeAdViewDelegate>)delegate

{
    self = [super init];
    if (self) {
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
        [self.adDisplayController closeAd];
        self.ready = NO;
        self.loading = NO;
    } else {
        [self.adDisplayController displayAd];
        [self.adManager invalidateTimers];

        if (!self.scrollView) {
            self.adDisplayController.visible = YES;
        } else {
            [self performSelector:@selector(updateAdVisibilityInScrollView) withObject:nil afterDelay:0.0f];
        }
    }
}

#pragma mark - Observering

- (void)unRegisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didBecomeActive:(NSNotification *)notification
{
    if (self.superview) {
        if (!self.scrollView) {
            self.adDisplayController.visible = YES;
        } else {
            [self updateAdVisibilityInScrollView];
        }
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
    self.loading = YES;
    self.ready = NO;

    self.loading = YES;
    [self.adManager loadAdWithAppKey:self.appKey targeting:targeting];
}

- (void)setAdVisible:(BOOL)visible {
    if (self.isReady) {
        self.adDisplayController.visible = visible;
    }
}

- (void)updateAdVisibilityInScrollView {
    
    if (!self.superview) {
        return;
    }

    CGRect frameRelativeToView = [self convertRect:self.bounds toView:self.scrollView];
    CGRect visibleRect = CGRectMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    if (CGRectContainsPoint(visibleRect, CGPointMake(CGRectGetMidX(frameRelativeToView), CGRectGetMidY(frameRelativeToView)))) {
        self.adDisplayController.visible = YES;
    } else {
        self.adDisplayController.visible = NO;
    }
}

#pragma mark - Private

- (void)failedLoadingAdWithError:(NSError *)error
{
    self.loading = NO;
    self.ready = NO;
    if ([self.delegate respondsToSelector:@selector(loopMeAdView:didFailToLoadAdWithError:)]) {
        [self.delegate loopMeAdView:self didFailToLoadAdWithError:error];
    }
}

#pragma mark - LoopMeAdManagerDelegate

- (void)adManager:(LoopMeAdManager *)manager didReceiveAdConfiguration:(LoopMeAdConfiguration *)adConfiguration {
    
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

- (void)adManagerDidExpireAd:(LoopMeAdManager *)manager {
    self.ready = NO;
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewDidExpire:)]) {
        [self.delegate loopMeAdViewDidExpire:self];
    }
}

#pragma mark - LoopMeAdDisplayControllerDelegate

- (UIView *)containerView
{
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
    if ([self.delegate respondsToSelector:@selector(loopMeAdViewVideoDidReachEnd:)]) {
        [self.delegate loopMeAdViewVideoDidReachEnd:self];
    }
}

- (void)adDisplayControllerDidDismissModal:(LoopMeAdDisplayController *)adDisplayController
{
    if (self.scrollView) {
        [self updateAdVisibilityInScrollView];
    } else {
        self.adDisplayController.visible = YES;
    }
}

- (void)adDisplayControllerShouldCloseAd:(LoopMeAdDisplayController *)adDisplayController
{
    [self removeFromSuperview];
}

@end
