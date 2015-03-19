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

const NSTimeInterval kLoopMeAdRequestTimeOutInterval = 20.0;

@interface LoopMeServerCommunicator ()

@property (nonatomic, assign, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *userAgent;

- (NSURLRequest *)adRequestForURL:(NSURL *)URL;

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
    [self.connection cancel];
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

- (NSURLRequest *)adRequestForURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:kLoopMeAdRequestTimeOutInterval];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    return request;
}

#pragma mark - Public

- (void)loadURL:(NSURL *)URL
{
    [self cancel];
    self.URL = URL;
    self.connection = [NSURLConnection connectionWithRequest:[self adRequestForURL:URL]
                                                    delegate:self];
    self.loading = YES;
}

- (void)cancel
{
    self.loading = NO;
    [self.connection cancel];
    self.connection = nil;
    self.responseData = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode != 200) {
            [connection cancel];
            self.loading = NO;
            [self.delegate serverCommunicator:self didFailWithError:[LoopMeError errorForStatusCode:statusCode]];
            return;
        }
    }
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.loading = NO;
    [self.delegate serverCommunicator:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    LoopMeAdConfiguration *configuration = [[LoopMeAdConfiguration alloc] initWithData:[NSData dataWithData:self.responseData]];
    self.responseData = nil;
    self.loading = NO;
    [self.delegate serverCommunicator:self didReceiveAdConfiguration:configuration];
}

@end
