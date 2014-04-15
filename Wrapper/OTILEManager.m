//
//  OTILEManager.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTILEManager.h"
#import "OTIServiceDefines.h"
#import "OTIWrapperPeer.h"
#import "OTIIdentityCore.h"
#import "OTIWrapperCore.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface OTILEManager () <CBCentralManagerDelegate,CBPeripheralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager        *_centeralManager;
    CBPeripheralManager     *_peripheralManager;
    
    CBMutableService        *_wrapperService;
    
    CBMutableCharacteristic *_wrapperSettingChar;
    CBMutableCharacteristic *_wrapperHashChar;
    CBMutableCharacteristic *_wrapperNotiChar;
    
    BOOL                    _readyToAdvertise;
    BOOL                    _isScanning;
    
    NSMutableDictionary     *_peersDictionary;
    
    dispatch_queue_t        _centralQueue;
}

@end

@implementation OTILEManager

- (id)init
{
    if (self = [super init]) {
        _readyToAdvertise = NO;
        _isScanning = NO;
        _peersDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray *)peersAround
{
    NSMutableArray *peerArray = [[NSMutableArray alloc]init];
    
    for (OTIWrapperPeer *peer in [_peersDictionary allValues]) {
        if (peer.hasProcessed) {
            [peerArray addObject:peer];
        }
    }
    
    return [peerArray copy];
}

- (void)initCentalManager
{
    _centralQueue = dispatch_queue_create("org.oltica.wrapper.centralManagerQueue", DISPATCH_QUEUE_SERIAL);
    _centeralManager = [[CBCentralManager alloc]initWithDelegate:self queue:_centralQueue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopScan) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startScan) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)startScan
{
    if (_centeralManager.state == CBCentralManagerStatePoweredOn) {
        _isScanning = YES;
        [_centeralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:WRAPPER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]}];
    }
#warning Handle BT Off
}

- (void)stopScan
{
    if (_isScanning) {
        [_peersDictionary removeAllObjects];
        for (OTIWrapperPeer *peer in [_peersDictionary allValues]) {
            [peer destroyPeer];
        }
        [[OTIWrapperCore sharedCore]dataSourceDidUpdated];
        NSLog(@"Stop Scan");
        _isScanning = NO;
        [_centeralManager stopScan];
    }
}

- (void)removePeerWithUUID:(NSString *)uuid
{
    if ([_peersDictionary objectForKey:uuid]) {
        [_peersDictionary removeObjectForKey:uuid];
    }
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral) {
        [_centeralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)initPeripheralManager
{
    _peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:dispatch_queue_create("org.oltica.wrapper.peripheralManagerQueue", DISPATCH_QUEUE_SERIAL) options:@{CBPeripheralManagerOptionRestoreIdentifierKey: @"Wrapper.PeripheralManager"}];
}

- (void)setupPeripheralManager
{
    if (!_wrapperService) {
        _wrapperService = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:WRAPPER_SERVICE_UUID] primary:YES];
        
        _wrapperSettingChar = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:WRAPPER_CHAR_SETTING] properties:CBCharacteristicPropertyRead value:[self constructSettingData] permissions:CBAttributePermissionsReadable];
        
        _wrapperHashChar = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:WRAPPER_CHAR_HASH] properties:(CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite) value:nil permissions:(CBAttributePermissionsReadable|CBAttributePermissionsWriteable)];
        
        _wrapperNotiChar = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:WRAPPER_CHAR_NOTI] properties:(CBCharacteristicPropertyRead|CBCharacteristicPropertyNotify) value:nil permissions:CBAttributePermissionsReadable];

        _wrapperService.characteristics = @[_wrapperSettingChar,_wrapperHashChar,_wrapperNotiChar];
        
        [_peripheralManager addService:_wrapperService];
    }
}

- (NSData *)constructSettingData
{
    NSDictionary *dict = @{@"PTC": PROTOCOL_VERSION,@"PRI":[[OTIIdentityCore sharedCore] shouldUseHashInsteadOfRealAddress]?@"Y":@"N"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    return data;
}

- (void)startAdvertising
{
    if (_readyToAdvertise) {
        NSDictionary *advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:WRAPPER_SERVICE_UUID]]};
        [_peripheralManager startAdvertising:advertisingData];
    }else{
        [NSException raise:@"Invaild Call of function startAdvertising" format:@"PeripheralManager not ready to advertise."];
    }
}

- (void)stopAdvertising
{
    if (_peripheralManager.isAdvertising) {
        [_peripheralManager stopAdvertising];
    }
}


#pragma mark - CBCentalManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([_peersDictionary objectForKey:peripheral.identifier.UUIDString]) {
        OTIWrapperPeer *peer = [_peersDictionary objectForKey:peripheral.identifier.UUIDString];
        peer.RSSI = [RSSI copy];
        peer.peerPeripheral = peripheral;
        peer.LEManager = self;
        if (!peer.hasProcessed && !peer.processing) {
            peer.processing = YES;
            [central connectPeripheral:peripheral options:nil];
        }
        [peer resetDiscoveryTimer];
    }else{
        OTIWrapperPeer *peer = [[OTIWrapperPeer alloc]init];
        [_peersDictionary setObject:peer forKey:peripheral.identifier.UUIDString];
        peer.RSSI = [RSSI copy];
        peer.peerPeripheral = peripheral;
        peer.LEManager = self;
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if ([_peersDictionary objectForKey:peripheral.identifier.UUIDString]) {
        OTIWrapperPeer *peer = [_peersDictionary objectForKey:peripheral.identifier.UUIDString];
        [peer connected];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([_peersDictionary objectForKey:peripheral.identifier.UUIDString]) {
        OTIWrapperPeer *peer = [_peersDictionary objectForKey:peripheral.identifier.UUIDString];
        [peer disconnected];
    }
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self setupPeripheralManager];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"PeripheralManagerWillRestoreWithDict:%@",dict);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        _readyToAdvertise = YES;
        [self startAdvertising];
        NSLog(@"Ready to advertise");
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising:%@",error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"SubscribeByCentral:%@",central);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"UnsubscribeByCentral:%@",central);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    if (request.characteristic == _wrapperHashChar) {
        request.value = [[OTIIdentityCore sharedCore]encryptedUserInfo];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSMutableData *data = [[NSMutableData alloc]init];
    NSString    *_centralUUID = [(CBATTRequest *)[requests firstObject] central].identifier.UUIDString;
    for (CBATTRequest *aReq in requests){
        [data appendData:aReq.value];
        [peripheral respondToRequest:aReq withResult:CBATTErrorSuccess];
    }
    [[OTIIdentityCore sharedCore]authenticateCentral:_centralUUID withData:data];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    
}

@end
