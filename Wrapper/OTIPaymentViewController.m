//
//  OTIPaymentViewController.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIPaymentViewController.h"
#import "OTIIdentityCore.h"
#import "OTICoinbaseCore.h"

#import <MessageUI/MessageUI.h>

@interface OTIPaymentViewController ()<MFMailComposeViewControllerDelegate>{
    BOOL    _isBTC;
}


@property (weak, nonatomic) IBOutlet UIImageView *fromAvatarView;
@property (weak, nonatomic) IBOutlet UIImageView *toAvatarView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextField *moneyValue;
@property (weak, nonatomic) IBOutlet UIButton *directionButton;
@property (weak, nonatomic) IBOutlet UILabel *recptName;
@property (weak, nonatomic) IBOutlet UIButton *currencyButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;



- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)changeCurrency:(id)sender;

- (IBAction)cancelPayments:(id)sender;
- (IBAction)sendMoney:(id)sender;

@end

@implementation OTIPaymentViewController

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
    _isBTC = NO;
    
    _toAvatarView.image = [_peer userAvatar];
    _fromAvatarView.image = [[OTIIdentityCore sharedCore] userAvatar];
    _fromAvatarView.layer.cornerRadius = 50;
    _fromAvatarView.clipsToBounds = YES;
    _toAvatarView.layer.cornerRadius = 50;
    _toAvatarView.clipsToBounds = YES;
    
    if (CGRectGetHeight([UIScreen mainScreen].bounds) > 480) {
        _recptName.text = [_peer userName];
    }else{
        _recptName.text = @"";
    }
    
    _sendButton.tintColor = [UIColor colorWithHue:0.2833 saturation:0.82 brightness:0.83 alpha:1];
    [_sendButton setImage:[[UIImage imageNamed:@"send"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    _directionButton.tintColor = [UIColor colorWithHue:25.0/360.0 saturation:1.0 brightness:0.92 alpha:1.0];
    [_directionButton setImage:[[UIImage imageNamed:@"arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissKeyboard:(id)sender {
    [_moneyValue resignFirstResponder];
}

- (IBAction)changeCurrency:(id)sender {
    if ([OTICoinbaseCore coinbaseAuthorized]) {
        if (_isBTC) {
            _isBTC = NO;
            [_currencyButton setTitle:@"$" forState:UIControlStateNormal];
        }else{
            _isBTC = YES;
            [_currencyButton setTitle:@"฿" forState:UIControlStateNormal];
        }
    }
}

- (IBAction)cancelPayments:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendMoney:(id)sender {
    if (_moneyValue.text.length == 0) {
        NSCharacterSet *_numericOnly = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        NSCharacterSet *myStringSet = [NSCharacterSet characterSetWithCharactersInString:_moneyValue.text];
        
        if ([_numericOnly isSupersetOfSet:myStringSet]) {
            NSLog(@"Matched");
        }else{
            NSLog(@"MisMatched");
        }
    }
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber * myNumber = [f numberFromString:_moneyValue.text];
    if (!myNumber) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Invalid Value" message:@"It appears you entered a value is not support to send over Square Cash." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [a show];
        return;
    }
    
    if (_isBTC) {
        if ([OTICoinbaseCore coinbaseAuthorized]) {
            [_loadingIndicator startAnimating];
            [[OTICoinbaseCore sharedCore] sendMoneyToEmail:_peer.userEmailAddress forAmount:myNumber.stringValue note:[NSString stringWithFormat:@"%@ send you ฿%@ via Coinbase :)",[[OTIIdentityCore sharedCore] userName],myNumber] completionBlock:^(NSDictionary *dict){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_loadingIndicator stopAnimating];
                    if ([[dict objectForKey:@"success"] isEqualToNumber:@1]) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }else{
                        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:[[dict objectForKey:@"errors"] objectAtIndex:0] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [a show];
                    }
                });
            }];
        }
    }else{
        MFMailComposeViewController *mailComposer =
        [[MFMailComposeViewController alloc] init];
        [mailComposer setToRecipients:@[_peer.userEmailAddress]];
        [mailComposer setCcRecipients:@[@"cash@square.com"]];
        
        [mailComposer setSubject:[NSString stringWithFormat:@"Here's $%@",myNumber]];
        NSString *message = [NSString stringWithFormat:@"%@ send you $%@ via Square Cash :)",[[OTIIdentityCore sharedCore] userName],myNumber];
        [mailComposer setMessageBody:message
                              isHTML:NO];
        mailComposer.mailComposeDelegate = self;
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultCancelled) {
        NSLog(@"Canceled");
    }
    NSLog(@"%u,%@",result,error);
    [controller dismissViewControllerAnimated:NO completion:nil];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
