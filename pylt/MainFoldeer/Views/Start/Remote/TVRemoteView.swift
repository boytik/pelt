import SwiftUI

struct RemoteView: View {
    @State private var controlService: LGTVControlService?
    @State private var selectedDevice: LGDevice?
    @State private var showDeviceDiscovery = false
    @State private var showConnectionStatus = false
    
    init(device: LGDevice? = nil) {
        _selectedDevice = State(initialValue: device)
        if let device = device {
            _controlService = State(initialValue: LGTVControlService(device: device))
        }
    }
    
    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Device status bar
                deviceStatusBar
                
                // Power button
                IconButton(asset: "TurnOn", width: 70, height: 70) {
                    sendCommand(.powerOff)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                // 🎬 Hulu / Netflix / YouTube
                HStack(spacing: 20) {
                    IconButton(asset: "HuluButton", width: 98, height: 63) {
                        launchApp(.hulu)
                    }
                    IconButton(asset: "NetflixButton", width: 98, height: 63) {
                        launchApp(.netflix)
                    }
                    IconButton(asset: "YouTubeButton", width: 98, height: 63) {
                        launchApp(.youtube)
                    }
                }
                
                // 🔘 Центральный круг с навигацией
                ZStack {
                    IconButton(asset: "RoundIpne", width: 248, height: 248)
                    
                    // Overlay navigation buttons
                    VStack {
                        // Up
                        Button(action: { sendCommand(.up) }) {
                            Color.clear
                                .frame(width: 60, height: 60)
                        }
                        
                        HStack {
                            // Left
                            Button(action: { sendCommand(.left) }) {
                                Color.clear
                                    .frame(width: 60, height: 60)
                            }
                            
                            Spacer()
                            
                            // OK (center)
                            Button(action: { sendCommand(.ok) }) {
                                Color.clear
                                    .frame(width: 80, height: 80)
                            }
                            
                            Spacer()
                            
                            // Right
                            Button(action: { sendCommand(.right) }) {
                                Color.clear
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .frame(width: 248)
                        
                        // Down
                        Button(action: { sendCommand(.down) }) {
                            Color.clear
                                .frame(width: 60, height: 60)
                        }
                    }
                    .frame(width: 248, height: 248)
                }
                .padding(.vertical, 8)
                
                // 🔹 Ряд 1: Back / Stop / 123 / Home
                HStack(spacing: 20) {
                    IconButton(asset: "1.1", width: 66, height: 66) {
                        sendCommand(.back)
                    }
                    IconButton(asset: "1.2", width: 66, height: 66) {
                        sendCommand(.stop)
                    }
                    IconButton(asset: "1.3", width: 66, height: 66) {
                        // Show number pad
                    }
                    IconButton(asset: "1.4", width: 66, height: 66) {
                        sendCommand(.home)
                    }
                }
                
                // 🔸 Второй блок: Volume / Media / Channel
                HStack(alignment: .top, spacing: 20) {
                    // Volume - вертикальная кнопка с двумя зонами
                    DualVerticalButton(
                        asset: "2.1",
                        width: 66,
                        height: 143,
                        onTopTap: { sendCommand(.volumeUp) },
                        onBottomTap: { sendCommand(.volumeDown) }
                    )
                    
                    // Media controls
                    VStack(spacing: 11) {
                        IconButton(asset: "2.2", width: 66, height: 66) {
                            sendCommand(.mute)
                        }
                        IconButton(asset: "3.2", width: 66, height: 66) {
                            sendCommand(.rewind)
                        }
                    }
                    
                    VStack(spacing: 11) {
                        IconButton(asset: "2.3", width: 66, height: 66) {
                            sendCommand(.play)
                        }
                        IconButton(asset: "3.3", width: 66, height: 66) {
                            sendCommand(.fastForward)
                        }
                    }
                    
                    // Channel - вертикальная кнопка с двумя зонами
                    DualVerticalButton(
                        asset: "2.4",
                        width: 66,
                        height: 143,
                        onTopTap: { sendCommand(.channelUp) },
                        onBottomTap: { sendCommand(.channelDown) }
                    )
                }
                
                // Device selection button
                Button(action: {
                    showDeviceDiscovery = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "tv.and.hifispeaker.fill")
                            .font(.system(size: 18, weight: .medium))
                        
                        if let device = selectedDevice {
                            Text(device.name)
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            Text("Connect your device")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
            .padding(.bottom, 140) // Increased space above tab bar
            
            // Connection status overlay
            if showConnectionStatus {
                connectionStatusOverlay
            }
        }
        .sheet(isPresented: $showDeviceDiscovery) {
            DeviceDiscoveryView(selectedDevice: $selectedDevice)
        }
        .onChange(of: selectedDevice) { newDevice in
            if let device = newDevice {
                // Disconnect old service
                controlService?.disconnect()
                
                // Create new control service with selected device
                let service = LGTVControlService(device: device)
                controlService = service
                
                // Connect to device
                Task { @MainActor in
                    service.connect()
                }
            }
        }
        .onAppear {
            // Only auto-connect if device is already selected
            if let service = controlService, !service.isConnected {
                Task { @MainActor in
                    service.connect()
                }
            }
        }
    }
    
    // MARK: - Device Status Bar
    
    private var deviceStatusBar: some View {
        HStack {
            // Device name or "Not connected"
            if let device = selectedDevice {
                HStack(spacing: 8) {
                    Circle()
                        .fill(controlService?.isPaired == true ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(device.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text("Not connected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Connection Status Overlay
    
    private var connectionStatusOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                if let error = controlService?.errorMessage {
                    Text("Error: \(error)")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                } else if controlService?.isPaired == true {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                } else if controlService?.isConnected == true {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Connecting...")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            // Auto-hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showConnectionStatus = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func sendCommand(_ command: LGCommand) {
        guard let service = controlService, service.isPaired else {
            showConnectionStatus = true
            return
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        service.sendCommand(command)
    }
    
    private func launchApp(_ command: LGCommand) {
        guard let service = controlService, service.isPaired else {
            showConnectionStatus = true
            return
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        service.sendCommand(command)
    }
}

// MARK: - Универсальная кнопка с фиксированным размером

private struct IconButton: View {
    let asset: String
    let width: CGFloat
    let height: CGFloat
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: { action?() }) {
            Image(asset)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: width, height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Вертикальная кнопка с двумя зонами нажатия

private struct DualVerticalButton: View {
    let asset: String
    let width: CGFloat
    let height: CGFloat
    let onTopTap: () -> Void
    let onBottomTap: () -> Void
    
    var body: some View {
        ZStack {
            // Фоновое изображение
            Image(asset)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: width, height: height)
            
            // Две невидимые кнопки для верхней и нижней части
            VStack(spacing: 0) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onTopTap()
                }) {
                    Color.clear
                        .frame(width: width, height: height / 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onBottomTap()
                }) {
                    Color.clear
                        .frame(width: width, height: height / 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Preview

#Preview {
    RemoteView()
}
