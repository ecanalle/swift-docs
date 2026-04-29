# Bluetooth and BLE - Core Bluetooth Framework

## Overview

Bluetooth Low Energy (BLE) enables wireless communication with low-power peripheral devices. Core Bluetooth framework provides APIs for discovering, connecting, and reading/writing data to BLE devices.

## Main Topics

- [BLE Basics](#ble-basics)
- [Central and Peripheral](#central-and-peripheral-roles)
- [Device Discovery](#device-discovery)
- [Connection Management](#connection-management)
- [Reading and Writing Data](#reading-and-writing-data)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Core Bluetooth Framework](https://developer.apple.com/documentation/corebluetooth)
- [WWDC 2020: Advances in Bluetooth Technology](https://developer.apple.com/videos/play/wwdc2020/10097/)
- [BLE Fundamentals](https://developer.apple.com/documentation/corebluetooth/transferring_data_between_bluetooth_devices)

---

## BLE Basics

### What is Bluetooth Low Energy?

Bluetooth Low Energy (BLE) is a wireless technology designed for short-range communication with minimal power consumption. Unlike Classic Bluetooth, BLE is optimized for intermittent data transmission and can run for months on battery.

**Key Characteristics:**
- Range: 50-240 meters (depending on power class)
- Power consumption: Very low
- Data throughput: Lower than Classic Bluetooth (suitable for sensors)
- Ideal for: Fitness trackers, health monitors, smart home devices

### BLE Architecture

```swift
import CoreBluetooth

// BLE communication involves:
// 1. Central: iPhone/iPad (master device - connects and reads)
// 2. Peripheral: Sensor/Device (slave device - advertises and provides data)
// 3. GATT: Generic Attribute Profile (defines how data is structured)
// 4. Services: Collections of characteristics
// 5. Characteristics: Individual data points
// 6. Descriptors: Information about characteristics

// Example Service Structure:
// Service: Heart Rate
//   ├── Characteristic: Heart Rate Measurement
//   ├── Characteristic: Body Sensor Location
//   └── Characteristic: Heart Rate Control Point
```

---

## Central and Peripheral Roles

### Central Role (iPhone Reading from Sensor)

```swift
import CoreBluetooth

class BluetoothCentral: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Scanning
    func startScanning() {
        // Scan for peripherals advertising Heart Rate service
        let heartRateServiceUUID = CBUUID(string: "180D")
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is available")
            startScanning()
        case .poweredOff:
            print("❌ Bluetooth is off")
        case .unsupported:
            print("❌ Bluetooth not supported")
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDiscover peripheral: CBPeripheral, 
                       advertisementData: [String : Any], 
                       rssi RSSI: NSNumber) {
        // Found a device!
        discoveredPeripherals.append(peripheral)
        print("Found: \(peripheral.name ?? "Unknown"), RSSI: \(RSSI)")
    }
}
```

### Peripheral Role (Sensor Broadcasting Data)

```swift
import CoreBluetooth

class BluetoothPeripheral: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private var heartRateCharacteristic: CBMutableCharacteristic?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }
    
    func setupPeripheral() {
        // Create Heart Rate Service
        let heartRateServiceUUID = CBUUID(string: "180D")
        let heartRateService = CBMutableService(type: heartRateServiceUUID, primary: true)
        
        // Create Heart Rate Measurement Characteristic
        let heartRateCharacteristicUUID = CBUUID(string: "2A37")
        heartRateCharacteristic = CBMutableCharacteristic(
            type: heartRateCharacteristicUUID,
            properties: [.read, .notify],
            value: nil
        )
        
        heartRateService.characteristics = [heartRateCharacteristic!]
        peripheralManager.add(heartRateService)
    }
    
    func startAdvertising() {
        let heartRateServiceUUID = CBUUID(string: "180D")
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "My Heart Rate Monitor",
            CBAdvertisementDataServiceUUIDsKey: [heartRateServiceUUID]
        ])
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupPeripheral()
            startAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, 
                         didReceiveRead request: CBATTRequest) {
        // Respond to read requests
        let heartRate: UInt8 = 72
        let data = Data([0, heartRate])
        request.value = data
        peripheral.respond(to: request, withResult: .success)
    }
}
```

---

## Device Discovery

### Scanning for Devices

```swift
// ✅ Correct: Scan with service filter
func scanForSpecificDevices() {
    let heartRateServiceUUID = CBUUID(string: "180D")
    centralManager.scanForPeripherals(
        withServices: [heartRateServiceUUID],
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
    )
}

// ❌ Avoid: Scanning all devices without filter
func scanForAllDevices() {
    centralManager.scanForPeripherals(withServices: nil, options: nil)
    // Drains battery quickly and returns duplicates
}

// Implement discovery delegate
func centralManager(_ central: CBCentralManager, 
                   didDiscover peripheral: CBPeripheral, 
                   advertisementData: [String : Any], 
                   rssi RSSI: NSNumber) {
    print("Name: \(peripheral.name ?? "Unknown")")
    print("RSSI (Signal Strength): \(RSSI) dBm")
    
    // Check if this is the device we want
    if peripheral.name?.contains("Heart Rate") == true {
        discoveredPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
}
```

---

## Connection Management

### Connecting and Disconnecting

```swift
import CoreBluetooth

class BluetoothConnectionManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        // ✅ Correct: Stop scanning before connecting
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnectPeripheral() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - Connection Callbacks
    
    func centralManager(_ central: CBCentralManager, 
                       didConnect peripheral: CBPeripheral) {
        print("✅ Connected to \(peripheral.name ?? "Unknown")")
        
        // Discover services after connection
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didFailToConnect peripheral: CBPeripheral, 
                       error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDisconnectPeripheral peripheral: CBPeripheral, 
                       error: Error?) {
        print("⚠️ Disconnected: \(error?.localizedDescription ?? "User initiated")")
        connectedPeripheral = nil
    }
}
```

### Service and Characteristic Discovery

```swift
// MARK: - Service Discovery

func peripheral(_ peripheral: CBPeripheral, 
                didDiscoverServices error: Error?) {
    if let error = error {
        print("❌ Service discovery failed: \(error)")
        return
    }
    
    guard let services = peripheral.services else { return }
    
    for service in services {
        print("Found service: \(service.uuid)")
        // Discover characteristics for this service
        peripheral.discoverCharacteristics(nil, for: service)
    }
}

// MARK: - Characteristic Discovery

func peripheral(_ peripheral: CBPeripheral, 
                didDiscoverCharacteristicsFor service: CBService, 
                error: Error?) {
    if let error = error {
        print("❌ Characteristic discovery failed: \(error)")
        return
    }
    
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
        print("Found characteristic: \(characteristic.uuid)")
        
        // Subscribe to notifications if available
        if characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
}
```

---

## Reading and Writing Data

### Reading Values

```swift
// ✅ Correct: Read characteristic value
func readHeartRate(characteristic: CBCharacteristic) {
    if characteristic.properties.contains(.read) {
        peripheral.readValue(for: characteristic)
    }
}

// Receive read value
func peripheral(_ peripheral: CBPeripheral, 
                didUpdateValueFor characteristic: CBCharacteristic, 
                error: Error?) {
    if let error = error {
        print("❌ Read failed: \(error)")
        return
    }
    
    guard let data = characteristic.value else { return }
    
    // Parse heart rate value (first byte is flags, second is BPM)
    let heartRate = data.count > 1 ? data[1] : 0
    print("Heart Rate: \(heartRate) BPM")
}
```

### Writing Values

```swift
// ✅ Correct: Write control point command
func writeHeartRateControlPoint(_ peripheral: CBPeripheral, 
                               characteristic: CBCharacteristic,
                               command: UInt8) {
    let data = Data([command])
    
    if characteristic.properties.contains(.writeWithoutResponse) {
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    } else if characteristic.properties.contains(.write) {
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// Receive write confirmation
func peripheral(_ peripheral: CBPeripheral, 
                didWriteValueFor characteristic: CBCharacteristic, 
                error: Error?) {
    if let error = error {
        print("❌ Write failed: \(error)")
    } else {
        print("✅ Value written successfully")
    }
}
```

### Subscribing to Notifications

```swift
// ✅ Correct: Enable notifications for real-time updates
func subscribeToHeartRateUpdates(characteristic: CBCharacteristic) {
    if characteristic.properties.contains(.notify) {
        peripheral.setNotifyValue(true, for: characteristic)
    }
}

// Receive continuous updates
func peripheral(_ peripheral: CBPeripheral, 
                didUpdateNotificationStateFor characteristic: CBCharacteristic, 
                error: Error?) {
    if let error = error {
        print("❌ Notification subscription failed: \(error)")
        return
    }
    
    if characteristic.isNotifying {
        print("✅ Subscribed to notifications")
    } else {
        print("⚠️ Unsubscribed from notifications")
    }
}
```

---

## ✅ Best Practices

### Practice 1: Always Check Bluetooth State

**DO:**
```swift
func startBluetooth() {
    // Check state before scanning
    guard centralManager.state == .poweredOn else {
        print("Bluetooth not available")
        return
    }
    centralManager.scanForPeripherals(withServices: nil, options: nil)
}
```

### Practice 2: Use Service UUIDs to Filter Devices

**DO:**
```swift
let heartRateServiceUUID = CBUUID(string: "180D")
centralManager.scanForPeripherals(
    withServices: [heartRateServiceUUID],
    options: nil
)
// Reduces power consumption and returns only relevant devices
```

### Practice 3: Stop Scanning When Not Needed

**DO:**
```swift
func stopBluetooth() {
    centralManager.stopScan()
    // Saves battery immediately
}
```

### Practice 4: Handle Disconnections Gracefully

**DO:**
```swift
func centralManager(_ central: CBCentralManager, 
                   didDisconnectPeripheral peripheral: CBPeripheral, 
                   error: Error?) {
    // Attempt to reconnect or notify user
    if shouldAutoReconnect {
        central.connect(peripheral, options: nil)
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Not Stopping Scan

**WRONG:**
```swift
// Scanning continuously without stopping
func continuousScanning() {
    Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    // Drains battery drastically
}
```

**CORRECT:**
```swift
// Scan when needed, stop when done
func smartScanning() {
    centralManager.scanForPeripherals(withServices: nil, options: nil)
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        self.centralManager.stopScan()
    }
}
```

### Mistake 2: Ignoring Peripheral State

**WRONG:**
```swift
func readWithoutCheckingState() {
    peripheral.readValue(for: characteristic)
    // May fail if peripheral is not connected
}
```

**CORRECT:**
```swift
func readWithStateCheck() {
    guard peripheral.state == .connected else {
        print("Peripheral not connected")
        return
    }
    peripheral.readValue(for: characteristic)
}
```

### Mistake 3: Not Retaining Peripheral Reference

**WRONG:**
```swift
func connectToScannedDevice() {
    var discoveredPeripheral: CBPeripheral? // Local variable
    
    func didDiscoverDevice(_ peripheral: CBPeripheral) {
        discoveredPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    } // discoveredPeripheral deallocated!
}
```

**CORRECT:**
```swift
class BluetoothManager {
    var discoveredPeripheral: CBPeripheral? // Instance variable
    
    func connectToScannedDevice(_ peripheral: CBPeripheral) {
        self.discoveredPeripheral = peripheral // Retained
        centralManager.connect(peripheral, options: nil)
    }
}
```

---

## 🔗 Related Topics

- [Core Location](./core-location.md) - Combining location with proximity services
- [Background Modes](../04-app-lifecycle/background-modes.md) - Maintaining BLE in background
- [Networking and APIs](../03-networking/api-authentication.md) - Sending BLE data to servers
- [UserDefaults](../01-fundamentals/userdefaults.md) - Storing paired device information

---

**Master Bluetooth integration for building connected iOS experiences!**
