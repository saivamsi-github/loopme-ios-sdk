//
//  LoopMeVideoJSTransportProtocol.h
//  LoopMeSDK
//
//  Created by Dmitriy on 10/28/14.
//
//

#ifndef LoopMeSDK_LoopMeJSCommunicatorProtocol_h
#define LoopMeSDK_LoopMeJSCommunicatorProtocol_h

@protocol LoopMeJSCommunicatorProtocol <NSObject>

- (void)setCurrentTime:(CGFloat)currentTime;
- (void)setDuration:(CGFloat)fullDuration;
- (void)setState:(NSString *)state;
- (void)setShake;

@end

#endif
