//
//  OTIWrapperPeer.h
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "OTILEManager.h"

@interface OTIWrapperPeer : NSObject

@property (nonatomic, weak)   OTILEManager      *LEManager;
@property (nonatomic, strong) CBPeripheral      *peerPeripheral;
@property (nonatomic, strong) NSNumber          *RSSI;
@property (nonatomic, strong) NSData            *encryptToken;

@property (nonatomic, strong) NSString          *userName;
@property (nonatomic, strong) NSString          *userEmailAddress;
@property (nonatomic, strong) UIImage           *userAvatar;
@property (nonatomic, strong) NSString          *avatarID;

@property (nonatomic, readwrite) BOOL           isConnected;
@property (nonatomic, readwrite) BOOL           processing;
@property (nonatomic, readwrite) BOOL           hasProcessed;

- (void)destroyPeer;

- (void)resetDiscoveryTimer;
- (void)connected;
- (void)disconnected;

- (BOOL)isInContact;

@end
