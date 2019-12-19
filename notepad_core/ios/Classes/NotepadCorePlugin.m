#import <CoreBluetooth/CoreBluetooth.h>
#import "NotepadCorePlugin.h"

NSString *GSS_SUFFIX = @"0000-1000-8000-00805F9B34FB";

# pragma CBUUID+Extensions

@interface CBUUID (Extensions)
@end

@implementation CBUUID (Extensions)
- (NSString *)uuidString {
    return [self.UUIDString lowercaseString];
}
@end

# pragma CBPeripheral+Extensions

@interface CBPeripheral (Extensions)
@end

@implementation CBPeripheral (Extensions)
- (CBCharacteristic *)getCharacteristic:(NSString *)characteristic ofService:(NSString *)service {
    NSUInteger serviceIndex = [self.services indexOfObjectPassingTest:^BOOL(CBService *obj, NSUInteger idx, BOOL *stop) {
        NSString *withGss = [NSString stringWithFormat:@"0000%@-%@", obj.UUID.uuidString, GSS_SUFFIX];
        return [obj.UUID.uuidString isEqualToString:service] || [withGss isEqualToString:service];
    }];
    NSArray<CBCharacteristic *> *characteristics = self.services[serviceIndex].characteristics;
    NSUInteger characteristicIndex = [characteristics indexOfObjectPassingTest:^BOOL(CBCharacteristic *obj, NSUInteger idx, BOOL *stop) {
        NSString *withGss = [NSString stringWithFormat:@"0000%@-%@", obj.UUID.uuidString, GSS_SUFFIX];
        return [obj.UUID.uuidString isEqualToString:characteristic] || [withGss isEqualToString:characteristic];
    }];
    return characteristics[characteristicIndex];
}
@end

# pragma NotepadCorePlugin

@interface NotepadCorePlugin () <CBCentralManagerDelegate, FlutterStreamHandler, CBPeripheralDelegate>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredPeripherals;
@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) dispatch_group_t serviceConfigGroup;

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
        _peripheral.delegate = self;
        [_manager connectPeripheral:_peripheral options:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"disconnect"]) {
        [_manager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
        result(nil);
    } else if ([call.method isEqualToString:@"discoverServices"]) {
        [_peripheral discoverServices:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"writeValue"]) {
        NSString *service = call.arguments[@"service"];
        NSString *characteristic = call.arguments[@"characteristic"];
        FlutterStandardTypedData *value = call.arguments[@"value"];
        NSString *bleOutputProperty = call.arguments[@"bleOutputProperty"];
        enum CBCharacteristicWriteType type = [bleOutputProperty isEqualToString:@"withoutResponse"] ? CBCharacteristicWriteWithoutResponse : CBCharacteristicWriteWithResponse;
        [_peripheral writeValue:[value data]
              forCharacteristic:[_peripheral getCharacteristic:characteristic ofService:service]
                           type:type];
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

# pragma CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"peripheral: %@ didDiscoverServices: %@", peripheral.identifier, error);
    _serviceConfigGroup = dispatch_group_create();
    for (CBService *service in peripheral.services) {
        dispatch_group_enter(_serviceConfigGroup);
        [peripheral discoverCharacteristics:nil forService:service];
    }
    dispatch_group_notify(_serviceConfigGroup, dispatch_get_main_queue(), ^{
        self->_serviceConfigGroup = nil;
        [self->_connectorMessage sendMessage:@{@"ServiceState": @"discovered"}];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"peripheral:didDiscoverCharacteristicsForService (%@, %@)", service.UUID.uuidString, characteristic.UUID.uuidString);
    }
    dispatch_group_leave(_serviceConfigGroup);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"peripheral:didWriteValueForCharacteristic %@ %@ error: %@", characteristic.UUID.uuidString, characteristic.value, error);
}

@end
