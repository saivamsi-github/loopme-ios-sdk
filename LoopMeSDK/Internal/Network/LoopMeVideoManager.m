//
//  LoopMeVideoManager.m
//  LoopMeSDK
//
//  Created by Kogda Bogdan on 2/19/15.
//
//

#import <stdlib.h>
#import "LoopMeVideoManager.h"
#import "LoopMeError.h"

NSInteger const videoLoadTimeOutInterval = 180;

@interface LoopMeVideoManager ()
<
    NSURLConnectionDataDelegate
>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *videoData;
@property (nonatomic, strong) NSString *videoPath;

- (NSString *)assetsDirectory;

@end

@implementation LoopMeVideoManager

#pragma mark - Life Cycle

- (instancetype)initWithVideoPath:(NSString *)videoPath delegate:(id<LoopMeVideoManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _videoPath = videoPath;
        _delegate = delegate;
        [self clearOldCacheFiles];
    }
    return self;
}

#pragma mark - Private

- (NSString *)assetsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    return [documentsDirectory stringByAppendingPathComponent:@"lm_assets/"];
}

#pragma mark - Public

- (void)loadVideoWithURL:(NSURL *)URL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:videoLoadTimeOutInterval];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancel
{
    [self.connection cancel];
    self.connection = nil;
}

- (void)clearOldCacheFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *directoryPath = self.assetsDirectory;
    NSDirectoryEnumerator* enumerator = [fm enumeratorAtPath:directoryPath];
    
    NSString* file;
    while (file = [enumerator nextObject]) {

        NSDate *creationDate = [[fm attributesOfItemAtPath:[directoryPath stringByAppendingPathComponent:file] error:nil] fileCreationDate];
        NSDate *yesterDay = [[NSDate date] dateByAddingTimeInterval:(-1*32*60*60)];
        
        if ([creationDate compare:yesterDay] == NSOrderedAscending) {
            [fm removeItemAtPath:[directoryPath stringByAppendingPathComponent:file] error:nil];
        }
    }
}


- (void)cacheVideoData:(NSData *)data
{
    NSString *directoryPath = self.assetsDirectory;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
    
    NSString *dataPath = [directoryPath stringByAppendingPathComponent:self.videoPath];
    NSURL *URL = [NSURL fileURLWithPath:dataPath];
    
    if([data writeToFile:dataPath atomically:NO]) {
        [self.delegate videoManager:self didLoadVideo:URL];
    } else {
        [self.delegate videoManager:self didFailLoadWithError:[LoopMeError errorForStatusCode:LoopMeErrorCodeWrirtingToDisk]];
    }
}

- (BOOL)hasCachedURL:(NSURL *)URL
{
    if (!self.videoPath) {
        return NO;
    }
    
    NSString *videoPath = [[self assetsDirectory] stringByAppendingPathComponent:URL.lastPathComponent];
    return [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
}

- (NSURL *)videoFileURL
{
    NSString *dataPath = [[self assetsDirectory] stringByAppendingPathComponent:self.videoPath];
    NSURL *URL = [NSURL fileURLWithPath:dataPath];
    return URL;
}
#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode != 200) {
            [connection cancel];
            [self.delegate videoManager:self didFailLoadWithError:[LoopMeError errorForStatusCode:statusCode]];
            return;
        }
    }
    self.videoData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.videoData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate videoManager:self didFailLoadWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self cacheVideoData:[NSData dataWithData:self.videoData]];
    self.videoData = nil;
    self.connection = nil;
}


@end
