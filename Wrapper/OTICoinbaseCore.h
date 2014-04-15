//
//  OTICoinbaseCore.h
//  Wrapper
//
//  Created by Khaos Tian on 4/13/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

#define COINBASE_CID @"CLIENT_ID"
#define COINBASE_CST @"CLIENT_SEC"
#define COINBASE_KEYCHAIN_SERVICE @"org.oltica.splitz.coinbase"

@interface OTICoinbaseCore : NSObject

+ (BOOL)coinbaseAuthorized;
+ (id)sharedCore;

- (void)deAuthorize;
- (NSURL *)urlForAuthorizing;
- (void)processOAuthWithCode:(NSString *)code;
- (void)sendMoneyToEmail:(NSString *)email forAmount:(NSString *)amount note:(NSString *)note completionBlock:(void (^)(NSDictionary *))completionBlock;

@end
