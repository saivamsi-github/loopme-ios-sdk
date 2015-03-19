//
//  LoopMeUtility.h
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import "LoopMeLogging.h"

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

