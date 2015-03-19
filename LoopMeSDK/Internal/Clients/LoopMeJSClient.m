//
//  LoopMeJSClient.m
//  LoopMeSDK
//
//  Created by Dmitriy on 10/24/14.
//
//

#import <AVFoundation/AVFoundation.h>

#import "LoopMeAdWebView.h"
#import "LoopMeDefinitions.h"
#import "LoopMeJSClient.h"
#import "LoopMeVideoCommunicatorProtocol.h"
#import "NSURL+LoopMeAdditions.h"
#import "LoopMeLogging.h"

NSString * const _kLoopMeURLScheme = @"loopme";

// Commands
NSString * const _kLoopMeSuccessCommand = @"success";
NSString * const _kLoopMeFailLoadCommand = @"fail";
NSString * const _kLoopMeCloseCommand = @"close";
NSString * const _kLoopMePlayCommand = @"play";
NSString * const _kLoopMeStopCommand = @"pause";
NSString * const _kLoopMeMuteCommand = @"mute";
NSString * const _kLoopMeLoadCommand = @"load";
NSString * const _kLoopMeVibrateCommand = @"vibrate";
NSString * const _kLoopMeEnableStretchCommand = @"enableStretching";
NSString * const _kLoopMeDisableStretchCommand = @"disableStretching";

typedef NS_ENUM(NSUInteger, LoopMeJSParamType)
{
    LoopMeJSParamTypeNumber,
    LoopMeJSParamTypeString,
    LoopMeJSParamTypeBoolean
};

// Events
const struct LoopMeEventStruct LoopMeEvent =
{
    .isVisible = @"isVisible",
    .state = @"state",
    .duration = @"duration",
    .currentTime = @"currentTime",
    .shake = @"shake",
    .isNativeCallFinished = @"isNativeCallFinished"
};

const struct LoopMeWebViewStateStruct LoopMeWebViewState =
{
    .visible = @"VISIBLE",
    .hidden = @"HIDDEN",
    .closed = @"CLOSED"
};

@interface LoopMeJSClient ()

@property (nonatomic, weak) id<LoopMeJSClientDelegate> delegate;
@property (nonatomic, strong, readonly) id<LoopMeVideoCommunicatorProtocol> videoClient;
@property (nonatomic, strong, readonly) UIWebView *webViewClient;

- (void)loadVideoWithParams:(NSDictionary *)params;
- (void)playVideoWithParams:(NSDictionary *)params;
- (void)pauseVideoWithParams:(NSDictionary *)params;
@end

@implementation LoopMeJSClient

#pragma mark - Life Cycle

- (instancetype)initWithDelegate:(id<LoopMeJSClientDelegate>)deleagate
{
    if (self = [super init]) {
        _delegate = deleagate;
    }
    return self;
}

#pragma mark - Properties

- (id<LoopMeVideoCommunicatorProtocol>)videoClient
{
    return [self.delegate videoCommunicator];
}

- (UIWebView *)webViewClient
{
    return [self.delegate webViewTransport];
}

#pragma mark - Private

- (void)loadVideoWithParams:(NSDictionary *)params
{
    NSString *videoSource = params[@"src"];
    [self.videoClient loadWithURL:[NSURL URLWithString:[videoSource stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (void)playVideoWithParams:(NSDictionary *)params
{
    NSString *time = params[@"currentTime"];
    double timeToPlay = (time) ? [time doubleValue] : -1;
    [self.videoClient playFromTime:timeToPlay];
}

- (void)pauseVideoWithParams:(NSDictionary *)params
{
    NSString *time = params[@"currentTime"];
    double timeToPause = (time) ? [time doubleValue] : -1;
    [self.videoClient pauseOnTime:timeToPause];
}

- (void)muteVideoWithParams:(NSDictionary *)params
{
    NSString *muteString = params[@"mute"];
    BOOL mute = [muteString isEqual:@"true"] ? YES : NO;
    [self.videoClient setMute:mute];
}

#pragma mark JS Commands

- (void)processCommand:(NSString *)command forNamespace:(NSString *)ns withParams:(NSDictionary *)params
{
    if ([ns isEqualToString:kLoopMeNamespaceWebview]) {
        [self processWebViewCommand:command withParams:params];
    } else if ([ns isEqualToString:kLoopMeNamespaceVideo]) {
        [self processVideoCommand:command withParams:params];
    } else {
        LoopMeLogDebug(@"Namespace: %@ is not supported", ns);
    }
}

- (void)processWebViewCommand:(NSString *)command withParams:(NSDictionary *)params
{
    if ([command isEqualToString:_kLoopMeSuccessCommand]) {
        [self.delegate JSClientDidReceiveSuccessCommand:self];
    } else if ([command isEqualToString:_kLoopMeFailLoadCommand]) {
        [self.delegate JSClientDidReceiveFailCommand:self];
    } else if ([command isEqualToString:_kLoopMeCloseCommand]) {
        [self.delegate JSClientDidReceiveCloseCommand:self];
    } else if ([command isEqualToString:_kLoopMeVibrateCommand]) {
        [self.delegate JSClientDidReceiveVibrateCommand:self];
    } else {
        LoopMeLogDebug(@"JS command: %@ for namespace: %@ is not supported", command, @"webview");
    }
}

- (void)processVideoCommand:(NSString *)command withParams:(NSDictionary *)params
{
    if ([command isEqualToString:_kLoopMeLoadCommand]) {
        [self loadVideoWithParams:params];
    } else if ([command isEqualToString:_kLoopMePlayCommand]) {
        [self playVideoWithParams:params];
    } else if ([command isEqualToString:_kLoopMeStopCommand]) {
        [self pauseVideoWithParams:params];
    } else if ([command isEqualToString:_kLoopMeMuteCommand]) {
        [self muteVideoWithParams:params];
    } else if ([command isEqualToString:_kLoopMeEnableStretchCommand]) {
        [self.videoClient setGravity:AVLayerVideoGravityResize];
    } else if ([command isEqualToString:_kLoopMeDisableStretchCommand]) {
        [self.videoClient setGravity:AVLayerVideoGravityResizeAspect];
    } else {
        LoopMeLogDebug(@"JS command: %@ for namespace: %@ is not supported", command, @"video");
    }
}

#pragma mark JS Events

- (NSString *)makeEventStringForEvent:(NSString *)event namespace:(NSString *)ns withParam:(NSObject *)param paramBOOL:(BOOL)isBOOL
{
    if (isBOOL == YES) {
        param = [(NSNumber *)param boolValue] == YES ? @"true" : @"false";
    } else if ([param isKindOfClass:[NSString class]]) {
        param = [NSString stringWithFormat:@"\"%@\"", param];
    }
    NSString *eventString = [NSString stringWithFormat:@"L.bridge.set(\"%@\",{%@:%@})", ns, event, param];
    return eventString;
}

#pragma mark - Public

- (void)executeEvent:(NSString *)event forNamespace:(NSString *)ns param:(NSObject *)param
{
    [self executeEvent:event forNamespace:ns param:param paramBOOL:NO];
}

- (void)executeEvent:(NSString *)event forNamespace:(NSString *)ns param:(NSObject *)param paramBOOL:(BOOL)isBOOL
{
    NSString *eventString = [self makeEventStringForEvent:event namespace:ns withParam:param paramBOOL:isBOOL];
    [self.webViewClient stringByEvaluatingJavaScriptFromString:eventString];
}

- (BOOL)shouldInterceptURL:(NSURL *)URL
{
    return [URL.scheme.lowercaseString isEqualToString:_kLoopMeURLScheme];
}

- (void)processURL:(NSURL *)URL
{
    NSString *ns = URL.host;
    NSString *command = URL.lastPathComponent;
    NSDictionary *params = [URL lm_toDictionary];
    LoopMeLogDebug(@"Processing JS command: %@, namespace: %@, params: %@", command, ns, params);
    [self processCommand:command forNamespace:ns withParams:params];
}

#pragma mark - LoopMeJSTransportProtocol

- (void)setState:(NSString *)state
{
    [self executeEvent:LoopMeEvent.state forNamespace:kLoopMeNamespaceVideo param:state];
}

- (void)setDuration:(CGFloat)fullDuration
{
    [self executeEvent:LoopMeEvent.duration forNamespace:kLoopMeNamespaceVideo param:[NSNumber numberWithFloat:fullDuration]];
}

- (void)setCurrentTime:(CGFloat)currentTime
{
    [self executeEvent:LoopMeEvent.currentTime forNamespace:kLoopMeNamespaceVideo param:[NSNumber numberWithFloat:currentTime]];
}

- (void)setShake
{
    [self executeEvent:LoopMeEvent.shake forNamespace:kLoopMeNamespaceWebview param:@YES paramBOOL:YES];
}
@end
