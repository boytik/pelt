import Foundation
import Network

// MARK: - LG TV Discovery Service

@MainActor
class LGDiscoveryService: ObservableObject {
    @Published var discoveredDevices: [LGDevice] = []
    @Published var isScanning = false
    
    private var udpSocket: NWConnection?
    private let ssdpAddress = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    
    // SSDP search message for LG TVs
    private let ssdpSearchMessage = """
    M-SEARCH * HTTP/1.1\r
    HOST: 239.255.255.250:1900\r
    MAN: "ssdp:discover"\r
    MX: 3\r
    ST: urn:lge-com:service:webos-second-screen:1\r
    \r
    """
    
    init() {}
    
    // MARK: - Start Discovery
    
    func startDiscovery() {
        guard !isScanning else { return }
        
        isScanning = true
        discoveredDevices.removeAll()
        
        // Setup UDP multicast
        setupUDPSocket()
        sendSSDPSearch()
        
        // Stop after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await stopDiscovery()
        }
    }
    
    // MARK: - Stop Discovery
    
    func stopDiscovery() {
        isScanning = false
        udpSocket?.cancel()
        udpSocket = nil
    }
    
    // MARK: - Setup UDP Socket
    
    private func setupUDPSocket() {
        let host = NWEndpoint.Host(ssdpAddress)
        let port = NWEndpoint.Port(rawValue: ssdpPort)!
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        udpSocket = NWConnection(host: host, port: port, using: parameters)
        
        udpSocket?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ UDP Socket ready")
                Task { @MainActor in
                    self?.receiveMessages()
                }
            case .failed(let error):
                print("❌ UDP Socket failed: \(error)")
            default:
                break
            }
        }
        
        udpSocket?.start(queue: .main)
    }
    
    // MARK: - Send SSDP Search
    
    private func sendSSDPSearch() {
        guard let data = ssdpSearchMessage.data(using: .utf8) else { return }
        
        udpSocket?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Failed to send SSDP search: \(error)")
            } else {
                print("📡 SSDP search sent")
            }
        })
    }
    
    // MARK: - Receive Messages
    
    private func receiveMessages() {
        udpSocket?.receiveMessage { [weak self] data, _, _, error in
            guard let self = self, let data = data else {
                if let error = error {
                    print("❌ Receive error: \(error)")
                }
                return
            }
            
            if let response = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self.parseSSDPResponse(response)
                }
            }
            
            // Continue receiving
            Task { @MainActor in
                self.receiveMessages()
            }
        }
    }
    
    // MARK: - Parse SSDP Response
    
    private func parseSSDPResponse(_ response: String) {
        print("📥 SSDP Response received")
        
        // Check if it's an LG TV
        guard response.contains("LG") || response.contains("webOS") else {
            return
        }
        
        var ipAddress: String?
        var modelName: String?
        var deviceName: String?
        
        // Parse response headers
        let lines = response.components(separatedBy: "\r\n")
        for line in lines {
            let components = line.components(separatedBy: ": ")
            guard components.count == 2 else { continue }
            
            let key = components[0].uppercased()
            let value = components[1]
            
            switch key {
            case "LOCATION":
                // Extract IP from URL like http://192.168.1.100:3000/
                if let url = URL(string: value),
                   let host = url.host {
                    ipAddress = host
                }
            case "SERVER":
                modelName = value
            case "USN":
                // Extract model from USN
                if value.contains("LG") {
                    deviceName = "LG TV"
                }
            default:
                break
            }
        }
        
        // Create device if we found IP
        if let ip = ipAddress {
            let device = LGDevice(
                name: deviceName ?? "LG WebOS TV",
                ipAddress: ip,
                port: 3000,
                modelName: modelName
            )
            
            // Add if not already discovered
            if !discoveredDevices.contains(where: { $0.ipAddress == device.ipAddress }) {
                discoveredDevices.append(device)
                print("✅ Found LG TV: \(ip)")
            }
        }
    }
}
