//
//  LoopMeJSClient.h
//  LoopMeSDK
//
//  Created by Dmitriy on 10/24/14.
//
//

#import "LoopMeJSCommunicatorProtocol.h"

@class LoopMeJSClient;

@protocol LoopMeVideoCommunicatorProtocol;
@protocol LoopMeJSClientDelegate;

static NSString *const kLoopMeNamespaceWebview = @"webview";
static NSString *const kLoopMeNamespaceVideo = @"video";

extern const struct LoopMeEventStruct
{
    __unsafe_unretained NSString *state;
    __unsafe_unretained NSString *isVisible;
    __unsafe_unretained NSString *duration;
    __unsafe_unretained NSString *currentTime;
    __unsafe_unretained NSString *shake;
    __unsafe_unretained NSString *isNativeCallFinished;
} LoopMeEvent;

extern const struct LoopMeWebViewStateStruct
{
    __unsafe_unretained NSString *visible;
    __unsafe_unretained NSString *hidden;
    __unsafe_unretained NSString *closed;
} LoopMeWebViewState;

@interface LoopMeJSClient : NSObject
<
    LoopMeJSCommunicatorProtocol
>

- (instancetype)initWithDelegate:(id<LoopMeJSClientDelegate>)deleagate;
- (BOOL)shouldInterceptURL:(NSURL *)URL;
- (void)processURL:(NSURL *)URL;
- (void)executeEvent:(NSString *)event forNamespace:(NSString *)ns param:(NSObject *)param;
- (void)executeEvent:(NSString *)event forNamespace:(NSString *)ns param:(NSObject *)param paramBOOL:(BOOL)isBOOL;

@end

@protocol LoopMeJSClientDelegate <NSObject>

- (UIWebView *)webViewTransport;
- (id<LoopMeVideoCommunicatorProtocol>)videoCommunicator;
- (void)JSClientDidReceiveSuccessCommand:(LoopMeJSClient *)client;
- (void)JSClientDidReceiveFailCommand:(LoopMeJSClient *)client;
- (void)JSClientDidReceiveCloseCommand:(LoopMeJSClient *)client;
- (void)JSClientDidReceiveVibrateCommand:(LoopMeJSClient *)client;

@end


