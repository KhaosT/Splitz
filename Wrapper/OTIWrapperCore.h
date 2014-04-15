//
//  OTIWrapperCore.h
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTINotifier <NSObject>

@optional

- (void)updateData:(id)sender;

@end

@interface OTIWrapperCore : NSObject

@property (nonatomic,assign) id dataNotifier;

+ (OTIWrapperCore *)sharedCore;
- (NSDictionary *)userContacts;
- (NSArray *)peersAround;

- (void)dataSourceDidUpdated;

@end
