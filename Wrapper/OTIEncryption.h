//
//  OTIEncryption.h
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTIEncryption : NSObject

+ (NSData *)encryptedDataFromData:(NSData *)data withKey:(NSString *)key;
+ (NSData *)decryptedDataFromData:(NSData *)data withKey:(NSString *)key;

@end
