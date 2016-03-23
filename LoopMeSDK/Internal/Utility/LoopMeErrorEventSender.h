//
//  LoopMeErrorSender.h
//
//  Created by Bohdan on 12/11/15.
//  Copyright © 2015 LoopMe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LoopMeEventErrorType) {
    LoopMeEventErrorTypeBadAssets,
    LoopMeEventErrorType504,
    LoopMeEventErrorTypeTimeOut,
    LoopMeEventErrorTypeWrongRedirect,
};


@interface LoopMeErrorEventSender : NSObject

+ (void)sendEventTo:(NSString *)url withError:(LoopMeEventErrorType)errorType;

@end
