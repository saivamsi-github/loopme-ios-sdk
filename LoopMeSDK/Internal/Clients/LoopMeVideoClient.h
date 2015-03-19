//
//  LoopMeVideoClient.h
//  LoopMeSDK
//
//  Created by Kogda Bogdan on 10/20/14.
//
//

#import "LoopMeVideoCommunicatorProtocol.h"

@class LoopMeVideoClient;
@class AVPlayerLayer;

@protocol LoopMeJSCommunicatorProtocol;
@protocol LoopMeVideoClientDelegate;

extern const struct LoopMeVideoStateStruct
{
    __unsafe_unretained NSString *ready;
    __unsafe_unretained NSString *completed;
    __unsafe_unretained NSString *buffering;
    __unsafe_unretained NSString *playing;
    __unsafe_unretained NSString *paused;
    __unsafe_unretained NSString *broken;
} LoopMeVideoState;

@interface LoopMeVideoClient : NSObject
<
    LoopMeVideoCommunicatorProtocol
>
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

- (instancetype)initWithDelegate:(id<LoopMeVideoClientDelegate>)delegate;
- (void)adjustLayerToFrame:(CGRect)frame;
- (void)cancel;

@end

@protocol LoopMeVideoClientDelegate <NSObject>

- (id<LoopMeJSCommunicatorProtocol>)JSCommunicator;
- (void)videoClient:(LoopMeVideoClient *)client setupLayer:(AVPlayerLayer *)layer;
- (void)videoClientDidReachEnd:(LoopMeVideoClient *)client;
- (void)videoClient:(LoopMeVideoClient *)client didFailToLoadVideoWithError:(NSError *)error;

@end