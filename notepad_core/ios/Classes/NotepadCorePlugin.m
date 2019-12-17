#import <CoreBluetooth/CoreBluetooth.h>
#import "NotepadCorePlugin.h"

# pragma NotepadCorePlugin

@interface NotepadCorePlugin () <CBCentralManagerDelegate, FlutterStreamHandler>
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) FlutterEventSink scanResultSink;

@end

@implementation NotepadCorePlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [[NotepadCorePlugin alloc] initWithRegistrar:registrar];
}

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

        FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"notepad_core/method" binaryMessenger:[registrar messenger]];
        [registrar addMethodCallDelegate:self channel:methodChannel];
        [[FlutterEventChannel eventChannelWithName:@"notepad_core/event.scanResult" binaryMessenger:[registrar messenger]] setStreamHandler:self];
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
    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (_scanResultSink)
        _scanResultSink(@{
                @"name": peripheral.name ? peripheral.name : @"",
                @"deviceId": peripheral.identifier.UUIDString,
                @"manufacturerData": [FlutterStandardTypedData typedDataWithBytes:(manufacturerData ? manufacturerData : [NSData new])],
                @"rssi": RSSI,
        });
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
