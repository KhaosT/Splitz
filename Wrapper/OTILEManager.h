//
//  OTILEManager.h
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OTILEManager : NSObject

- (void)initCentalManager;
- (void)initPeripheralManager;

- (void)setupPeripheralManager;
- (void)startAdvertising;
- (void)stopAdvertising;

- (void)removePeerWithUUID:(NSString *)uuid;
- (void)disconnectPeripheral:(CBPeripheral *)peripheral;

- (NSArray *)peersAround;

@end
