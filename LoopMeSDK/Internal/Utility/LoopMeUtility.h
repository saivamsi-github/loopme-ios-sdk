//
//  LoopMeUtility.h
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2012 Ciklum. All rights reserved.
//

#import "LoopMeInterstitial.h"

@interface LoopMeUtility : NSObject

+ (NSString *)storeItemIdentifierForURL:(NSURL *)URL;

@end

@interface NSString (LoopMeAdditions)

- (NSString *)URLEncodedString;

@end
