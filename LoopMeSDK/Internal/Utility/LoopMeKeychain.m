//
//  LoopMeKeychain.m
//
//  Created by Bohdan on 2/29/16.
//  Copyright (c) 2010-2016 Sam Soffes, http://soff.es

#import "LoopMeKeychain.h"

NSString *const kLoopMeKeychainErrorDomain = @"com.loopme.loopmekeychain";

NSString *const kLoopMeKeychainAccountKey = @"acct";
NSString *const kLoopMeKeychainCreatedAtKey = @"cdat";
NSString *const kLoopMeKeychainClassKey = @"labl";
NSString *const kLoopMeKeychainDescriptionKey = @"desc";
NSString *const kLoopMeKeychainLabelKey = @"labl";
NSString *const kLoopMeKeychainLastModifiedKey = @"mdat";
NSString *const kLoopMeKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE  
CFTypeRef LoopMeKeychainAccessibilityType = NULL;
#endif

@interface LoopMeKeychain ()

+ (NSMutableDictionary *)_queryForService:(NSString *)service account:(NSString *)account;
@end


@implementation LoopMeKeychain

#pragma mark - Getting Passwords

+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account {
	return [self passwordForService:service account:account error:nil];
}


+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    NSData *data = [self passwordDataForService:service account:account error:error];
	if (data.length > 0) {
		NSString *string = [[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding];
		return string;
	}
	
	return nil;
}

+ (NSData *)passwordDataForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    OSStatus status = LoopMeKeychainErrorBadArguments;
	if (!service || !account) {
		if (error) {
			*error = [NSError errorWithDomain:kLoopMeKeychainErrorDomain code:status userInfo:nil];
		}
		return nil;
	}
	
	CFTypeRef result = NULL;	
	NSMutableDictionary *query = [self _queryForService:service account:account];

	[query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	[query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
	
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kLoopMeKeychainErrorDomain code:status userInfo:nil];
		return nil;
	}
	return (__bridge_transfer NSData *)result;
}


#pragma mark - Deleting Passwords

+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account {
	return [self deletePasswordForService:service account:account error:nil];
}


+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
	OSStatus status = LoopMeKeychainErrorBadArguments;
	if (service && account) {
		NSMutableDictionary *query = [self _queryForService:service account:account];
		status = SecItemDelete((__bridge CFDictionaryRef)query);
	}
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kLoopMeKeychainErrorDomain code:status userInfo:nil];
	}
	return (status == noErr);
    
}


#pragma mark - Setting Passwords

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account {
	return [self setPassword:password forService:service account:account error:nil];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    return [self setPasswordData:data forService:service account:account error:error];
}


+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    OSStatus status = LoopMeKeychainErrorBadArguments;
	if (password && service && account) {
        [self deletePasswordForService:service account:account];
        NSMutableDictionary *query = [self _queryForService:service account:account];
		[query setObject:password forKey:(__bridge id)kSecValueData];
		
#if __IPHONE_4_0 && TARGET_OS_IPHONE
		if (LoopMeKeychainAccessibilityType) {
			[query setObject:(id)[self accessibilityType] forKey:(__bridge id)kSecAttrAccessible];
		}
#endif
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
	}
	if (status != noErr && error != NULL) {
		*error = [NSError errorWithDomain:kLoopMeKeychainErrorDomain code:status userInfo:nil];
	}
	return (status == noErr);
}


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE 
+ (CFTypeRef)accessibilityType {
	return LoopMeKeychainAccessibilityType;
}


+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
	CFRetain(accessibilityType);
	if (LoopMeKeychainAccessibilityType) {
		CFRelease(LoopMeKeychainAccessibilityType);
	}
	LoopMeKeychainAccessibilityType = accessibilityType;
}
#endif


#pragma mark - Private

+ (NSMutableDictionary *)_queryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
    if (service) {
		[dictionary setObject:service forKey:(__bridge id)kSecAttrService];
	}
	
    if (account) {
		[dictionary setObject:account forKey:(__bridge id)kSecAttrAccount];
	}
	
    return dictionary;
}

@end
