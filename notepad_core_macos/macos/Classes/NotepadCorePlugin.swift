import Cocoa
import CoreBluetooth
import FlutterMacOS

public class NotepadCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        NotepadCorePlugin(registrar)
    }

    private var manager: CBCentralManager!

    private var connectorMessage: FlutterBasicMessageChannel!

    private var scanResultSink: FlutterEventSink?

    convenience init(_ registrar: FlutterPluginRegistrar) {
        self.init()
        manager = CBCentralManager(delegate: self, queue: nil)

        let channel = FlutterMethodChannel(name: "notepad_core/method", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(self, channel: channel)
        FlutterEventChannel(name: "notepad_core/event.scanResult", binaryMessenger: registrar.messenger).setStreamHandler(self)
        connectorMessage = FlutterBasicMessageChannel(name: "notepad_core/message.connector", binaryMessenger: registrar.messenger)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("handleMethodCall \(call.method)")
        switch call.method {
        case "isBluetoothAvailable":
            result(manager.state == .poweredOn)
        case "startScan":
            manager.scanForPeripherals(withServices: nil)
            result(nil)
        case "stopScan":
            manager.stopScan()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension NotepadCorePlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState \(central.state)")
        if (central.state == .poweredOff) {
            connectorMessage.sendMessage(["BluetoothState": "unavailable"])
        } else if (central.state == .poweredOn) {
            connectorMessage.sendMessage(["BluetoothState": "available"])
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("centralManager:didDiscoverPeripheral \(peripheral.name) \(peripheral.identifier)")

        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        scanResultSink?([
            "name": peripheral.name ?? "",
            "deviceId": peripheral.identifier.uuidString,
            "manufacturerData": FlutterStandardTypedData(bytes: manufacturerData ?? Data()),
            "rssi": RSSI,
        ])
    }
}

extension NotepadCorePlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
            return FlutterError(code: "NotImplemented", message: nil, details: nil)
        }
        if (name == "scanResult") {
            scanResultSink = events
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
            return FlutterError(code: "NotImplemented", message: nil, details: nil)
        }
        if (name == "scanResult") {
            scanResultSink = nil
        }
        return nil
    }
}
