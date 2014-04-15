//
//  OTIAppDelegate.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIAppDelegate.h"
#import "OTIAroundMeViewController.h"
#import "OTISetupViewController.h"
#import "OTICoinbaseCore.h"

@implementation OTIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"finishedSetup"]) {
        self.viewController = [[OTIAroundMeViewController alloc] initWithNibName:nil bundle:nil];
    }else{
        OTISetupViewController *setUpVC = [[OTISetupViewController alloc] initWithNibName:nil bundle:nil];

        self.viewController = [[UINavigationController alloc]initWithRootViewController:setUpVC];
    }
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    //splitz://coinbase/
    
    NSString *urlString = [url absoluteString];
    NSArray *subElements = [urlString componentsSeparatedByString:@"/"];
    NSLog(@"%@",subElements);
    if (subElements.count > 2 && [subElements[2] isEqualToString:@"coinbase"]) {
        NSLog(@"CoinBase");
        NSString *query = [[subElements lastObject] substringFromIndex:1];
        NSArray *queryElements = [query componentsSeparatedByString:@"&"];
        for (NSString *element in queryElements) {
            NSArray *keyVal = [element componentsSeparatedByString:@"="];
            if (keyVal.count > 0) {
                NSString *variableKey = [keyVal objectAtIndex:0];
                NSString *value = (keyVal.count == 2) ? [keyVal lastObject] : nil;
                if ([variableKey isEqualToString:@"code"] && value) {
                    [[OTICoinbaseCore sharedCore] processOAuthWithCode:value];
                }
            }
        }
    }
    return YES;
}

@end
