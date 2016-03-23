//
//  LoopMeKeychain.m
//
//  Created by Bohdan on 2/29/16.
//  Copyright (c) 2010-2016 Sam Soffes, http://soff.es

#import <Foundation/Foundation.h>
#import <Security/Security.h>

/** Error codes that can be returned in NSError objects. */
typedef enum {
	/** No error. */
	LoopMeKeychainErrorNone = noErr,
	
	/** Some of the arguments were invalid. */
	LoopMeKeychainErrorBadArguments = -1001,
	
	/** There was no paLoopMeword. */
	LoopMeKeychainErrorNoPassword = -1002,
	
	/** One or more parameters passed internally were not valid. */
	LoopMeKeychainErrorInvalidParameter = errSecParam,
	
	/** Failed to allocate memory. */
	LoopMeKeychainErrorFailedToAllocated = errSecAllocate,
	
	/** No trust results are available. */
	LoopMeKeychainErrorNotAvailable = errSecNotAvailable,
	
	/** Authorization/Authentication failed. */
	LoopMeKeychainErrorAuthorizationFailed = errSecAuthFailed,
	
	/** The item already exists. */
	LoopMeKeychainErrorDuplicatedItem = errSecDuplicateItem,
	
	/** The item cannot be found.*/
	LoopMeKeychainErrorNotFound = errSecItemNotFound,
	
	/** Interaction with the Security Server is not allowed. */
	LoopMeKeychainErrorInteractionNotAllowed = errSecInteractionNotAllowed,
	
	/** Unable to decode the provided data. */
	LoopMeKeychainErrorFailedToDecode = errSecDecode
} LoopMeKeychainErrorCode;

extern NSString *const kLoopMeKeychainErrorDomain;

/** Account name. */
extern NSString *const kLoopMeKeychainAccountKey;

/**
 Time the item was created.
 
 The value will be a string.
 */
extern NSString *const kLoopMeKeychainCreatedAtKey;

/** Item class. */
extern NSString *const kLoopMeKeychainClassKey;

/** Item description. */
extern NSString *const kLoopMeKeychainDescriptionKey;

/** Item label. */
extern NSString *const kLoopMeKeychainLabelKey;

/** Time the item was last modified.
 
 The value will be a string.
 */
extern NSString *const kLoopMeKeychainLastModifiedKey;

/** Where the item was created. */
extern NSString *const kLoopMeKeychainWhereKey;

/**
 Simple wrapper for accessing accounts, getting passwords, setting passwords, and deleting passwords using the system
 Keychain on Mac OS X and iOS.
 
 This was originally inspired by EMKeychain and SDKeychain (both of which are now gone) and SSKeychain. Thanks to the authors.
 */
@interface LoopMeKeychain : NSObject


///------------------------
/// @name Getting Passwords
///------------------------

/**
 Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't have a
 password for the given parameters.
 
 @param serviceName The service for which to return the corresponding password.
 
 @param account The account for which to return the corresponding password.
 
 @return Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't
 have a password for the given parameters.
 
 @see passwordForService:account:error:
 */
+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account;

/**
 Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't have a
 password for the given parameters.
 
 @param serviceName The service for which to return the corresponding password.
 
 @param account The account for which to return the corresponding password.
 
 @param error If accessing the password fails, upon return contains an error that describes the problem.
 
 @return Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't
 have a password for the given parameters.
 
 @see passwordForService:account:
 */
+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;

///-------------------------
/// @name Deleting Passwords
///-------------------------

/**
 Deletes a password from the Keychain.
 
 @param serviceName The service for which to delete the corresponding password.
 
 @param account The account for which to delete the corresponding password.
 
 @return Returns `YES` on success, or `NO` on failure.
 
 @see deletePasswordForService:account:error:
 */
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account;

/**
 Deletes a password from the Keychain.
 
 @param serviceName The service for which to delete the corresponding password.
 
 @param account The account for which to delete the corresponding password.
 
 @param error If deleting the password fails, upon return contains an error that describes the problem.
 
 @return Returns `YES` on success, or `NO` on failure.
 
 @see deletePasswordForService:account:
 */
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;


///------------------------
/// @name Setting Passwords
///------------------------

/**
 Sets a password in the Keychain.
 
 @param password The password to store in the Keychain.
 
 @param serviceName The service for which to set the corresponding password.
 
 @param account The account for which to set the corresponding password.
 
 @return Returns `YES` on success, or `NO` on failure.
 
 @see setPassword:forService:account:error:
 */
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account;

/**
 Sets a password in the Keychain.
 
 @param password The password to store in the Keychain.
 
 @param serviceName The service for which to set the corresponding password.
 
 @param account The account for which to set the corresponding password.
 
 @param error If setting the password fails, upon return contains an error that describes the problem.
 
 @return Returns `YES` on success, or `NO` on failure.
 
 @see setPassword:forService:account:
 */
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;


///--------------------
/// @name Configuration
///--------------------

#if __IPHONE_4_0 && TARGET_OS_IPHONE
/**
 Returns the accessibility type for all future passwords saved to the Keychain.
 
 @return Returns the accessibility type.
 
 The return value will be `NULL` or one of the "Keychain Item Accessibility Constants" used for determining when a
 keychain item should be readable.
 
 @see accessibilityType
 */
+ (CFTypeRef)accessibilityType;

/**
 Sets the accessibility type for all future passwords saved to the Keychain.
 
 @param accessibilityType One of the "Keychain Item Accessibility Constants" used for determining when a keychain item
 should be readable.
 
 If the value is `NULL` (the default), the Keychain default will be used.
 
 @see accessibilityType
 */
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType;
#endif

@end
