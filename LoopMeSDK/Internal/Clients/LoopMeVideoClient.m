//
//  LoopMeVideoClient.m
//  LoopMeSDK
//
//  Created by Kogda Bogdan on 10/20/14.
//
//
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LoopMeVideoClient.h"
#import "LoopMeDefinitions.h"
#import "LoopMeJSCommunicatorProtocol.h"
#import "LoopMeError.h"
#import "LoopMeVideoManager.h"

const struct LoopMeVideoStateStruct LoopMeVideoState =
{
    .ready = @"READY",
    .completed = @"COMPLETE",
    .buffering = @"BUFFERING",
    .playing = @"PLAYING",
    .paused = @"PAUSED",
    .broken = @"BROKEN"
};

static void *VideoControllerStatusObservationContext = &VideoControllerStatusObservationContext;
NSString * const kLoopMeVideoStatusKey = @"status";
const NSInteger kResizeOffset = 11;

@interface LoopMeVideoClient ()
<
    LoopMeVideoManagerDelegate
>
@property (nonatomic, weak) id<LoopMeVideoClientDelegate> delegate;
@property (nonatomic, weak) id<LoopMeJSCommunicatorProtocol> JSClient;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) NSTimer *loadingVideoTimer;
@property (nonatomic, strong) id playbackTimeObserver;
@property (nonatomic, strong) LoopMeVideoManager *videoManager;
@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, assign, getter = isShouldPlay) BOOL shouldPlay;
@property (nonatomic, assign, getter = isStatusSent) BOOL statusSent;
@property (nonatomic, strong) NSString *layerGravity;

- (AVPlayerLayer *)playerLayer;
- (NSURL *)currentAssetURLForPlayer:(AVPlayer *)player;
- (void)setupPlayerWithFileURL:(NSURL *)URL;
- (BOOL)playerHasBufferedURL:(NSURL *)URL;
- (void)unregisterObservers;
- (void)addTimerForCurrentTime;
- (void)routeChange:(NSNotification*)notification;
- (void)willEnterForeground:(NSNotification*)notification;
- (void)playerItemDidReachEnd:(id)object;

@end

@implementation LoopMeVideoClient

#pragma mark - Properties

- (AVPlayerLayer *)playerLayer
{
    if (_playerLayer == nil) {
        if (!self.player) {
            return nil;
        }
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        [_playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        _playerLayer.needsDisplayOnBoundsChange = YES;
        [self.delegate videoClient:self setupLayer:_playerLayer];
    }
    return _playerLayer;
}

- (id<LoopMeJSCommunicatorProtocol>)JSClient
{
    return [self.delegate JSCommunicator];
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem != playerItem) {
        if (_playerItem) {
            [_playerItem removeObserver:self forKeyPath:kLoopMeVideoStatusKey context:VideoControllerStatusObservationContext];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:_playerItem];
        }
        _playerItem = playerItem;
        if (_playerItem) {
            [_playerItem addObserver:self forKeyPath:kLoopMeVideoStatusKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:VideoControllerStatusObservationContext];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:_playerItem];
        }
    }
}

- (void)setPlayer:(AVPlayer *)player
{
    if(_player != player) {
        self.statusSent = NO;
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
        
        if (_player) {
            [_player removeTimeObserver:self.playbackTimeObserver];
        }
        _player = player;
        
        if (_player) {
            [self addTimerForCurrentTime];
            [self playerLayer];
            self.shouldPlay = NO;
        }
    }
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [self unregisterObservers];
    [self cancel];
}

- (instancetype)initWithDelegate:(id<LoopMeVideoClientDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(routeChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

    }
    return self;
}

#pragma mark - Private

- (NSURL *)currentAssetURLForPlayer:(AVPlayer *)player
{
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
        return nil;
    }
    return [(AVURLAsset *)currentPlayerAsset URL];
}

- (void)setupPlayerWithFileURL:(NSURL *)URL
{
    self.playerItem = [AVPlayerItem playerItemWithURL:URL];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
}

- (BOOL)playerHasBufferedURL:(NSURL *)URL
{
    if (!self.videoPath) {
        return NO;
    }
    return [[self currentAssetURLForPlayer:self.player].absoluteString hasSuffix:self.videoPath];
}

#pragma mark Observers & Timers

- (void)unregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)addTimerForCurrentTime
{
    CMTime interval = CMTimeMakeWithSeconds(0.1, NSEC_PER_USEC);
    __weak LoopMeVideoClient *selfWeak = self;
    self.playbackTimeObserver =
    [self.player addPeriodicTimeObserverForInterval:interval
                                              queue:NULL
                                         usingBlock:^(CMTime time) {
                                             float currentTime = (float)CMTimeGetSeconds(time);
                                             if (currentTime > 0 && selfWeak.isShouldPlay) {
                                                 [selfWeak.JSClient setCurrentTime:currentTime*1000];
                                             }
                                         }];
}

- (void)routeChange:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.isShouldPlay) {
                    [self.player play];
                }
            });
            break;
    }
}

- (void)willEnterForeground:(NSNotification*)notification
{
    if (!self.isStatusSent && self.player) {
        [self setupPlayerWithFileURL:[self currentAssetURLForPlayer:self.player]];
    }
}
#pragma mark Player state notification

- (void)playerItemDidReachEnd:(id)object
{
    [self.JSClient setState:LoopMeVideoState.completed];
    self.shouldPlay = NO;
    [self.delegate videoClientDidReachEnd:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    
    if (object == self.playerItem && [keyPath isEqualToString:kLoopMeVideoStatusKey]) {
        if (self.playerItem.status == AVPlayerItemStatusFailed) {
            [self.JSClient setState:LoopMeVideoState.broken];
            self.statusSent = YES;
        } else if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            if (!self.isStatusSent) {
                [self.JSClient setState:LoopMeVideoState.ready];
                [self.JSClient setDuration:CMTimeGetSeconds(self.player.currentItem.asset.duration)*1000];
                self.statusSent = YES;
            }
        }
    }
}


#pragma mark - Public

- (void)adjustLayerToFrame:(CGRect)frame
{
    self.playerLayer.frame = frame;
    if (self.layerGravity) {
        self.playerLayer.videoGravity = self.layerGravity;
        self.layerGravity = nil;
        return;
    }
    
    CGRect videoRect = [self.playerLayer videoRect];
    CGFloat k = 100;
    if (videoRect.size.width == self.playerLayer.bounds.size.width) {
        k = videoRect.size.height * 100 / self.playerLayer.bounds.size.height;
    } else if (videoRect.size.height == self.playerLayer.bounds.size.height) {
        k = videoRect.size.width * 100 / self.playerLayer.bounds.size.width;
    }
    
    if ((100 - floorf(k)) <= kResizeOffset) {
        [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
    }
}

- (void)cancel {
    [self.videoManager cancel];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    self.playerItem = nil;
    self.shouldPlay = NO;
}

#pragma mark - LoopMeJSVideoTransportProtocol

- (void)loadWithURL:(NSURL *)URL
{
    self.videoPath = URL.lastPathComponent;
    self.videoManager = [[LoopMeVideoManager alloc] initWithVideoPath:self.videoPath delegate:self];
    if ([self playerHasBufferedURL:URL]) {
        [self.JSClient setState:LoopMeVideoState.ready];
        [self.JSClient setDuration:CMTimeGetSeconds(self.player.currentItem.asset.duration)*1000];
    } else if ([self.videoManager hasCachedURL:URL]) {
        [self setupPlayerWithFileURL:[self.videoManager videoFileURL]];
    } else {
        [self.JSClient setState:LoopMeVideoState.buffering];
        [self.videoManager loadVideoWithURL:URL];
    }
}

- (void)setMute:(BOOL)mute
{
    self.player.volume = (mute) ? 0.0f : 1.0f;
}

- (void)seekToTime:(double)time
{
    if (time >= 0) {
        CMTime timeStruct = CMTimeMake(time, 1000);
        [self.player seekToTime:timeStruct
                toleranceBefore:kCMTimeZero
                 toleranceAfter:kCMTimePositiveInfinity];
    }
}

- (void)playFromTime:(double)time
{
    [self seekToTime:time];
    self.shouldPlay = YES;
    [self.JSClient setState:LoopMeVideoState.playing];
    [self.player play];
}

- (void)pauseOnTime:(double)time
{
    [self seekToTime:time];
    self.shouldPlay = NO;
    [self.JSClient setState:LoopMeVideoState.paused];
    [self.player pause];
}

- (void)setGravity:(NSString *)gravity
{
    self.layerGravity = gravity;
    if (self.playerLayer) {
        self.playerLayer.videoGravity = gravity;
    }
}

#pragma mark - LoopMeVideoManagerDelegate

- (void)videoManager:(LoopMeVideoManager *)videoManager didLoadVideo:(NSURL *)videoURL
{
    [self setupPlayerWithFileURL:videoURL];
}

- (void)videoManager:(LoopMeVideoManager *)videoManager didFailLoadWithError:(NSError *)error
{
    [self.JSClient setState:LoopMeVideoState.broken];
    [self.delegate videoClient:self didFailToLoadVideoWithError:error];
}

@end
