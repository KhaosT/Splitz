//
//  OTIIdentityCore.h
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTIIdentityCore : NSObject

+ (OTIIdentityCore *)sharedCore;

- (void)setUpUserWithUsername:(NSString *)name email:(NSString *)email;
- (void)setUpUserAvatar:(UIImage *)image;

- (NSString *)userName;
- (UIImage *)userAvatar;

- (BOOL)shouldUseHashInsteadOfRealAddress;
- (NSData *)userUUID;

- (NSData *)encryptedUserInfo;
- (void)authenticateCentral:(NSString *)uuid withData:(NSData *)data;
- (BOOL)authenticatedCentral:(NSString *)uuid;

@end
