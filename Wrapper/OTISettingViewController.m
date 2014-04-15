//
//  OTISettingViewController.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTISettingViewController.h"
#import "OTISetupViewController.h"
#import "OTIAppDelegate.h"

#import "OTICoinbaseCore.h"

@interface OTISettingViewController ()
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

- (IBAction)changePrivacyStatus:(id)sender;
- (IBAction)resetUserData:(id)sender;
- (IBAction)dismissSettings:(id)sender;
- (IBAction)authWithCoinBase:(id)sender;

@end

@implementation OTISettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([OTICoinbaseCore coinbaseAuthorized]) {
        [_connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changePrivacyStatus:(id)sender {
    
}

- (IBAction)resetUserData:(id)sender {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"avatar.png"];
    [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
    
    OTISetupViewController *setUpVC = [[OTISetupViewController alloc] initWithNibName:nil bundle:nil];
    setUpVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:setUpVC];
    
    OTIAppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [d.window.rootViewController presentViewController:navi
                                              animated:YES
                                            completion:^{
                                                
                                                // and then get rid of it as a modal
                                                
                                                [navi dismissViewControllerAnimated:NO completion:nil];
                                                
                                                // and set it as your rootview controller
                                                
                                                d.window.rootViewController = navi;
                                            }];
}

- (IBAction)dismissSettings:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)authWithCoinBase:(id)sender {
    if (![OTICoinbaseCore coinbaseAuthorized]) {
        NSURL *authUrl = [[OTICoinbaseCore sharedCore] urlForAuthorizing];
        [[UIApplication sharedApplication] openURL:authUrl];
        [_connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    }else{
        [_connectButton setTitle:@"Connect" forState:UIControlStateNormal];
        [[OTICoinbaseCore sharedCore] deAuthorize];
    }
}
@end
