import Foundation

// MARK: - LG Device Model

struct LGDevice: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let ipAddress: String
    let port: Int
    let modelName: String?
    
    init(id: String = UUID().uuidString,
         name: String,
         ipAddress: String,
         port: Int = 3000,
         modelName: String? = nil) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.modelName = modelName
    }
    
    // Equatable conformance for .onChange()
    static func == (lhs: LGDevice, rhs: LGDevice) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - WebOS Command

enum LGCommand: String {
    // Power
    case powerOn = "ssap://system/turnOn"
    case powerOff = "ssap://system/turnOff"
    
    // Navigation - FIXED: были неправильные значения
    case up = "UP"
    case down = "DOWN"
    case left = "LEFT"
    case right = "RIGHT"
    case ok = "ENTER"
    case back = "BACK"
    case home = "HOME"
    
    // Volume
    case volumeUp = "ssap://audio/volumeUp"
    case volumeDown = "ssap://audio/volumeDown"
    case mute = "ssap://audio/setMute"
    
    // Channel
    case channelUp = "ssap://tv/channelUp"
    case channelDown = "ssap://tv/channelDown"
    
    // Media
    case play = "ssap://media.controls/play"
    case pause = "ssap://media.controls/pause"
    case stop = "ssap://media.controls/stop"
    case rewind = "ssap://media.controls/rewind"
    case fastForward = "ssap://media.controls/fastForward"
    
    // Apps
    case netflix = "netflix"
    case youtube = "youtube.leanback.v4"
    case hulu = "hulu"
    
    // Numbers
    case number0 = "0"
    case number1 = "1"
    case number2 = "2"
    case number3 = "3"
    case number4 = "4"
    case number5 = "5"
    case number6 = "6"
    case number7 = "7"
    case number8 = "8"
    case number9 = "9"
}

// MARK: - WebSocket Message Types

struct WebOSMessage: Codable {
    let type: String
    let id: String?
    let payload: [String: AnyCodable]?
    let uri: String?
    
    init(type: String, id: String? = nil, payload: [String: AnyCodable]? = nil, uri: String? = nil) {
        self.type = type
        self.id = id
        self.payload = payload
        self.uri = uri
    }
}

struct WebOSResponse: Codable {
    let type: String
    let id: String?
    let payload: [String: AnyCodable]?
    let error: String?
}

// MARK: - AnyCodable helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
