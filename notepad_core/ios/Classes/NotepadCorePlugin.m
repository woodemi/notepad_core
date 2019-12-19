#import <CoreBluetooth/CoreBluetooth.h>
#import "NotepadCorePlugin.h"

# pragma NotepadCorePlugin

@interface NotepadCorePlugin () <CBCentralManagerDelegate, FlutterStreamHandler>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredPeripherals;
@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) FlutterBasicMessageChannel *connectorMessage;
@property(nonatomic, strong) FlutterEventSink scanResultSink;

@end

@implementation NotepadCorePlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [[NotepadCorePlugin alloc] initWithRegistrar:registrar];
}

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredPeripherals = [[NSMutableDictionary alloc] init];

        FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"notepad_core/method" binaryMessenger:[registrar messenger]];
        [registrar addMethodCallDelegate:self channel:methodChannel];
        [[FlutterEventChannel eventChannelWithName:@"notepad_core/event.scanResult" binaryMessenger:[registrar messenger]] setStreamHandler:self];
        _connectorMessage = [FlutterBasicMessageChannel messageChannelWithName:@"notepad_core/message.connector" binaryMessenger:[registrar messenger]];
    }
    return self;
}

# pragma FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"handleMethodCall %@", call.method);
    if ([call.method isEqualToString:@"startScan"]) {
        [_manager scanForPeripheralsWithServices:nil options:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"stopScan"]) {
        [_manager stopScan];
        result(nil);
    } else if ([call.method isEqualToString:@"connect"]) {
        NSString *deviceId = call.arguments[@"deviceId"];
        _peripheral = _discoveredPeripherals[deviceId];
        [_manager connectPeripheral:_peripheral options:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"disconnect"]) {
        [_manager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

# pragma CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"centralManagerDidUpdateState %ld", (long) central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"centralManager:didDiscoverPeripheral %@ %@", peripheral.name, peripheral.identifier);
    [_discoveredPeripherals setValue:peripheral forKey:peripheral.identifier.UUIDString];

    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (_scanResultSink)
        _scanResultSink(@{
                @"name": peripheral.name ? peripheral.name : @"",
                @"deviceId": peripheral.identifier.UUIDString,
                @"manufacturerData": [FlutterStandardTypedData typedDataWithBytes:(manufacturerData ? manufacturerData : [NSData new])],
                @"rssi": RSSI,
        });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"centralManager:didConnect %@", peripheral.identifier);
    [_connectorMessage sendMessage:@{@"ConnectionState": @"connected"}];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"centralManager:didDisconnectPeripheral: %@ error: %@", peripheral.identifier, error);
    _peripheral = nil;
    [_connectorMessage sendMessage:@{@"ConnectionState": @"disconnected"}];
}

# pragma FlutterStreamHandler

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    NSString *name = [arguments objectForKey:@"name"];
    NSLog(@"NotepadCorePlugin onListenWithArguments：%@", name);
    if ([name isEqualToString:@"scanResult"]) {
        _scanResultSink = events;
    }
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    NSString *name = [arguments objectForKey:@"name"];
    NSLog(@"NotepadCorePlugin onCancelWithArguments：%@", name);
    if ([name isEqualToString:@"scanResult"]) {
        _scanResultSink = nil;
    }
    return nil;
}

@end
