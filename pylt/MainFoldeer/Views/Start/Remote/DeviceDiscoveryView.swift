import SwiftUI

struct DeviceDiscoveryView: View {
    @StateObject private var discoveryService = LGDiscoveryService()
    @Binding var selectedDevice: LGDevice?
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNoDevicesAlert = false
    @State private var showConnectionErrorAlert = false
    
    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Text("Find TV")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                if discoveryService.isScanning {
                    // Scanning indicator
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Scanning network...")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else if discoveryService.discoveredDevices.isEmpty {
                    // No devices found
                    VStack(spacing: 20) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No devices found")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Make sure your TV is on\nand connected to the same Wi-Fi network")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Device list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(discoveryService.discoveredDevices) { device in
                                DeviceRow(device: device) {
                                    selectDevice(device)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Scan button
                Button(action: {
                    discoveryService.startDiscovery()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                        Text(discoveryService.isScanning ? "Scanning..." : "Scan again")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.8))
                    )
                }
                .disabled(discoveryService.isScanning)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Couldn't find the devices", isPresented: $showNoDevicesAlert) {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button("Try again") {
                discoveryService.startDiscovery()
            }
        } message: {
            Text("Check the connection and try again later")
        }
        .alert("Error connecting to the selected TV", isPresented: $showConnectionErrorAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Try again") {
                if let device = selectedDevice {
                    selectDevice(device)
                }
            }
        } message: {
            Text("Check the connection and try again later")
        }
        .onAppear {
            discoveryService.startDiscovery()
        }
        .onChange(of: discoveryService.isScanning) { isScanning in
            // Show alert if scanning finished and no devices found
            if !isScanning && discoveryService.discoveredDevices.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showNoDevicesAlert = true
                }
            }
        }
    }
    
    private func selectDevice(_ device: LGDevice) {
        // Try to connect to device
        let testService = LGTVControlService(device: device)
        
        Task { @MainActor in
            testService.connect()
            
            // Wait a bit to see if connection succeeds
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            if testService.isPaired || testService.isConnected {
                // Success - set device and dismiss
                selectedDevice = device
                dismiss()
            } else {
                // Failed to connect - show error
                showConnectionErrorAlert = true
            }
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: LGDevice
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // TV Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "tv")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Device info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(device.ipAddress)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let model = device.modelName {
                        Text(model)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DeviceDiscoveryView(selectedDevice: .constant(nil))
}
