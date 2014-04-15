//
//  OTIAvatarViewController.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIAvatarViewController.h"
#import "OTIAroundMeViewController.h"
#import "OTIAppDelegate.h"
#import "OTIIdentityCore.h"

@interface OTIAvatarViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)takePicture:(id)sender;
- (IBAction)chooseFromCameraRoll:(id)sender;
- (IBAction)skipAvatarSetup:(id)sender;

@end

@implementation OTIAvatarViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takePicture:(id)sender {
    UIImagePickerController *caperture = [[UIImagePickerController alloc]init];
    caperture.delegate = self;
    caperture.allowsEditing = NO;
    caperture.sourceType = UIImagePickerControllerSourceTypeCamera;
    caperture.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    [self presentViewController:caperture animated:NO completion:NULL];
}

- (IBAction)chooseFromCameraRoll:(id)sender {
    UIImagePickerController *pick = [[UIImagePickerController alloc]init];
    pick.delegate = self;
    pick.allowsEditing = NO;
    pick.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:pick animated:NO completion:NULL];
}

- (IBAction)skipAvatarSetup:(id)sender {
    OTIAroundMeViewController *vc = [[OTIAroundMeViewController alloc] initWithNibName:nil bundle:nil];
    
    // animate the modal presentation
    
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    OTIAppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    [d.window.rootViewController presentViewController:vc
                                                 animated:YES
                                               completion:^{
                                                   
                                                   // and then get rid of it as a modal
                                                   
                                                   [vc dismissViewControllerAnimated:NO completion:nil];
                                                   
                                                   // and set it as your rootview controller
                                                   
                                                   d.window.rootViewController = vc;
                                               }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [[OTIIdentityCore sharedCore] setUpUserAvatar:[self cropBiggestCenteredSquareImageFromImage:image withSide:100]];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self skipAvatarSetup:self];
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage*)cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side
{
    // Get size of current image
    CGSize size = [image size];
    if( size.width == size.height && size.width == side){
        return image;
    }
    
    CGSize newSize = CGSizeMake(side, side);
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.height / image.size.height;
        delta = ratio*(image.size.width - image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.width;
        delta = ratio*(image.size.height - image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
