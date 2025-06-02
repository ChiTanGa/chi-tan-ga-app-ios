//
//  BLECore.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 31.05.2025.
//

import CoreBluetooth

/// Represents a discoverable BLE peripheral (your ESP32 Gateway).
struct BLEDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var name: String
    var services: [BLEService] = [] // Subdevices like ADS1256_1, ADS1256_2
    var isConnected: Bool = false
    var advertisementData: [String: Any]?
    var rssi: NSNumber?
}

/// Represents a BLE service, which corresponds to your "Subdevice" (e.g., ADS1256_1).
struct BLEService: Identifiable {
    let id: UUID = UUID() // Use a unique ID for SwiftUI's List
    let cbService: CBService
    var name: String
    var characteristics: [BLECharacteristic] = []
    var bitrate: String = "N/A"
    var resolution: String = "N/A"
}

/// Represents a BLE characteristic.
struct BLECharacteristic: Identifiable {
    let id: UUID = UUID() // Use a unique ID for SwiftUI's List
    let cbCharacteristic: CBCharacteristic
    var name: String
    var value: String = "N/A"
}
