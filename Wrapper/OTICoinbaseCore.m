//
//  OTICoinbaseCore.m
//  Wrapper
//
//  Created by Khaos Tian on 4/13/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTICoinbaseCore.h"
#import "SSKeychain.h"
#import "AFHTTPRequestOperationManager.h"

@interface OTICoinbaseCore (){
    
}

@end

@implementation OTICoinbaseCore

+ (BOOL)coinbaseAuthorized
{
    if ([SSKeychain accountsForService:COINBASE_KEYCHAIN_SERVICE] && [[NSUserDefaults standardUserDefaults]boolForKey:@"Authorized"]) {
        return YES;
    }else{
        return NO;
    }
}

+ (id)sharedCore
{
    static OTICoinbaseCore *coinbaseCore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coinbaseCore = [[self alloc]init];
    });
    
    return coinbaseCore;
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([self checkExpireDate]) {
            [self initKeyRefresh];
        }
    }
    return self;
}

- (BOOL)checkExpireDate
{
    NSDate *expectDateToExpire = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExpireDate"];
    if (expectDateToExpire) {
        NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:expectDateToExpire];
        if (timeDiff > 0) {
            return YES;
        }
    }
    return NO;
}

- (NSURL *)urlForAuthorizing
{
    NSURL *authUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://coinbase.com/oauth/authorize?response_type=code&client_id=%@&redirect_uri=splitz://coinbase/",COINBASE_CID]];
    
    return authUrl;
}

- (void)deAuthorize
{
    NSArray *accounts = [SSKeychain accountsForService:COINBASE_KEYCHAIN_SERVICE];
    for (NSString *account in accounts) {
        [SSKeychain deletePasswordForService:COINBASE_KEYCHAIN_SERVICE account:account];
    }
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"ExpireDate"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"Authorized"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)sendMoneyToEmail:(NSString *)email forAmount:(NSString *)amount note:(NSString *)note completionBlock:(void (^)(NSDictionary *))completionBlock
{
    NSString *access_Token = [SSKeychain passwordForService:COINBASE_KEYCHAIN_SERVICE account:@"access_token"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *tokenUrl = [NSString stringWithFormat:@"https://coinbase.com/api/v1/transactions/send_money"];
    NSDictionary *parameters = @{@"access_token": access_Token,@"transaction":@{@"to": email, @"amount": amount, @"notes": note}};
    [manager POST:tokenUrl parameters:parameters constructingBodyWithBlock:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"%@",responseObject);
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  completionBlock(responseObject);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@",error);
              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Authorized"];
              [[NSUserDefaults standardUserDefaults] synchronize];
          }
     ];

}

- (void)initKeyRefresh
{
    NSString *refresh_Token = [SSKeychain passwordForService:COINBASE_KEYCHAIN_SERVICE account:@"refresh_token"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *tokenUrl = [NSString stringWithFormat:@"https://coinbase.com/oauth/token"];
    NSDictionary *parameters = @{@"grant_type": @"refresh_token",@"refresh_token": refresh_Token,@"client_id": COINBASE_CID, @"client_secret": COINBASE_CST};
    [manager POST:tokenUrl parameters:parameters constructingBodyWithBlock:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"%@",responseObject);
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  [SSKeychain setPassword:[responseObject objectForKey:@"access_token"] forService:COINBASE_KEYCHAIN_SERVICE account:@"access_token"];
                  [SSKeychain setPassword:[responseObject objectForKey:@"refresh_token"] forService:COINBASE_KEYCHAIN_SERVICE account:@"refresh_token"];
                  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                  NSDateComponents *components = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSCalendarUnitHour| NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:[NSDate date]];
                  [components setHour:components.hour + 2];
                  NSDate * date = [gregorian dateFromComponents:components];
                  [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"ExpireDate"];
                  [[NSUserDefaults standardUserDefaults] synchronize];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@",error);
              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Authorized"];
              [[NSUserDefaults standardUserDefaults] synchronize];
          }
     ];
}

- (void)processOAuthWithCode:(NSString *)code
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *tokenUrl = [NSString stringWithFormat:@"https://coinbase.com/oauth/token"];
    NSDictionary *parameters = @{@"grant_type": @"authorization_code",@"code": code,@"redirect_uri": @"splitz://coinbase/",@"client_id": COINBASE_CID, @"client_secret": COINBASE_CST};
    [manager POST:tokenUrl parameters:parameters constructingBodyWithBlock:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"%@",responseObject);
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  [SSKeychain setPassword:[responseObject objectForKey:@"access_token"] forService:COINBASE_KEYCHAIN_SERVICE account:@"access_token"];
                  [SSKeychain setPassword:[responseObject objectForKey:@"refresh_token"] forService:COINBASE_KEYCHAIN_SERVICE account:@"refresh_token"];
                  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                  NSDateComponents *components = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSCalendarUnitHour| NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:[NSDate date]];
                  [components setHour:components.hour + 2];
                  NSDate * date = [gregorian dateFromComponents:components];
                  [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"ExpireDate"];
                  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Authorized"];
                  [[NSUserDefaults standardUserDefaults] synchronize];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@",error);
              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Authorized"];
              [[NSUserDefaults standardUserDefaults] synchronize];
          }
     ];
}

@end
