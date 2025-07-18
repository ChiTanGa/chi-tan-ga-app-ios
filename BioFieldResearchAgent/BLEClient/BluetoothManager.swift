//
//  BLEManager.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 31.05.2025.
//
import CoreBluetooth

// MARK: - UUID Definitions
// These UUIDs must match the ones defined in your ESP32 code.
let SERVICE_UUID_ADS1256_1 = CBUUID(string:    "A0B1C2D3-E4F5-4678-9012-3456789ACE00")
let CHAR_UUID_ADS1_MODE    = CBUUID(string:    "A0B1C2D3-E4F5-4678-9012-3456789ACE01")
let CHAR_UUID_ADS1_BITRATE = CBUUID(string:    "A0B1C2D3-E4F5-4678-9012-3456789ACE02")
let CHAR_UUID_ADS1_RESOLUTION = CBUUID(string: "A0B1C2D3-E4F5-4678-9012-3456789ACE03")
let CHAR_UUID_ADS1_CH1_GAIN = CBUUID(string:   "A0B1C2D3-E4F5-4678-9012-3456789ACE04")
let CHAR_UUID_ADS1_STREAM_CONTROL  = CBUUID(string:  "A0B1C2D3-E4F5-4678-9012-3456789ACE0C")
let CHAR_UUID_ADS1_SENSOR_DATA    = CBUUID(string:   "A0B1C2D3-E4F5-4678-9012-3456789ACE0D")

let SERVICE_UUID_ADS1256_2 = CBUUID(string:    "A0B1C2D3-E4F5-4678-9012-3456789ACF00")
let CHAR_UUID_ADS2_MODE  = CBUUID(string:      "A0B1C2D3-E4F5-4678-9012-3456789ACF01")
let CHAR_UUID_ADS2_BITRATE = CBUUID(string:    "A0B1C2D3-E4F5-4678-9012-3456789ACF02")
let CHAR_UUID_ADS2_RESOLUTION = CBUUID(string: "A0B1C2D3-E4F5-4678-9012-3456789ACF03")
let CHAR_UUID_ADS2_CH1_GAIN = CBUUID(string:   "A0B1C2D3-E4F5-4678-9012-3456789ACF04")
let CHAR_UUID_ADS2_STREAM_CONTROL   = CBUUID(string:   "A0B1C2D3-E4F5-4678-9012-3456789ACF0C")
let CHAR_UUID_ADS2_SENSOR_DATA      = CBUUID(string:   "A0B1C2D3-E4F5-4678-9012-3456789ACF0D")

// Array of all ADS1256 service UUIDs to scan for
let ADS_SERVICE_UUIDS: [CBUUID] = [SERVICE_UUID_ADS1256_1, SERVICE_UUID_ADS1256_2]
let ADS_SERVICE_CHARACTERISTICS: [CBUUID] = [CHAR_UUID_ADS1_MODE, CHAR_UUID_ADS1_BITRATE, CHAR_UUID_ADS1_RESOLUTION, CHAR_UUID_ADS1_CH1_GAIN, CHAR_UUID_ADS1_STREAM_CONTROL, CHAR_UUID_ADS1_SENSOR_DATA, CHAR_UUID_ADS2_MODE, CHAR_UUID_ADS2_BITRATE, CHAR_UUID_ADS2_RESOLUTION, CHAR_UUID_ADS2_CH1_GAIN, CHAR_UUID_ADS2_STREAM_CONTROL, CHAR_UUID_ADS2_SENSOR_DATA]
let ADS_STREAM_CONTROL_CHARS: [CBUUID] = [CHAR_UUID_ADS1_STREAM_CONTROL, CHAR_UUID_ADS2_STREAM_CONTROL]
let ADS_SENSOR_DATA_CHARS: [CBUUID] = [CHAR_UUID_ADS1_SENSOR_DATA, CHAR_UUID_ADS2_SENSOR_DATA]

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [BLEDevice] = []
    @Published var connectedDevice: BLEDevice?
    @Published var isScanning: Bool = false
    @Published var connectionStatusMessage: String = ""

    private var centralManager: CBCentralManager!
    private var peripheralsDict: [UUID: CBPeripheral] = [:] // Map UUID to CBPeripheral for quick lookup
    private var currentConnectingPeripheral: CBPeripheral?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: Central Manager Delegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState called. Current state: \(central.state.rawValue)") // Use rawValue for debugging
        
        if central.state == .poweredOn {
            connectionStatusMessage = "Bluetooth is ON. Ready to scan."
        } else {
            connectionStatusMessage = "Bluetooth is not available: \(central.state.rawValue)"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let deviceName = peripheral.name, deviceName.contains("ESP32_MultiDevice_Gateway") {
            // Only add if not already in the list
            if !discoveredDevices.contains(where: { $0.id == peripheral.identifier }) {
                let newDevice = BLEDevice(id: peripheral.identifier, peripheral: peripheral, name: deviceName, advertisementData: advertisementData, rssi: RSSI)
                discoveredDevices.append(newDevice)
                peripheralsDict[peripheral.identifier] = peripheral
                print("Discovered ESP32 Gateway: \(deviceName)")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        DispatchQueue.main.async {
            self.connectionStatusMessage = "Connected to \(peripheral.name ?? "Unknown Device")"
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                // Create a mutable copy of the device at the found index
                var updatedDevice = self.discoveredDevices[index]
                updatedDevice.isConnected = true

                // Replace the old device with the updated device in the array
                self.discoveredDevices[index] = updatedDevice

                // Set the connectedDevice
                self.connectedDevice = updatedDevice // Or self.discoveredDevices[index]

                // Set the peripheral's delegate to self to receive service/characteristic discovery callbacks
                peripheral.delegate = self
                // Discover services for the connected peripheral
                peripheral.discoverServices(ADS_SERVICE_UUIDS) // Discover only relevant ADS services
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device"): \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
            self.connectionStatusMessage = "Failed to connect to \(peripheral.name ?? "Unknown Device")."
            self.currentConnectingPeripheral = nil
            if var failedDevice = self.discoveredDevices.first(where: { $0.id == peripheral.identifier }) {
                failedDevice.isConnected = false
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device"): \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
            self.connectionStatusMessage = "Disconnected from \(peripheral.name ?? "Unknown Device")"
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredDevices[index].isConnected = false
                self.discoveredDevices[index].services = [] // Clear services on disconnect
            }
            if self.connectedDevice?.id == peripheral.identifier {
                self.connectedDevice = nil
            }
        }
    }

    // MARK: Peripheral Delegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            print("Error discovering services: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        DispatchQueue.main.async {
            // Find the index of the connected device in the discoveredDevices array
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                // Get a mutable copy of the device from the array
                var deviceToUpdate = self.discoveredDevices[index]

                deviceToUpdate.services.removeAll() // Clear existing services for this device

                for cbService in services {
                    // Check if it's one of our expected ADS services
                    if ADS_SERVICE_UUIDS.contains(cbService.uuid) {
                        let serviceName = self.nameForServiceUUID(cbService.uuid)
                        let newService = BLEService(cbService: cbService, name: serviceName)
                        deviceToUpdate.services.append(newService)
                        print("Discovered service: \(serviceName) (\(cbService.uuid.uuidString)) for device: \(peripheral.name ?? "Unknown")")
                        
                        // Discover characteristics for this service
                        peripheral.discoverCharacteristics(ADS_SERVICE_CHARACTERISTICS, for: cbService)
                    }
                }
                
                // Update the device in the discoveredDevices array
                self.discoveredDevices[index] = deviceToUpdate
                
                // Also update self.connectedDevice if it's still pointing to the same peripheral
                // This is important because connectedDevice is a Published property and needs to reflect the latest state
                if self.connectedDevice?.id == peripheral.identifier {
                    self.connectedDevice = deviceToUpdate
                }
            } else {
                print("Error: Connected device not found in discoveredDevices for peripheral \(peripheral.name ?? "Unknown Device")")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            print("Error discovering characteristics for service \(service.uuid.uuidString): \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        DispatchQueue.main.async {
            // 1. Find the index of the relevant device in discoveredDevices
            if let deviceIndex = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                // Get a mutable copy of the device from the array
                var deviceToUpdate = self.discoveredDevices[deviceIndex]

                // 2. Find the index of the relevant service within that device
                if let serviceIndex = deviceToUpdate.services.firstIndex(where: { $0.cbService.uuid == service.uuid }) {
                    // Get a mutable copy of the service from the device's services array
                    var serviceToUpdate = deviceToUpdate.services[serviceIndex]

                    serviceToUpdate.characteristics.removeAll() // Clear existing characteristics
                    for cbCharacteristic in characteristics {
                        let charName = self.nameForCharacteristicUUID(cbCharacteristic.uuid)
                        let newChar = BLECharacteristic(cbCharacteristic: cbCharacteristic, name: charName)
                        serviceToUpdate.characteristics.append(newChar)
                        print("  Discovered characteristic for \(serviceToUpdate.name): \(charName) (\(cbCharacteristic.uuid.uuidString))")

                        if ADS_SERVICE_CHARACTERISTICS.contains(cbCharacteristic.uuid) {
                            // Read initial characteristic values (bitrate, resolution,..)
                            if cbCharacteristic.properties.contains(.read) {
                                peripheral.readValue(for: cbCharacteristic)
                            }
                            
                            // Check if we should be notified about changes of characteristic value
                            if cbCharacteristic.properties.contains(.notify) {
                                peripheral.setNotifyValue(true, for: cbCharacteristic)
                                print("  Enabled notifications for characteristic: \(charName)")
                            }
                        }
                    }

                    // 3. Update the service within the device's services array
                    deviceToUpdate.services[serviceIndex] = serviceToUpdate

                    // 4. Update the device back in the discoveredDevices array
                    self.discoveredDevices[deviceIndex] = deviceToUpdate

                    // 5. Also update self.connectedDevice if it's still pointing to this peripheral
                    if self.connectedDevice?.id == peripheral.identifier {
                        self.connectedDevice = deviceToUpdate
                    }
                } else {
                    print("Error: Service \(service.uuid.uuidString) not found in device \(peripheral.name ?? "Unknown Device")'s services.")
                }
            } else {
                print("Error: Connected device not found in discoveredDevices for peripheral \(peripheral.name ?? "Unknown Device")")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }

        guard let value = characteristic.value else {
            print("No value for characteristic: \(characteristic.uuid.uuidString)")
            return
        }

        DispatchQueue.main.async {
            // 1. Find the index of the relevant device in discoveredDevices
            if let deviceIndex = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                // Get a mutable copy of the device from the array
                var deviceToUpdate = self.discoveredDevices[deviceIndex]

                // 2. Find the index of the relevant service within that device
                // Note: characteristic.service! is generally safe here because the characteristic
                // *must* belong to a service to be updated.
                if let serviceIndex = deviceToUpdate.services.firstIndex(where: { $0.cbService.uuid == characteristic.service!.uuid }) {
                    // Get a mutable copy of the service from the device's services array
                    var serviceToUpdate = deviceToUpdate.services[serviceIndex]

                    let serviceName = serviceToUpdate.name // Use the name from the mutable copy

                    if characteristic.uuid == CHAR_UUID_ADS1_BITRATE || characteristic.uuid == CHAR_UUID_ADS2_BITRATE {
                        if value.count >= MemoryLayout<Int32>.size { // Ensure enough bytes are available
                            let bitrateValue = value.withUnsafeBytes { $0.load(as: Int32.self) }
                            serviceToUpdate.bitrate = "\(bitrateValue) SPS"
                            print("  \(serviceName) Bitrate: \(bitrateValue) SPS")
                        } else {
                            serviceToUpdate.bitrate = "Error (Invalid Data Length)"
                            print("  \(serviceName) Bitrate: Error (Invalid Data Length)")
                        }
                    } else if characteristic.uuid == CHAR_UUID_ADS1_RESOLUTION || characteristic.uuid == CHAR_UUID_ADS2_RESOLUTION {
                        if let resolutionValue = value.first { // Assuming it's a single byte (UInt8)
                            serviceToUpdate.resolution = "\(resolutionValue) bits"
                            print("  \(serviceName) Resolution: \(resolutionValue) bits")
                        } else {
                            serviceToUpdate.resolution = "Error"
                        }
                    } else if ADS_STREAM_CONTROL_CHARS.contains(characteristic.uuid) {
                        if let isStreaming = value.first { // Assuming it's a single byte (UInt8)
                            serviceToUpdate.isStreaming = isStreaming > 0 ? true : false
                            print("  \(serviceName) is streaming: \(isStreaming)")
                        }
                    } else if ADS_SENSOR_DATA_CHARS.contains(characteristic.uuid) {
                        // Read here to new struct for CBOR data
                        do {
                            let sensorData = try ADSSensorData(fromCBOR: value)
                            print("CBOR Decoded: res=\(sensorData.resolution), cmp=\(sensorData.compression), t=\(sensorData.time), bin.count=\(sensorData.binaryData.count) num.count=\(sensorData.decodedReadingNumbers.count)")
                            print(" Average Reading: \(sensorData.decodedReadingNumbers.reduce(0, +) / UInt32(sensorData.decodedReadingNumbers.count))")
                        } catch {
                            print("CBOR decode error: \(error)")
                        }
                    }

                    // 3. Update the service within the device's services array
                    deviceToUpdate.services[serviceIndex] = serviceToUpdate

                    // 4. Update the device back in the discoveredDevices array
                    self.discoveredDevices[deviceIndex] = deviceToUpdate

                    // 5. Also update self.connectedDevice if it's still pointing to this peripheral
                    if self.connectedDevice?.id == peripheral.identifier {
                        self.connectedDevice = deviceToUpdate
                    }
                } else {
                    print("Error: Service for characteristic \(characteristic.uuid.uuidString) not found in device \(peripheral.name ?? "Unknown Device")'s services.")
                }
            } else {
                print("Error: Connected device not found in discoveredDevices for peripheral \(peripheral.name ?? "Unknown Device")")
            }
        }
    }
    // MARK: Public Methods

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatusMessage = "Bluetooth is not powered on."
            return
        }
        discoveredDevices.removeAll()
        peripheralsDict.removeAll()
        isScanning = true
        connectionStatusMessage = "Scanning for BLE devices..."
        // Scan for all devices that advertise the ADS1256 service UUIDs
        centralManager.scanForPeripherals(withServices: ADS_SERVICE_UUIDS, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        print("BLE Scanning started...")
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        connectionStatusMessage = "Scanning stopped."
        print("BLE Scanning stopped.")
    }

    func connect(to device: BLEDevice) {
        stopScanning() // Stop scanning before connecting
        currentConnectingPeripheral = device.peripheral
        centralManager.connect(device.peripheral, options: nil)
        connectionStatusMessage = "Connecting to \(device.name)..."
    }

    func disconnect(from device: BLEDevice) {
        centralManager.cancelPeripheralConnection(device.peripheral)
    }
    
    func controlStreaming(device: BLEDevice, service: BLEService, start: Bool) {
        guard let streamingContronCharacteristic: BLECharacteristic = service.characteristics.first(where: { ADS_STREAM_CONTROL_CHARS.contains( $0.cbCharacteristic.uuid) }) else {
            print("No streaming control characteristic for service: \(service.cbService.uuid.uuidString)")
            return
        }
        let data = start ? Data([0x0001]) : Data([0x0000])
        device.peripheral.writeValue(data, for: streamingContronCharacteristic.cbCharacteristic, type: .withResponse)
    }

    // MARK: Helper Methods for UUID to Name Mapping

    private func nameForServiceUUID(_ uuid: CBUUID) -> String {
        if uuid == SERVICE_UUID_ADS1256_1 {
            return "ADS1256_1"
        } else if uuid == SERVICE_UUID_ADS1256_2 {
            return "ADS1256_2"
        }
        return uuid.uuidString
    }

    private func nameForCharacteristicUUID(_ uuid: CBUUID) -> String {
        switch uuid {
        case CHAR_UUID_ADS1_MODE: return "ADS1 Mode"
        case CHAR_UUID_ADS1_BITRATE: return "ADS1 Bitrate"
        case CHAR_UUID_ADS1_RESOLUTION: return "ADS1 Resolution"
        case CHAR_UUID_ADS1_CH1_GAIN: return "ADS1 Ch1 Gain"
        case CHAR_UUID_ADS1_STREAM_CONTROL: return "ADS1 Stream Control"
        case CHAR_UUID_ADS1_SENSOR_DATA: return "ADS1 Sensor Data"
        case CHAR_UUID_ADS2_MODE: return "ADS2 Mode"
        case CHAR_UUID_ADS2_BITRATE: return "ADS2 Bitrate"
        case CHAR_UUID_ADS2_RESOLUTION: return "ADS2 Resolution"
        case CHAR_UUID_ADS2_CH1_GAIN: return "ADS2 Ch1 Gain"
        case CHAR_UUID_ADS2_STREAM_CONTROL: return "ADS2 Stream Control"
        case CHAR_UUID_ADS2_SENSOR_DATA: return "ADS2 Sensor Data"
        default: return uuid.uuidString
        }
    }
}
