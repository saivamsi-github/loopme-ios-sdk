//
//  LoopMeGlobalSettings.h
//  LoopMeSDK
//
//  Created by Kogda Bogdan on 6/16/15.
//
//

#import <Foundation/Foundation.h>

@interface LoopMeGlobalSettings : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign, getter = isDoNotLoadVideoWithoutWiFi) BOOL doNotLoadVideoWithoutWiFi;
@property (nonatomic, assign, getter = isLiveDebugEnabled) BOOL liveDebugEnabled;
@property (nonatomic, assign, getter = isPreload25Enabled) BOOL preload25;
@property (nonatomic, strong) NSString *errorLinkFormat;
@property (nonatomic, assign, getter = isV360) BOOL v360;

@end
