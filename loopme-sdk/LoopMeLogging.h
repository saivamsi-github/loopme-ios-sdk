//
//  LoopMeLogging.h
//  LoopMeSDK
//
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    LoopMeLogLevelError        = 0,
    LoopMeLogLevelDebug        = 10,
    LoopMeLogLevelInfo        = 20,
    LoopMeLogLevelOff        = 30,
} LoopMeLogLevel;

LoopMeLogLevel getLoopMeLogLevel(void);
void setLoopMeLogLevel(LoopMeLogLevel level);

void LoopMeLogDebug(NSString *format, ...);
void LoopMeLogInfo(NSString *format, ...);
void LoopMeLogError(NSString *format, ...);
