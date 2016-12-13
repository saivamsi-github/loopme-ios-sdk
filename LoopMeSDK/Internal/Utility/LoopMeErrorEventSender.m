//
//  LoopMeErrorSender.m
//
//  Created by Bohdan on 12/11/15.
//  Copyright © 2015 LoopMe. All rights reserved.
//

#import "LoopMeErrorEventSender.h"
#import "LoopMeGlobalSettings.h"
#import "LoopMeDefinitions.h"

@implementation LoopMeErrorEventSender

+ (void)sendEventTo:(NSString *)url withError:(LoopMeEventErrorType)errorType {
    NSString *errorTypeParameter;
    switch (errorType) {
        case LoopMeEventErrorType504:
            errorTypeParameter = @"504";
            break;
            
        case LoopMeEventErrorTypeBadAssets:
            errorTypeParameter = @"bad_asset";
            break;
            
        case LoopMeEventErrorTypeTimeOut:
            errorTypeParameter = @"time_out";
            break;
            
        case LoopMeEventErrorTypeWrongRedirect:
            errorTypeParameter = @"wrong_redirect";
            break;
            
        default:
            break;
    }
    
    if (!url) {
        url = @"https://track.loopme.me/sj/tr?et=ERROR&id=3fcdd1c4f102b8b8&sv=%@&error_type=%@";
    }
    
    NSString *finalURL = [NSString stringWithFormat:url, LOOPME_SDK_VERSION, errorTypeParameter];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:finalURL]] resume];
}

@end
