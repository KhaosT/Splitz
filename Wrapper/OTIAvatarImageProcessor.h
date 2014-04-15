//
//  OTIAvatarImageProcessor.h
//  Wrapper
//
//  Created by Khaos Tian on 4/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTIAvatarImageProcessor : NSObject

+ (UIImage *)generateImageForInitial:(NSString *)initial withRadius:(CGFloat)radius;

@end
