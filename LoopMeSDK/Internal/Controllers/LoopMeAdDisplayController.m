//
//  LoopMeAdWebViewAgent.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "LoopMeAdDisplayController.h"
#import "LoopMeAdConfiguration.h"
#import "LoopMeAdWebView.h"
#import "LoopMeDefinitions.h"
#import "LoopMeDestinationDisplayController.h"
#import "LoopMeJSClient.h"
#import "LoopMeVideoClient.h"
#import "NSURL+LoopMeAdditions.h"
#import "LoopMeError.h"
#import "LoopMeLogging.h"

NSInteger const kLoopMeWebViewLoadingTimeout = 180;
NSString * const kLoopMeShakeNotificationName = @"DeviceShaken";

@interface LoopMeAdDisplayController ()
<
    UIWebViewDelegate,
    LoopMeVideoClientDelegate,
    LoopMeJSClientDelegate,
    LoopMeDestinationDisplayControllerDelegate
>

@property (nonatomic, strong) LoopMeAdWebView *webView;
@property (nonatomic, strong) LoopMeJSClient *JSClient;
@property (nonatomic, strong) LoopMeVideoClient *videoClient;
@property (nonatomic, strong) LoopMeDestinationDisplayController *destinationDisplayAgent;
@property (nonatomic, assign, getter = isShouldHandleRequests) BOOL shouldHandleRequests;
@property (nonatomic, assign) BOOL forceInvisible;
@property (nonatomic, strong) NSTimer *webViewTimeOutTimer;

- (void)deviceShaken;
- (BOOL)shouldIntercept:(NSURL *)URL
         navigationType:(UIWebViewNavigationType)navigationType;
- (void)interceptURL:(NSURL *)URL;

@end

@implementation LoopMeAdDisplayController

#pragma mark - Properties

- (LoopMeVideoClient *)videoClient
{
    if (_videoClient == nil) {
        _videoClient = [[LoopMeVideoClient alloc] initWithDelegate:self];
    }
    return _videoClient;
}

- (void)setVisible:(BOOL)visible
{
    if (_forceInvisible) visible = NO;
    if (_visible != visible) {
    
        _visible = visible;
        if (_visible) {
            [self.JSClient executeEvent:LoopMeEvent.state forNamespace:kLoopMeNamespaceWebview param:LoopMeWebViewState.visible];
        } else {
            [self.JSClient executeEvent:LoopMeEvent.state forNamespace:kLoopMeNamespaceWebview param:LoopMeWebViewState.hidden];
        }
    }
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [_webView stopLoading];
    _webView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoopMeShakeNotificationName object:nil];
    [_webViewTimeOutTimer invalidate];
    _webViewTimeOutTimer = nil;
}

- (instancetype)initWithDelegate:(id<LoopMeAdDisplayControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _destinationDisplayAgent = [LoopMeDestinationDisplayController controllerWithDelegate:self];
        _JSClient = [[LoopMeJSClient alloc] initWithDelegate:self];
        _webView = [[LoopMeAdWebView alloc] init];
        _webView.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceShaken) name:kLoopMeShakeNotificationName object:nil];
    }
    return self;
}

#pragma mark - Private

- (void)deviceShaken
{
    [self.JSClient setShake];
}

- (BOOL)shouldIntercept:(NSURL *)URL
         navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([self.delegate respondsToSelector:@selector(adDisplayControllerDidReceiveTap:)]) {
            [self.delegate adDisplayControllerDidReceiveTap:self];
        }
        return YES;
    } else if (navigationType == UIWebViewNavigationTypeOther) {
        return NO;
    }
    return NO;
}

- (void)interceptURL:(NSURL *)URL
{
    [self.destinationDisplayAgent displayDestinationWithURL:URL];
}

- (void)cancelWebView
{
    [self.webView stopLoading];
    
    NSError *error = [LoopMeError errorForStatusCode:LoopMeErrorCodeHTMLRequestTimeOut];
    if ([self.delegate respondsToSelector:@selector(adDisplayController:didFailToLoadAdWithError:)]) {
        LoopMeLogInfo(@"Ad failed to load: %@", error);
        [self.delegate adDisplayController:self didFailToLoadAdWithError:error];
    }
}
#pragma mark - Public

- (void)loadConfiguration:(LoopMeAdConfiguration *)configuration
{
    self.shouldHandleRequests = YES;
    [self.webView loadHTMLString:configuration.adResponseHTMLString
                         baseURL:nil];
    self.webViewTimeOutTimer = [NSTimer scheduledTimerWithTimeInterval:kLoopMeWebViewLoadingTimeout target:self selector:@selector(cancelWebView) userInfo:nil repeats:NO];
}

- (void)displayAd
{
    self.webView.frame = self.delegate.containerView.bounds;
    [self.videoClient adjustLayerToFrame:self.webView.frame];
    [self.delegate.containerView addSubview:self.webView];
    [self.delegate.containerView bringSubviewToFront:self.webView];
}

- (void)closeAd
{
    [self stopHandlingRequests];
    self.visible = NO;
    [self.JSClient executeEvent:LoopMeEvent.state forNamespace:kLoopMeNamespaceWebview param:LoopMeWebViewState.closed];
}

- (void)layoutSubviews {
    [self.videoClient adjustLayerToFrame:self.webView.frame];
}

- (void)stopHandlingRequests
{
    self.shouldHandleRequests = NO;
    [self.destinationDisplayAgent cancel];
    [self.videoClient cancel];
    [self.webView stopLoading];
    [self.webViewTimeOutTimer invalidate];
}

- (void)continueHandlingRequests
{
    self.shouldHandleRequests = YES;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (!self.isShouldHandleRequests) {
        return NO;
    }
    NSURL *URL = [request URL];
    if ([self.JSClient shouldInterceptURL:URL]) {
        [self.JSClient executeEvent:LoopMeEvent.isNativeCallFinished forNamespace:kLoopMeNamespaceWebview param:@YES paramBOOL:YES];
        [self.JSClient processURL:URL];
        return NO;
    } else if ([self shouldIntercept:URL navigationType:navigationType]) {
        [self interceptURL:URL];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    LoopMeLogDebug(@"WebView received an error %@", error);
    if (error.code == -1004) {
        if ([self.delegate respondsToSelector:@selector(adDisplayController:didFailToLoadAdWithError:)]) {
            [self.delegate adDisplayController:self didFailToLoadAdWithError:error];
        }
    }
}

#pragma mark - LoopMeDestinationDisplayAgentDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentation];
}

- (void)destinationDisplayControllerWillLeaveApplication:(LoopMeDestinationDisplayController *)destinationAgent
{
    if ([self.delegate respondsToSelector:@selector(adDisplayControllerWillLeaveApplication:)]) {
        [self.delegate adDisplayControllerWillLeaveApplication:self];
    }
}

- (void)destinationDisplayControllerWillPresentModal:(LoopMeDestinationDisplayController *)destinationAgent
{
    self.forceInvisible = YES;
    self.visible = NO;
}

- (void)destinationDisplayControllerDidDismissModal:(LoopMeDestinationDisplayController *)destinationAgent
{
    self.forceInvisible = NO;
    if ([self.delegate respondsToSelector:@selector(adDisplayControllerDidDismissModal:)]) {
        [self.delegate adDisplayControllerDidDismissModal:self];
    }
}

#pragma mark - JSClientDelegate 

- (UIWebView *)webViewTransport
{
    return self.webView;
}

- (id<LoopMeVideoCommunicatorProtocol>)videoCommunicator
{
    return self.videoClient;
}

- (void)JSClientDidReceiveSuccessCommand:(LoopMeJSClient *)client
{
    LoopMeLogInfo(@"Ad was successfully loaded");
    [self.webViewTimeOutTimer invalidate];
    _webViewTimeOutTimer = nil;
    if ([self.delegate respondsToSelector:@selector(adDisplayControllerDidFinishLoadingAd:)]) {
        [self.delegate adDisplayControllerDidFinishLoadingAd:self];
    }
}

- (void)JSClientDidReceiveFailCommand:(LoopMeJSClient *)client
{
    NSError *error = [LoopMeError errorForStatusCode:LoopMeErrorCodeSpecificHost];
    LoopMeLogInfo(@"Ad failed to load: %@", error);
    [self.webViewTimeOutTimer invalidate];
    _webViewTimeOutTimer = nil;
    if ([self.delegate respondsToSelector:@selector(adDisplayController:didFailToLoadAdWithError:)]) {
        [self.delegate adDisplayController:self didFailToLoadAdWithError:error];
    }
}

- (void)JSClientDidReceiveCloseCommand:(LoopMeJSClient *)client
{
    if ([self.delegate respondsToSelector:@selector(adDisplayControllerShouldCloseAd:)]) {
        [self.delegate adDisplayControllerShouldCloseAd:self];
    }
}

- (void)JSClientDidReceiveVibrateCommand:(LoopMeJSClient *)client
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - VideoClientDelegate

- (id<LoopMeJSCommunicatorProtocol>)JSCommunicator
{
    return self.JSClient;
}

- (void)videoClientDidReachEnd:(LoopMeVideoClient *)client
{
    LoopMeLogInfo(@"Video ad did reach end");
    if ([self.delegate respondsToSelector:
         @selector(adDisplayControllerVideoDidReachEnd:)]) {
        [self.delegate adDisplayControllerVideoDidReachEnd:self];
    }
}

- (void)videoClient:(LoopMeVideoClient *)client didFailToLoadVideoWithError:(NSError *)error
{
    LoopMeLogInfo(@"Did fail to load video ad");
    if ([self.delegate respondsToSelector:
         @selector(adDisplayController:didFailToLoadAdWithError:)]) {
        [self.delegate adDisplayController:self didFailToLoadAdWithError:error];
    }
}

- (void)videoClient:(LoopMeVideoClient *)client setupLayer:(AVPlayerLayer *)layer
{
    layer.frame = self.delegate.containerView.bounds;
    [[self.delegate containerView].layer insertSublayer:layer below:self.webView.layer];
}

@end
