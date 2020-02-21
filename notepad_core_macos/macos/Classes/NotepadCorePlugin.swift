import Cocoa
import CoreBluetooth
import FlutterMacOS

let GSS_SUFFIX = "0000-1000-8000-00805f9b34fb"

extension CBUUID {
    public var uuidStr: String {
        get {
            uuidString.lowercased()
        }
    }
}

extension CBPeripheral {
    public func getCharacteristic(_ characteristic: String, of service: String) -> CBCharacteristic {
        let s = self.services?.first {
            $0.uuid.uuidStr == service || "0000\($0.uuid.uuidStr)-\(GSS_SUFFIX)" == service
        }
        let c = s?.characteristics?.first {
            $0.uuid.uuidStr == characteristic || "0000\($0.uuid.uuidStr)-\(GSS_SUFFIX)" == characteristic
        }
        return c!
    }

    public func setNotifiable(_ bleInputProperty: String, for characteristic: String, of service: String) {
        setNotifyValue(bleInputProperty != "disabled", for: getCharacteristic(characteristic, of: service))
    }
}

public class NotepadCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = NotepadCorePlugin()

        let channel = FlutterMethodChannel(name: "notepad_core/method", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(plugin, channel: channel)

        FlutterEventChannel(name: "notepad_core/event.scanResult", binaryMessenger: registrar.messenger).setStreamHandler(plugin)
        plugin.connectorMessage = FlutterBasicMessageChannel(name: "notepad_core/message.connector", binaryMessenger: registrar.messenger)
        plugin.clientMessage = FlutterBasicMessageChannel(name: "notepad_core/message.client", binaryMessenger: registrar.messenger)
    }

    private var manager: CBCentralManager!
    private var discoveredPeripherals: Dictionary<String, CBPeripheral>!
    private var peripheral: CBPeripheral?

    private var serviceConfigGroup: DispatchGroup?

    private var scanResultSink: FlutterEventSink?
    private var connectorMessage: FlutterBasicMessageChannel!
    private var clientMessage: FlutterBasicMessageChannel!

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
        discoveredPeripherals = Dictionary()
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
        case "connect":
            guard let arguments = call.arguments as? Dictionary<String, Any>,
                  let deviceId = arguments["deviceId"] as? String else {
                result(FlutterMethodNotImplemented)
                return
            }
            peripheral = discoveredPeripherals[deviceId]
            peripheral!.delegate = self
            manager.connect(peripheral!)
            result(nil)
        case "disconnect":
            if peripheral != nil {
                manager.cancelPeripheralConnection(peripheral!)
            }
            clean()
            result(nil)
        case "discoverServices":
            peripheral?.discoverServices(nil)
            result(nil)
        case "setNotifiable":
            guard let arguments = call.arguments as? Dictionary<String, Any>,
                  let service = arguments["service"] as? String,
                  let characteristic = arguments["characteristic"] as? String,
                  let bleInputProperty = arguments["bleInputProperty"] as? String else {
                result(FlutterMethodNotImplemented)
                return
            }
            peripheral?.setNotifiable(bleInputProperty, for: characteristic, of: service)
            result(nil)
        case "readValue":
            guard let arguments = call.arguments as? Dictionary<String, Any>,
                  let service = arguments["service"] as? String,
                  let characteristic = arguments["characteristic"] as? String else {
                result(FlutterMethodNotImplemented)
                return
            }
            peripheral?.readValue(for: peripheral!.getCharacteristic(characteristic, of: service))
            result(nil)
        case "writeValue":
            guard let arguments = call.arguments as? Dictionary<String, Any>,
                  let service = arguments["service"] as? String,
                  let characteristic = arguments["characteristic"] as? String,
                  let value = arguments["value"] as? FlutterStandardTypedData,
                  let bleOutputProperty = arguments["bleOutputProperty"] as? String else {
                result(FlutterMethodNotImplemented)
                return
            }
            let type = bleOutputProperty == "withoutResponse" ? CBCharacteristicWriteType.withoutResponse : CBCharacteristicWriteType.withResponse
            peripheral?.writeValue(value.data,
                    for: peripheral!.getCharacteristic(characteristic, of: service),
                    type: type)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension NotepadCorePlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState \(central.state.rawValue)")
        switch central.state {
        case .poweredOff:
            connectorMessage.sendMessage(["BluetoothState": "unavailable"])
        case .poweredOn:
            connectorMessage.sendMessage(["BluetoothState": "available"])
        default:
            break
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("centralManager:didDiscoverPeripheral \(peripheral.name) \(peripheral.identifier)")
        discoveredPeripherals[peripheral.identifier.uuidString] = peripheral

        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        scanResultSink?([
            "name": peripheral.name ?? "",
            "deviceId": peripheral.identifier.uuidString,
            "manufacturerData": FlutterStandardTypedData(bytes: manufacturerData ?? Data()),
            "rssi": RSSI,
        ])
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager:didConnect \(peripheral.identifier)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        connectorMessage.sendMessage(["ConnectionState": "connected"])
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("centralManager:didDisconnectPeripheral: \(peripheral.identifier) error: \(error)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        clean()
        connectorMessage.sendMessage(["ConnectionState": "disconnected"])
    }

    private func clean() {
        peripheral = nil
    }
}

extension NotepadCorePlugin: FlutterStreamHandler {
    open func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
            return nil
        }
        print("NotepadCorePlugin onListenWithArguments：\(name)")
        if name == "scanResult" {
            scanResultSink = events
        }
        return nil
    }

    open func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
            return nil
        }
        print("NotepadCorePlugin onCancelWithArguments：\(name)")
        if name == "scanResult" {
            scanResultSink = nil
        }
        return nil
    }
}

extension NotepadCorePlugin: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral: \(peripheral.identifier) didDiscoverServices: \(error)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        serviceConfigGroup = DispatchGroup()
        for service in peripheral.services! {
            serviceConfigGroup?.enter()
            peripheral.discoverCharacteristics(nil, for: service)
        }
        serviceConfigGroup?.notify(queue: DispatchQueue.main) {
            self.serviceConfigGroup = nil
            self.connectorMessage.sendMessage(["ServiceState": "discovered"])
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("peripheral:didDiscoverCharacteristicsForService (\(service.uuid), \(characteristic.uuid)")
        }
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        serviceConfigGroup?.leave()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("peripheral:didUpdateNotificationStateFor \(characteristic.uuid) \(characteristic.isNotifying)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        clientMessage.sendMessage(["characteristicConfig": characteristic.uuid.uuidStr])
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value as? NSData
        print("peripheral:didWriteValueForCharacteristic \(characteristic.uuid) \(data) error: \(error)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value!
        print("peripheral:didUpdateValueForForCharacteristic \(characteristic.uuid) \(data as NSData) error: \(error)")
        if self.peripheral != peripheral {
            print("Probably MEMORY LEAK!")
            return
        }
        let characteristicValue: [String: Any] = [
            "characteristic": characteristic.uuid.uuidStr,
            "value": FlutterStandardTypedData(bytes: data)
        ]
        clientMessage.sendMessage(["characteristicValue": characteristicValue])
    }
}
