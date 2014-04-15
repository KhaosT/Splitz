//
//  OTIHashing.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIHashing.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation OTIHashing

+ (NSString *)hashValueForString:(NSString *)string
{
    NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    
	CC_SHA1([strData bytes], (CC_LONG)string.length, hash);
    
    NSMutableString *hashString = [[NSMutableString alloc]init];
    
	int i;
	for (i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [hashString appendFormat:@"%02x",hash[i]];
    }
    
    return hashString;
}

@end
