//
//  OTIAvatarImageProcessor.m
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIAvatarImageProcessor.h"

@implementation OTIAvatarImageProcessor

+ (UIImage *)generateImageForInitial:(NSString *)initial withRadius:(CGFloat)radius
{
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:36.f];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius*2, radius*2), NO, 0);
    CGSize size = [OTIAvatarImageProcessor getSizeForText:initial forFont:font];
    CGRect rect = CGRectMake(0, radius - size.height/2, radius*2, radius*2);
    [[UIColor lightGrayColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, radius*2, radius*2));
    [[UIColor blackColor]set];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [initial drawInRect:CGRectIntegral(rect) withAttributes:@{NSFontAttributeName: font,NSParagraphStyleAttributeName:style}];
    UIImage *avatar = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return avatar;
}

+ (CGSize)getSizeForText:(NSString *)text forFont:(UIFont *)font
{
    NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:font forKey: NSFontAttributeName];
    CGSize size = [text boundingRectWithSize:CGSizeMake(200.f, 200.f)
                                     options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                  attributes:stringAttributes context:nil].size;
    return CGSizeMake(size.width + 1, size.height + 1);
}

@end
