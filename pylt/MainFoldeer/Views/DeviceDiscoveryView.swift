import SwiftUI

struct DeviceDiscoveryView: View {
    @StateObject private var discoveryService = LGDiscoveryService()
    @Binding var selectedDevice: LGDevice?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Text("Найти телевизор")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                if discoveryService.isScanning {
                    // Scanning indicator
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Сканирование сети...")
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
                        
                        Text("Устройства не найдены")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Убедитесь, что телевизор включен\nи подключен к той же Wi-Fi сети")
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
                                    selectedDevice = device
                                    dismiss()
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
                        Text(discoveryService.isScanning ? "Сканирование..." : "Сканировать снова")
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
        .onAppear {
            discoveryService.startDiscovery()
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
