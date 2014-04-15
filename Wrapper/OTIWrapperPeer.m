//
//  OTIWrapperPeer.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIWrapperPeer.h"
#import "OTIServiceDefines.h"
#import "OTIWrapperCore.h"
#import "OTIHashing.h"
#import "OTIEncryption.h"
#import "OTIServiceDefines.h"
#import "OTIAvatarImageProcessor.h"

@interface OTIWrapperPeer ()<CBPeripheralDelegate>
{
    NSTimer         *_lastDiscoveryTimer;
    NSTimer         *_connectionTimer;
    
    int             _disappearCount;
    
    BOOL            _hashed;
    BOOL            _isInUserContact;
    
    CBCharacteristic    *_wrapperSettingChar;
    CBCharacteristic    *_wrapperHashChar;
    CBCharacteristic    *_wrapperNotiChar;
}

@end

@implementation OTIWrapperPeer

- (id)init
{
    if (self = [super init]) {
        _isConnected = NO;
        _disappearCount = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            _lastDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(peerDidDisappear) userInfo:nil repeats:YES];
        });
    }
    return self;
}

- (void)peerDidDisappear
{
    if (_peerPeripheral.state != CBPeripheralStateConnected) {
        if (_disappearCount < 2) {
            _disappearCount ++;
        }else{
            //Send notification that peer has been disappear from user;
            NSLog(@"Peer:%@ Disappeared",_userName);
            [_LEManager removePeerWithUUID:_peerPeripheral.identifier.UUIDString];
            [[OTIWrapperCore sharedCore]dataSourceDidUpdated];
            [_lastDiscoveryTimer invalidate];
            _lastDiscoveryTimer = nil;
        }
    }
}

- (void)destroyPeer
{
    [_LEManager removePeerWithUUID:_peerPeripheral.identifier.UUIDString];
    [_lastDiscoveryTimer invalidate];
    _lastDiscoveryTimer = nil;
    _disappearCount = 0;
    _connectionTimer = nil;
    _encryptToken = nil;
    _userName = nil;
    _userEmailAddress = nil;
    _userAvatar = nil;
    
}

- (void)resetDiscoveryTimer
{
    _disappearCount = 0;
    //Reset Timer to disappear;
}

- (BOOL)isInContact
{
    return _isInUserContact;
}

- (void)connected
{
    NSLog(@"Connected");
    _isConnected = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(shouldTerminateConnection) userInfo:nil repeats:NO];
    });
    [_peerPeripheral setDelegate:self];
    [_peerPeripheral discoverServices:@[[CBUUID UUIDWithString:WRAPPER_SERVICE_UUID]]];
}

- (void)shouldTerminateConnection
{
    [_LEManager disconnectPeripheral:_peerPeripheral];
    //Send notification to LEManager ask to disconnect from peer because the action takes too long
}

- (void)disconnected
{
    NSLog(@"Disconnected");
    _processing = NO;
    _isConnected = NO;
    [_connectionTimer invalidate];
    _connectionTimer = nil;
    //Restart Timer since we are no longer connected to peripher;
}

- (void)exchangeUserInfo
{
    if (_wrapperHashChar) {
        [_peerPeripheral readValueForCharacteristic:_wrapperHashChar];
    }
}

- (void)finishExchangeData
{
    _hasProcessed = YES;
    _processing = NO;
    [[OTIWrapperCore sharedCore]dataSourceDidUpdated];
    [_LEManager disconnectPeripheral:_peerPeripheral];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for(CBService *aService in peripheral.services){
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:WRAPPER_SERVICE_UUID]]) {
            NSLog(@"Found Service");
            [peripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for(CBCharacteristic *aCharacteristic in service.characteristics){
        if ([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:WRAPPER_CHAR_NOTI]]) {
            NSLog(@"Discover Notify Char");
            _wrapperNotiChar = aCharacteristic;
#warning Disabled Notify
            //[_peerPeripheral setNotifyValue:YES forCharacteristic:_wrapperNotiChar];
        }
        if ([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:WRAPPER_CHAR_HASH]]) {
            NSLog(@"Discover Hash Char");
            _wrapperHashChar = aCharacteristic;
        }
        if ([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:WRAPPER_CHAR_SETTING]]) {
            NSLog(@"Discover Setting Char");
            _wrapperSettingChar = aCharacteristic;
            [_peerPeripheral readValueForCharacteristic:_wrapperSettingChar];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic isEqual:_wrapperSettingChar]) {
        NSDictionary *settings = [NSJSONSerialization JSONObjectWithData:characteristic.value options:0 error:nil];
        if ([[settings objectForKey:@"PRI"] isEqualToString:@"Y"]) {
            _hashed = YES;
        }
        [self exchangeUserInfo];
        NSLog(@"Read Settings:%@",[NSJSONSerialization JSONObjectWithData:characteristic.value options:0 error:nil]);
    }
    
    if ([characteristic isEqual:_wrapperHashChar]) {
        if (characteristic.value) {
            NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:[OTIEncryption decryptedDataFromData:characteristic.value withKey:SHARED_KEY] options:0 error:nil];
            
            if (!userInfo) {
                return;
            }
            
            _userEmailAddress = [[[userInfo objectForKey:@"e"]lowercaseString] copy];
            _userName = [[userInfo objectForKey:@"u"] copy];
            
            NSString *key = nil;
            
            if (_hashed) {
                key = [[userInfo objectForKey:@"e"] copy];
            }else{
                key = [OTIHashing hashValueForString:_userEmailAddress];
            }
            
            if ([[[OTIWrapperCore sharedCore] userContacts]objectForKey:key]) {
                _isInUserContact = YES;
                _userAvatar = [[[[OTIWrapperCore sharedCore] userContacts]objectForKey:key] objectForKey:@"avatar"];
                NSLog(@"Is in user's contact");
            }
            
            NSArray *names = [_userName componentsSeparatedByString:@" "];
            
            if (!_userAvatar) {
                NSMutableString *nameInitial = [[NSMutableString alloc]init];
                for (NSString *name in names) {
                    if (name.length > 0) {
                        [nameInitial appendString:[name substringToIndex:1]];
                    }
                }
                
                _userAvatar = [OTIAvatarImageProcessor generateImageForInitial:nameInitial withRadius:40.f];
            }
            
            NSLog(@"Hash Val:%@",userInfo);
            
            [self finishExchangeData];
        }
    }
}

 - (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}

@end
