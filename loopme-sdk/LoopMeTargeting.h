//
//  LoopMeTargeting.h
//  LoopMeSDK
//
//  Copyright (c) 2014 LoopMe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSUInteger, LoopMeGender) {
    LoopMeGenderUnknown,
    LoopMeGenderMale,
    LoopMeGenderFemale
};

@interface LoopMeTargeting : NSObject

@property (nonatomic) CLLocation *location;
@property (nonatomic) NSString *keywords;
@property (nonatomic, assign) NSInteger yearOfBirth;
@property (nonatomic, assign) LoopMeGender gender;

- (id)initWithLocation:(CLLocation *)location keywords:(NSString *)keywords yearOfBirth:(NSInteger)yob gender:(LoopMeGender) gender;
- (id)initWithLocation:(CLLocation *)location;
- (id)initWithKeywords:(NSString *)keywords;
- (id)initWithGender:(LoopMeGender) gender;

@end
