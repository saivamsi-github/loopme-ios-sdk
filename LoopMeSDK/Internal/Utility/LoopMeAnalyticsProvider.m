//
//  AnalyticsProvider.m
//
//  Created by Bohdan on 2/29/16.
//  Copyright © 2016 LoopMe. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "LoopMeAnalyticsProvider.h"
#import "LoopMeKeychain.h"
#import "LoopMeLogging.h"
#import "LoopMeServerURLBuilder.h"
#import "LoopMeIdentityProvider.h"

static NSString * const kLoopMeBackgroundAnalyticSessionID = @"com.loopme.backgrouns.session";

@interface LoopMeAnalyticsProvider ()

@property (nonatomic, strong) NSTimer *senderTimer;
@property (nonatomic, strong) NSURL *sendURL;
@property (nonatomic, strong) NSString *userAgent;

@end

@implementation LoopMeAnalyticsProvider

+ (instancetype)sharedInstance {
    static LoopMeAnalyticsProvider *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LoopMeAnalyticsProvider alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _sendInterval = 900;
        _analyticURLString = @"https://loopme.me/api/v2/events";
        
        UIBackgroundTaskIdentifier bgTask = 0;
        UIApplication  *app = [UIApplication sharedApplication];
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
        }];
        
        [self sendData];
        
        _senderTimer = [NSTimer
                 scheduledTimerWithTimeInterval:_sendInterval
                 target:self
                 selector:@selector(sendData)
                 userInfo:nil
                 repeats:YES];
    }
    
    return self;
}

- (NSString *)userAgent
{
    if (_userAgent == nil) {
        __weak LoopMeAnalyticsProvider *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        });
    }
    return _userAgent;
}

- (void)sendData {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:kLoopMeBackgroundAnalyticSessionID];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    self.sendURL = [NSURL URLWithString:[_analyticURLString stringByAppendingString:[NSString stringWithFormat:@"?et=INFO&vt=%@", [LoopMeIdentityProvider uniqueIdentifier]]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    
    NSString *params = [LoopMeServerURLBuilder packageIDs];
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[session dataTaskWithRequest:request] resume];
}

- (void)dealloc {
    [_senderTimer invalidate];
    _senderTimer = nil;
}

@end
