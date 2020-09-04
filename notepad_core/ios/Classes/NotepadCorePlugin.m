#import <CoreBluetooth/CoreBluetooth.h>
#import "NotepadCorePlugin.h"

const int GATT_HEADER_LENGTH = 3;

NSString *GSS_SUFFIX = @"0000-1000-8000-00805f9b34fb";

# pragma CBUUID+Extensions

@interface CBUUID (Extensions)
@end

@implementation CBUUID (Extensions)
- (NSString *)uuidStr {
    return self.UUIDString.lowercaseString;
}
@end

# pragma CBPeripheral+Extensions

@interface CBPeripheral (Extensions)
@end

@implementation CBPeripheral (Extensions)
- (CBCharacteristic *)getCharacteristic:(NSString *)characteristic ofService:(NSString *)service {
    NSUInteger serviceIndex = [self.services indexOfObjectPassingTest:^BOOL(CBService *obj, NSUInteger idx, BOOL *stop) {
        NSString *withGss = [NSString stringWithFormat:@"0000%@-%@", obj.UUID.uuidStr, GSS_SUFFIX];
        return [obj.UUID.uuidStr isEqualToString:service] || [withGss isEqualToString:service];
    }];
    NSArray<CBCharacteristic *> *characteristics = self.services[serviceIndex].characteristics;
    NSUInteger characteristicIndex = [characteristics indexOfObjectPassingTest:^BOOL(CBCharacteristic *obj, NSUInteger idx, BOOL *stop) {
        NSString *withGss = [NSString stringWithFormat:@"0000%@-%@", obj.UUID.uuidStr, GSS_SUFFIX];
        return [obj.UUID.uuidStr isEqualToString:characteristic] || [withGss isEqualToString:characteristic];
    }];
    return characteristics[characteristicIndex];
}

- (void)setNotifiable:(NSString *)bleInputProperty forCharacteristic:(NSString *)characteristic ofService:(NSString *)service {
    [self setNotifyValue:![bleInputProperty isEqualToString:@"disabled"]
       forCharacteristic:[self getCharacteristic:characteristic ofService:service]];
}
@end

# pragma NotepadCorePlugin

@interface NotepadCorePlugin () <CBCentralManagerDelegate, FlutterStreamHandler, CBPeripheralDelegate>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredPeripherals;
@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) FlutterBasicMessageChannel *connectorMessage;
@property(nonatomic, strong) FlutterBasicMessageChannel *clientMessage;
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
        _clientMessage = [FlutterBasicMessageChannel messageChannelWithName:@"notepad_core/message.client" binaryMessenger:[registrar messenger]];
    }
    return self;
}

# pragma FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"handleMethodCall %@", call.method);
    if ([call.method isEqualToString:@"isBluetoothAvailable"]) {
        BOOL b = _manager.state == CBManagerStatePoweredOn;
        result(@(b));
    } else if ([call.method isEqualToString:@"startScan"]) {
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
        if (_peripheral)
            [_manager cancelPeripheralConnection:_peripheral];
        [self clean];
        result(nil);
        [_connectorMessage sendMessage:@{@"ConnectionState": @"disconnected"}];
    } else if ([call.method isEqualToString:@"discoverServices"]) {
        [_peripheral discoverServices:nil];
        result(nil);
    } else if ([call.method isEqualToString:@"setNotifiable"]) {
        NSString *service = call.arguments[@"service"];
        NSString *characteristic = call.arguments[@"characteristic"];
        NSString *bleInputProperty = call.arguments[@"bleInputProperty"];
        [_peripheral setNotifiable:bleInputProperty forCharacteristic:characteristic ofService:service];
        result(nil);
    } else if ([call.method isEqualToString:@"requestMtu"]) {
        NSUInteger mtu = [_peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
        result(nil);
        NSLog(@"peripheral.maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse %lu", (unsigned long) mtu);
        [_clientMessage sendMessage:@{@"mtuConfig": @(mtu + GATT_HEADER_LENGTH)}];
    } else if ([call.method isEqualToString:@"requestConnectionPriority"]) {
        // Ignore API for Android
        result(nil);
    } else if ([call.method isEqualToString:@"readValue"]) {
        NSString *service = call.arguments[@"service"];
        NSString *characteristic = call.arguments[@"characteristic"];
        [_peripheral readValueForCharacteristic:[_peripheral getCharacteristic:characteristic ofService:service]];
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
    switch (central.state) {
        case CBManagerStatePoweredOff:
            [_connectorMessage sendMessage:@{@"BluetoothState": @"unavailable"}];
            break;
        case CBManagerStatePoweredOn:
            [_connectorMessage sendMessage:@{@"BluetoothState": @"available"}];
            break;
    }

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"centralManager:didDiscoverPeripheral %@ %@", peripheral.name, peripheral.identifier);
    [_discoveredPeripherals setValue:peripheral forKey:peripheral.identifier.UUIDString];

    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (_scanResultSink)
        _scanResultSink(@{
                @"name": advertisementData[@"kCBAdvDataLocalName"] != nil ? advertisementData[@"kCBAdvDataLocalName"] : peripheral.name ? peripheral.name : @"",
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
    [self clean];
    [_connectorMessage sendMessage:@{@"ConnectionState": @"disconnected"}];
}

- (void)clean {
    _peripheral = nil;
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
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"peripheral:didDiscoverCharacteristicsForService (%@, %@)", service.UUID.uuidStr, characteristic.UUID.uuidStr);
    }
    [self->_connectorMessage sendMessage:@{
            @"ServiceState": @"discovered",
            @"services": @[service.UUID.uuidStr],
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"peripheral:didUpdateNotificationStateFor %@ %d", characteristic.UUID, characteristic.isNotifying);
    [_clientMessage sendMessage:@{@"characteristicConfig": characteristic.UUID.uuidStr}];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"peripheral:didWriteValueForCharacteristic %@ %@ error: %@", characteristic.UUID.uuidStr, characteristic.value, error);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (peripheral != _peripheral) {
        NSLog(@"Probably MEMORY LEAK!");
        return;
    }
    NSLog(@"peripheral:didUpdateValueForCharacteristic %@ %@ error: %@", characteristic.UUID.uuidStr, characteristic.value, error);
    NSDictionary *characteristicValue = @{
            @"characteristic": characteristic.UUID.uuidStr,
            @"value": [FlutterStandardTypedData typedDataWithBytes:characteristic.value],
    };
    [_clientMessage sendMessage:@{@"characteristicValue": characteristicValue}];
}

@end
