//
//  OTIIdentityCore.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIIdentityCore.h"
#import "OTIServiceDefines.h"
#import "OTIEncryption.h"
#import "OTIServiceDefines.h"
#import "OTIAvatarImageProcessor.h"

@interface OTIIdentityCore (){
    NSString    *_userName;
    NSString    *_userEmail;
    
    UIImage     *_userAvatar;
}

@end

@implementation OTIIdentityCore

+ (OTIIdentityCore *)sharedCore
{
    static OTIIdentityCore *identityCore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identityCore = [[self alloc]init];
    });
    
    return identityCore;
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([[NSUserDefaults standardUserDefaults]objectForKey:@"username"]) {
            _userName = [[NSUserDefaults standardUserDefaults]objectForKey:@"username"];
            _userEmail = [[NSUserDefaults standardUserDefaults]objectForKey:@"email"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"avatar.png"];
            _userAvatar = [[UIImage alloc]initWithContentsOfFile:filePath];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (!_userAvatar) {
                    NSMutableString *nameInitial = [[NSMutableString alloc]init];
                    NSArray *names = [[[OTIIdentityCore sharedCore] userName] componentsSeparatedByString:@" "];
                    for (NSString *name in names) {
                        if (name.length > 0) {
                            [nameInitial appendString:[name substringToIndex:1]];
                        }
                    }
                    _userAvatar = [OTIAvatarImageProcessor generateImageForInitial:nameInitial withRadius:50.f];
                }
            });
        }
    }
    return self;
}

- (void)setUpUserWithUsername:(NSString *)name email:(NSString *)email
{
    _userName = [name copy];
    _userEmail = [email copy];
    
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUpUserAvatar:(UIImage *)image
{
    _userAvatar = [image copy];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"avatar.png"];
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
}

- (NSString *)userName
{
    return _userName;
}

- (UIImage *)userAvatar
{
    return _userAvatar;
}

- (BOOL)shouldUseHashInsteadOfRealAddress
{
    return NO;
}

- (NSData *)userUUID
{
    return nil;
}

- (NSData *)encryptedUserInfo
{
    if (_userEmail) {
        NSDictionary *dict = @{@"u": _userName,@"e": _userEmail};
        NSData *unencryptedData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        NSData *encryptedData = [OTIEncryption encryptedDataFromData:unencryptedData withKey:SHARED_KEY];
        return encryptedData;
    }
    
    return nil;
}

- (void)authenticateCentral:(NSString *)uuid withData:(NSData *)data
{
    
}

- (BOOL)authenticatedCentral:(NSString *)uuid
{
    return NO;
}

@end
