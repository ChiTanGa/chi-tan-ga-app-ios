//
//  BluetoothView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 31.05.2025.
//
import SwiftUI

struct BluetoothView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    //@State private var selectedService: BLEService?

    var body: some View {
        NavigationView {
            VStack {
                Text(bluetoothManager.connectionStatusMessage)
                    .font(.caption)
                    .padding(.bottom, 5)

                Button(action: {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScanning()
                    } else {
                        bluetoothManager.startScanning()
                    }
                }) {
                    Label(bluetoothManager.isScanning ? "Stop Scan" : "Scan Sensors", systemImage: bluetoothManager.isScanning ? "stop.circle.fill" : "magnifyingglass")
                        .font(.headline)
                        .padding()
                        .background(bluetoothManager.isScanning ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom)

                if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                    Text("No ESP32 Gateways discovered yet.")
                        .foregroundColor(.gray)
                } else {
                    List {
                        // Display the "Root-Device(s): ESP32_MultiDevice_Gateway"
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            Section(header: Text("Root-Device: \(device.name)")) {
                                if device.isConnected {
                                    if device.services.isEmpty {
                                        Text("Discovering services...")
                                    } else {
                                        ForEach(device.services) { service in
                                            VStack(alignment: .leading) {
                                                Text("Subdevice: \(service.name)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                //if selectedService?.id == service.id {
                                                    Text("Bitrate: \(service.bitrate)")
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                    Text("Resolution: \(service.resolution)")
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                    // --- Add the Toggle button here ---
                                                    Toggle(isOn: Binding(
                                                        get: { service.isStreaming },
                                                        set: { newValue in
                                                            // Find the actual service in discoveredDevices to modify its state
                                                            if let deviceIndex = bluetoothManager.discoveredDevices.firstIndex(where: { $0.id == device.id }),
                                                               let serviceIndex = bluetoothManager.discoveredDevices[deviceIndex].services.firstIndex(where: { $0.id == service.id }) {
                                                                
                                                                // Update the actual service in the published array
                                                                bluetoothManager.discoveredDevices[deviceIndex].services[serviceIndex].isStreaming = newValue
                                                                
                                                                if newValue {
                                                                    bluetoothManager.controlStreaming(device: device, service: service, start: true)
                                                                } else {
                                                                    bluetoothManager.controlStreaming(device: device, service: service, start: false)
                                                                }
                                                            }
                                                        }
                                                    )) {
                                                        Text("Start Streaming")
                                                    }
                                                }
                                        }
                                    }
                                    Button("Disconnect from \(device.name)") {
                                        bluetoothManager.disconnect(from: device)
                                        //selectedService = nil // Clear selection on disconnect
                                    }
                                    .foregroundColor(.orange)
                                } else {
                                    Button("Connect to \(device.name)") {
                                        bluetoothManager.connect(to: device)
                                    }
                                }
                            }
                        }
                    }
                    // CONDITIONAL COMPILATION FOR LIST STYLE
                    #if os(iOS)
                        .listStyle(.insetGrouped)
                    #elseif os(macOS)
                        .listStyle(.sidebar) // Or .plain, depending on your desired look
                    #else
                        .listStyle(.plain) // Default for other platforms
                    #endif
                }
            }
            .navigationTitle("BLE Sensor Gateway")
        }
    }
}
