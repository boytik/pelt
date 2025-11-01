import Foundation
import Network

// MARK: - LG TV Control Service

@MainActor
class LGTVControlService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isPaired = false
    @Published var errorMessage: String?
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var messageIdCounter = 0
    private var clientKey: String?
    
    private let device: LGDevice
    
    init(device: LGDevice) {
        self.device = device
        super.init()
        
        // Load saved client key if exists
        loadClientKey()
    }
    
    // MARK: - Connection
    
    func connect() {
        let wsURL = URL(string: "ws://\(device.ipAddress):\(device.port)")!
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = urlSession?.webSocketTask(with: wsURL)
        
        webSocket?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Register app
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await registerApp()
        }
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        isPaired = false
    }
    
    // MARK: - Registration
    
    private func registerApp() {
        var payload: [String: AnyCodable] = [
            "forcePairing": AnyCodable(false),
            "pairingType": AnyCodable("PROMPT"),
            "manifest": AnyCodable([
                "manifestVersion": 1,
                "appVersion": "1.0.0",
                "signed": [
                    "created": "20250101",
                    "appId": "com.lg.remote",
                    "vendorId": "com.lg",
                    "localizedAppNames": [
                        "": "LG Remote",
                        "ru-RU": "LG Пульт"
                    ],
                    "localizedVendorNames": [
                        "": "LG Electronics"
                    ],
                    "permissions": [
                        "TEST_SECURE",
                        "CONTROL_INPUT_TEXT",
                        "CONTROL_MOUSE_AND_KEYBOARD",
                        "READ_INSTALLED_APPS",
                        "READ_LGE_SDX",
                        "READ_NOTIFICATIONS",
                        "SEARCH",
                        "WRITE_SETTINGS",
                        "WRITE_NOTIFICATION_ALERT",
                        "CONTROL_POWER",
                        "READ_CURRENT_CHANNEL",
                        "READ_RUNNING_APPS",
                        "READ_UPDATE_INFO",
                        "UPDATE_FROM_REMOTE_APP",
                        "READ_LGE_TV_INPUT_EVENTS",
                        "READ_TV_CURRENT_TIME"
                    ],
                    "serial": "2f930e2d2cfe083771f68e4fe7bb07"
                ] as [String: Any]
            ] as [String: Any])
        ]
        
        // Add client key if we have one
        if let clientKey = clientKey {
            payload["client-key"] = AnyCodable(clientKey)
        }
        
        sendMessage(type: "register", payload: payload)
    }
    
    // MARK: - Send Message
    
    private func sendMessage(type: String, uri: String? = nil, payload: [String: AnyCodable]? = nil) {
        messageIdCounter += 1
        
        var messageDict: [String: Any] = [
            "type": type,
            "id": "\(messageIdCounter)"
        ]
        
        if let uri = uri {
            messageDict["uri"] = uri
        }
        
        if let payload = payload {
            messageDict["payload"] = payload.mapValues { $0.value }
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to encode message")
            return
        }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(wsMessage) { [weak self] error in
            if let error = error {
                print("❌ Send error: \(error)")
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Receive Message
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    Task { @MainActor in
                        await self.handleMessage(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            await self.handleMessage(text)
                        }
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving
                self.receiveMessage()
                
            case .failure(let error):
                print("❌ Receive error: \(error)")
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Handle Message
    
    private func handleMessage(_ text: String) {
        print("📥 Received: \(text)")
        
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        switch type {
        case "registered":
            isConnected = true
            isPaired = true
            
            // Save client key
            if let payload = json["payload"] as? [String: Any],
               let clientKey = payload["client-key"] as? String {
                self.clientKey = clientKey
                saveClientKey(clientKey)
                print("✅ Registered with client key")
            }
            
        case "response":
            if let payload = json["payload"] as? [String: Any],
               let returnValue = payload["returnValue"] as? Bool,
               !returnValue {
                print("❌ Command failed")
            }
            
        case "error":
            if let error = json["error"] as? String {
                errorMessage = error
                print("❌ Error: \(error)")
            }
            
        default:
            break
        }
    }
    
    // MARK: - Commands
    
    func sendCommand(_ command: LGCommand) {
        guard isConnected && isPaired else {
            print("❌ Not connected or paired")
            return
        }
        
        let uri = command.rawValue
        
        // For direction keys, use input socket
        if ["UP", "DOWN", "LEFT", "RIGHT", "ENTER", "BACK", "HOME"].contains(uri) {
            sendMessage(
                type: "request",
                uri: "ssap://com.webos.service.ime/sendEnterKey",
                payload: nil
            )
        }
        // For apps
        else if ["netflix", "youtube.leanback.v4", "hulu"].contains(uri) {
            launchApp(appId: uri)
        }
        // For other commands
        else {
            sendMessage(type: "request", uri: uri, payload: nil)
        }
    }
    
    func launchApp(appId: String) {
        sendMessage(
            type: "request",
            uri: "ssap://system.launcher/launch",
            payload: ["id": AnyCodable(appId)]
        )
    }
    
    func sendKey(_ key: String) {
        // Send keyboard input
        sendMessage(
            type: "request",
            uri: "ssap://com.webos.service.ime/sendEnterKey",
            payload: nil
        )
    }
    
    // MARK: - Client Key Storage
    
    private func saveClientKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "lg_client_key_\(device.ipAddress)")
    }
    
    private func loadClientKey() {
        clientKey = UserDefaults.standard.string(forKey: "lg_client_key_\(device.ipAddress)")
    }
}

// MARK: - URLSessionWebSocketDelegate

extension LGTVControlService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        Task { @MainActor in
            self.isConnected = true
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("❌ WebSocket disconnected")
        Task { @MainActor in
            self.isConnected = false
            self.isPaired = false
        }
    }
}
