//
//  OTIPeerCell.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIPeerCell.h"

@interface OTIPeerCell (){
    CALayer  *_avatarLayer;
    UILabel  *_userName;
}

@end

@implementation OTIPeerCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _userName = [[UILabel alloc] initWithFrame:CGRectMake(0, 85, 80, 30)];
        _userName.textAlignment = NSTextAlignmentCenter;
        
        [self.contentView addSubview:_userName];
        
        _avatarLayer = [[CALayer alloc]init];
        _avatarLayer.cornerRadius = 40;
        _avatarLayer.masksToBounds = YES;
        _avatarLayer.frame = CGRectMake(0, 0, 80, 80);
        [self.contentView.layer addSublayer:_avatarLayer];
        
        // Initialization code
    }
    return self;
}

- (void)setName:(NSString *)name withImage:(UIImage *)image
{
    _userName.text = name;
    _avatarLayer.contents = (__bridge id)(image.CGImage);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
