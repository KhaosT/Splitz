//
//  OTIAroundMeViewController.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIAroundMeViewController.h"
#import "OTIIdentityCore.h"
#import "OTIWrapperCore.h"
#import "OTIPeerCell.h"
#import "OTIWrapperPeer.h"

#import "OTIPaymentViewController.h"
#import "OTISettingViewController.h"

@interface OTIAroundMeViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>{
    UICollectionView *_usersCollectionView;
    
    NSArray *_peersArray;
    
    NSTimer *_scanAnimationTimer;
    int     _scanAnimationIndex;
}

@property (weak, nonatomic) IBOutlet UIImageView *userAvatarImageView;
- (IBAction)displaySettings:(id)sender;

@end

@implementation OTIAroundMeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateData:(id)sender
{
    _peersArray = [[OTIWrapperCore sharedCore] peersAround];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_usersCollectionView reloadData];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scanAnimationIndex = 0;
    
    [[OTIWrapperCore sharedCore]setDataNotifier:self];
    
    _peersArray = [[OTIWrapperCore sharedCore] peersAround];
    
    _userAvatarImageView.layer.cornerRadius = 50;
    _userAvatarImageView.clipsToBounds = YES;
    
    if ([[OTIIdentityCore sharedCore] userAvatar]) {
        [_userAvatarImageView setImage:[[OTIIdentityCore sharedCore] userAvatar]];
    }
    
    _scanAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(setUpScanAnimation) userInfo:nil repeats:YES];
    
    [self setUpCollectionView];
    // Do any additional setup after loading the view from its nib.
}

- (void)setUpScanAnimation
{
    if (_scanAnimationIndex < 3) {
        _scanAnimationIndex ++;
        [self setUpScanAnimationWithIndex:_scanAnimationIndex];
    }else{
        [_scanAnimationTimer invalidate];
        _scanAnimationTimer = nil;
    }
}

- (void)setUpCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.itemSize = CGSizeMake(80, 115);
    layout.sectionInset = UIEdgeInsetsMake(10, 15, 10, 15);
    
    _usersCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 80, 320, 350) collectionViewLayout:layout];
    _usersCollectionView.backgroundColor = [UIColor clearColor];
    _usersCollectionView.dataSource = self;
    _usersCollectionView.delegate = self;
    [_usersCollectionView registerClass:[OTIPeerCell class] forCellWithReuseIdentifier:@"PeerCell"];
    
    [self.view addSubview:_usersCollectionView];
}

- (void)setUpScanAnimationWithIndex:(int)index
{
    CGFloat radius = 600;
    
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake((radius/2)*(-1), (radius/2)*(-1), radius, radius)];
    
    CAShapeLayer *backgroundShape = [[CAShapeLayer alloc]init];
    backgroundShape.path = ovalPath.CGPath;
    backgroundShape.position = self.userAvatarImageView.center;
    
    backgroundShape.fillColor = [UIColor clearColor].CGColor;
    backgroundShape.strokeColor = [UIColor colorWithHue:0.552 saturation:0.78 brightness:0.99 alpha:1.0].CGColor;
    
    
    CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 3;
    animationGroup.repeatCount = INFINITY;
    animationGroup.removedOnCompletion = NO;
    animationGroup.timingFunction = defaultCurve;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @0.0;
    scaleAnimation.toValue = @1.0;
    scaleAnimation.duration = 3;
    
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = 3;
    opacityAnimation.values = @[@1.0, @0.85, @0.45, @0];
    opacityAnimation.keyTimes = @[@0, @0.6, @0.8, @1];
    opacityAnimation.removedOnCompletion = NO;
    
    NSArray *animations = @[scaleAnimation, opacityAnimation];
    animationGroup.animations = animations;
    
    [self.view.layer insertSublayer:backgroundShape below:self.userAvatarImageView.layer];
    [backgroundShape addAnimation:animationGroup forKey:[NSString stringWithFormat:@"ZoomOutScan%i",index]];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _peersArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTIPeerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PeerCell" forIndexPath:indexPath];
    OTIWrapperPeer *peer = [_peersArray objectAtIndex:indexPath.item];
    UIImage *avatar = peer.userAvatar;
    
    NSArray *names = [peer.userName componentsSeparatedByString:@" "];
    
    [cell setName:names[0] withImage:avatar];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OTIPaymentViewController *vc = [[OTIPaymentViewController alloc]initWithNibName:nil bundle:nil];
    vc.peer = [_peersArray objectAtIndex:indexPath.item];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)displaySettings:(id)sender {
    OTISettingViewController *vc = [[OTISettingViewController alloc] initWithNibName:nil bundle:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
