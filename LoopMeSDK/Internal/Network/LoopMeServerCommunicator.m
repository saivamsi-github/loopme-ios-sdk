//
//  LoopMeServerCommunicator.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

#import "LoopMeAdConfiguration.h"
#import "LoopMeDefinitions.h"
#import "LoopMeServerCommunicator.h"
#import "LoopMeError.h"
#import "LoopMeErrorEventSender.h"

const NSTimeInterval kLoopMeAdRequestTimeOutInterval = 20.0;

@interface LoopMeServerCommunicator ()

@property (nonatomic, assign, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong) NSURLSessionDataTask *sessionDataTask;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *userAgent;

@end

@implementation LoopMeServerCommunicator

#pragma mark - Properties

- (NSString *)userAgent
{
    if (_userAgent == nil) {
        _userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    }
    return _userAgent;
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [self.sessionDataTask cancel];
}

- (instancetype)initWithDelegate:(id<LoopMeServerCommunicatorDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Private

- (NSURLSession *)adSession
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    configuration.timeoutIntervalForRequest = kLoopMeAdRequestTimeOutInterval;
    configuration.HTTPAdditionalHeaders = @{@"User-Agent" : self.userAgent};
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    return session;
}

#pragma mark - Public

- (void)loadURL:(NSURL *)URL
{
    [self cancel];
    self.URL = URL;
    
    self.session = [self adSession];
    
    __weak LoopMeServerCommunicator *safeSelf = self;
    
    self.sessionDataTask = [self.session dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([response respondsToSelector:@selector(statusCode)]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode != 200) {
                if (statusCode == 504) {
                    [LoopMeErrorEventSender sendEventTo:nil withError:LoopMeEventErrorType504];
                }
                safeSelf.loading = NO;
                [safeSelf.delegate serverCommunicator:safeSelf didFailWithError:[LoopMeError errorForStatusCode:statusCode]];
                return;
            }
        }
        
        if (error) {
            safeSelf.loading = NO;
            if (error.code == NSURLErrorTimedOut) {
                [LoopMeErrorEventSender sendEventTo:nil withError:LoopMeEventErrorTypeTimeOut];
            }
            
            [safeSelf.delegate serverCommunicator:safeSelf didFailWithError:error];
            return;
        }
        
        LoopMeAdConfiguration *configuration = [[LoopMeAdConfiguration alloc] initWithData:[NSData dataWithData:data]];
        safeSelf.loading = NO;
        [safeSelf.delegate serverCommunicator:safeSelf didReceiveAdConfiguration:configuration];
    }];
    [self.sessionDataTask resume];
    
    self.loading = YES;
}

- (void)cancel
{
    self.loading = NO;
    [self.sessionDataTask cancel];
    self.sessionDataTask = nil;
}

@end
