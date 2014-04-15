//
//  OTISetupViewController.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTISetupViewController.h"
#import "OTIIdentityCore.h"
#import "OTIAvatarViewController.h"

@interface OTISetupViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *userEmailField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

- (IBAction)goNext:(id)sender;

@end

@implementation OTISetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _userNameField.delegate = self;
    _userEmailField.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goNext:(id)sender
{
    if (_userNameField.text.length == 0) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Invalid Name" message:@"You must enter your name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        return;
    }
    
    if (_userEmailField.text.length == 0) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Invalid Email" message:@"You must enter your email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        return;
    }
    
    [[OTIIdentityCore sharedCore]setUpUserWithUsername:_userNameField.text email:_userEmailField.text];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"finishedSetup"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    OTIAvatarViewController *avatarVC = [[OTIAvatarViewController alloc]initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:avatarVC animated:YES];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:_userNameField]) {
        [_userEmailField becomeFirstResponder];
    }else{
        [_userEmailField resignFirstResponder];
        [self goNext:textField];
    }
    return NO;
}

@end
