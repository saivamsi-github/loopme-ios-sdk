//
//  LoopMeServerURLBuilder.h
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 07/11/13.
//  Copyright (c) 2013 LoopMe. All rights reserved.
//

@class LoopMeTargeting;

@interface LoopMeServerURLBuilder : NSObject

+ (NSURL *)URLWithAppKey:(NSString *)appKey;
+ (NSURL *)URLWithAppKey:(NSString *)appKey targeting:(LoopMeTargeting *)targeting;
+ (NSURL *)URLWithAppKey:(NSString *)appKey targeting:(LoopMeTargeting *)targeting baseURL:(NSURL *)baseURL;

@end
