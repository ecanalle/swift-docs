# Core Bluetooth - Wireless Communication

## Overview

Core Bluetooth enables communication with external Bluetooth devices. It supports Central mode (scanning/connecting) and Peripheral mode (advertising as a device).

## Main Topics

- [Central Mode](#central-mode)
- [Peripheral Mode](#peripheral-mode)
- [GATT Services](#gatt-services)
- [State Management](#state-management)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth)

---

## Central Mode

### Scanning for Devices

```swift
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?
    var discoveredDevices: [CBPeripheral] = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        // Scan for all devices
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        centralManager?.stopScan()
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on")
            startScanning()
        case .poweredOff:
            print("Bluetooth powered off")
        case .unsupported:
            print("Bluetooth not supported")
        default:
            print("Unknown state")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
            print("Discovered: \(peripheral.name ?? "Unknown")")
        }
    }
}
```

### Connecting to Device

```swift
class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var connectedPeripheral: CBPeripheral?
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager,
                       didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)  // Discover all services
    }
    
    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        print("Disconnected from \(peripheral.name ?? "device")")
        connectedPeripheral = nil
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Characteristic: \(characteristic.uuid)")
            
            // Read value
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // Subscribe to notifications
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
}
```

### Reading and Writing

```swift
class BluetoothManager: NSObject, CBPeripheralDelegate {
    func writeValue(to characteristic: CBCharacteristic, value: Data) {
        guard let peripheral = connectedPeripheral else { return }
        
        // Write with or without response
        if characteristic.properties.contains(.writeWithoutResponse) {
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        } else if characteristic.properties.contains(.write) {
            peripheral.writeValue(value, for: characteristic, type: .withResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }
        
        print("Received data: \(data.hexString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Write error: \(error)")
        } else {
            print("Write successful")
        }
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
```

---

## Peripheral Mode

### Advertising as Peripheral

```swift
import CoreBluetooth

class BluetoothPeripheral: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising() {
        let advertiseData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "MyDevice",
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "180A")]
        ]
        
        peripheralManager?.startAdvertising(advertiseData)
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral powered on")
            setupServices()
        case .poweredOff:
            print("Peripheral powered off")
        default:
            break
        }
    }
    
    func setupServices() {
        let serviceUUID = CBUUID(string: "180A")
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // Create characteristic
        let characteristicUUID = CBUUID(string: "2A29")
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .notify],
            value: "Manufacturer".data(using: .utf8),
            permissions: [.readable]
        )
        
        service.characteristics = [characteristic]
        peripheralManager?.add(service)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                          didAdd service: CBService,
                          error: Error?) {
        if let error = error {
            print("Error adding service: \(error)")
        } else {
            print("Service added successfully")
            startAdvertising()
        }
    }
}
```

---

## GATT Services

### Standard Service UUIDs

```swift
// Device Information Service
let deviceInfoService = CBUUID(string: "180A")

// Heart Rate Service
let heartRateService = CBUUID(string: "180D")

// Battery Service
let batteryService = CBUUID(string: "180F")

// Standard Characteristics
let manufacturerName = CBUUID(string: "2A29")     // 180A
let heartRateMeasurement = CBUUID(string: "2A37") // 180D
let batteryLevel = CBUUID(string: "2A19")         // 180F
```

### Custom Service Definition

```swift
// Custom UUIDs
let customServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
let customCharacUUID = CBUUID(string: "87654321-4321-4321-4321-210987654321")

func setupCustomService() {
    let service = CBMutableService(type: customServiceUUID, primary: true)
    
    let characteristic = CBMutableCharacteristic(
        type: customCharacUUID,
        properties: [.read, .write, .notify],
        value: nil,
        permissions: [.readable, .writeable]
    )
    
    service.characteristics = [characteristic]
    peripheralManager?.add(service)
}
```

---

## State Management

### Connection State

```swift
class BluetoothManager: NSObject {
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
        case disconnecting
    }
    
    private var state: ConnectionState = .disconnected
    var onStateChanged: ((ConnectionState) -> Void)?
    
    func setState(_ newState: ConnectionState) {
        guard state != newState else { return }
        
        state = newState
        print("State: \(newState)")
        onStateChanged?(newState)
    }
}
```

### Device Information Cache

```swift
struct BluetoothDevice {
    let identifier: UUID
    let name: String?
    let rssi: NSNumber
    var characteristics: [CBCharacteristic] = []
    var services: [CBService] = []
    
    var signalStrength: String {
        let rssiValue = rssi.intValue
        if rssiValue > -50 { return "Strong" }
        if rssiValue > -70 { return "Medium" }
        return "Weak"
    }
}
```

---

## 🎯 Best Practices

### 1. Check Bluetooth State
```swift
// ✅ Always check state before operations
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
        startScanning()
    }
}

// ❌ Assume Bluetooth is available
startScanning()  // May not work
```

### 2. Request User Permissions
```swift
// Info.plist requirements:
// NSBluetoothPeripheralUsageDescription
// NSBluetoothCentralRoleUsageDescription

// ✅ Test before use
if CBCentralManager().state == .poweredOn {
    // Safe to use
}
```

### 3. Cleanup on Disconnect
```swift
// ✅ Unsubscribe from notifications
func disconnect() {
    for characteristic in discoveredCharacteristics {
        centralManager?.cancelPeripheralConnection(peripheral)
    }
}
```

---

## ❌ Common Mistakes

### Mistake 1: Not Checking Bluetooth State

**WRONG:**
```swift
// ❌ May crash if Bluetooth off
startScanning()
```

**CORRECT:**
```swift
// ✅ Check state first
if centralManager.state == .poweredOn {
    startScanning()
}
```

---

### Mistake 2: Memory Leak with Delegate

**WRONG:**
```swift
// ❌ Retain cycle
peripheral.delegate = self
```

**CORRECT:**
```swift
// ✅ Use weak reference if needed
// Usually fine since peripheral manages delegate lifecycle
```

---

## Related Topics

- [Background Tasks](app-lifecycle.md)
- [Notifications](notifications.md)
- [Data Persistence](../06-data/persistence-and-storage/swiftdata.md)

---

**Master Core Bluetooth for wireless device integration!**
