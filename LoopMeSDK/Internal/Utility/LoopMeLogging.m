//
//  LoopMeUtility.h
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoopMeLogging.h"
#import "LoopMeServerURLBuilder.h"
#import "LoopMeGlobalSettings.h"

static NSString *kLoopMeUserDefaultsDateKey = @"loopMeLogWriteDate";
static LoopMeLogLevel logLevel = LoopMeLogLevelOff;

LoopMeLogLevel getLoopMeLogLevel()
{
    return logLevel;
}

void setLoopMeLogLevel(LoopMeLogLevel level)
{
    logLevel = level;
}

void LoopMeLogDebug(NSString *format, ...)
{
    if (logLevel <= LoopMeLogLevelDebug) {
        format = [NSString stringWithFormat:@"LoopMe: %@", format];
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

void LoopMeLogInfo(NSString *format, ...)
{
    if (logLevel <= LoopMeLogLevelInfo) {
        format = [NSString stringWithFormat:@"LoopMe: %@", format];
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

void LoopMeLogError(NSString *format, ...)
{
    if (logLevel <= LoopMeLogLevelError) {
        format = [NSString stringWithFormat:@"LoopMe: %@", format];
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

@interface LoopMeLoggingSender ()

@property (nonatomic) NSString *userAgent;
@property (nonatomic) NSInteger notReadyDisplayCount;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSMutableDictionary *properties;
@property (nonatomic) NSURLSession *session;

@end

@implementation LoopMeLoggingSender

static dispatch_semaphore_t sema; // The semaphore
static dispatch_once_t onceToken;

+ (LoopMeLoggingSender *)sharedInstance
{
    static LoopMeLoggingSender *sender = nil;
    if (!sender) {
        sender = [[LoopMeLoggingSender alloc] init];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLoopMeUserDefaultsDateKey];
    }
    return sender;
}

- (void)dealloc {
    [self.session finishTasksAndInvalidate];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        __weak LoopMeLoggingSender *weakSelf = self;
        dispatch_once(&onceToken, ^{
            // Initialize with count=1 (this is executed only once):
            sema = dispatch_semaphore_create(1);
            weakSelf.notReadyDisplayCount = 0;
            weakSelf.properties = [[NSMutableDictionary alloc] init];
        });
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

    }
    return self;
}

- (NSString *)userAgent
{
    if (_userAgent == nil) {
        __weak LoopMeLoggingSender *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        });
    }
    return _userAgent;
}

- (void)propertyTriggered:(NSString *)name value:(id)value {
    self.properties[@"name"] = value;
}

- (void)notReadyDisplay {
    _notReadyDisplayCount ++;
    [self sendLog];
}

- (void)setVideoLoadingTimeInterval:(NSTimeInterval)videoLoad
{
    _videoLoadingTimeInterval = videoLoad;
    [self sendLog];
}

- (void)sendLog
{
    if (![LoopMeGlobalSettings sharedInstance].isLiveDebugEnabled) {
        return;
    }
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLoopMeUserDefaultsDateKey];
    int intervall = (int) [lastDate timeIntervalSinceNow] / 60;
    if (abs(intervall) >= 3) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLoopMeUserDefaultsDateKey];
        if (dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER) == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self startSendingTask];
            });
        }
    }
}

- (void)startSendingTask
{
    NSURL *url = [NSURL URLWithString:@"https://loopme.me/api/errors"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *logs = @{@"loadingVideoTime" : @(self.videoLoadingTimeInterval), @"amountOfStoredVideos" : @([self storedVideos]), @"notReadyDisplay" : @(self.notReadyDisplayCount), @"doNotLoadVideoWithoutWiFi" : @([LoopMeGlobalSettings sharedInstance].isDoNotLoadVideoWithoutWiFi)};
    
    [self.properties addEntriesFromDictionary:logs];
    
    NSDictionary *params = @{@"msg" : @"sdk_debug", @"token" : [LoopMeServerURLBuilder parameterForUniqueIdentifier], @"package" : [LoopMeServerURLBuilder parameterForBundleIdentifier], @"debug_logs" : self.properties};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonData];
    
    NSURLSessionDataTask *postDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_semaphore_signal(sema);
        [self.properties removeAllObjects];
    }];
    
    [postDataTask resume];
}

- (NSInteger)storedVideos
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self assetsDirectory] error:nil].count;
}

- (NSString *)assetsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"lm_assets/"];
    return documentsDirectory;
}

@end