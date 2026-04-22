import Foundation

/// Shared data model for communication between the main app and the widget extension.
/// Data is stored in a shared App Group UserDefaults container.
enum PortFreeShared {
    static let appGroupID = "group.JINGZHE.PortFree"
    static let portsKey = "sharedListeningPorts"
    static let lastUpdatedKey = "sharedLastUpdated"

    struct PortEntry: Codable {
        let port: Int
        let processName: String
        let pid: Int
        let user: String
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func savePorts(_ ports: [PortEntry]) {
        guard let defaults = sharedDefaults else { return }
        if let data = try? JSONEncoder().encode(ports) {
            defaults.set(data, forKey: portsKey)
            defaults.set(Date().timeIntervalSince1970, forKey: lastUpdatedKey)
        }
    }

    static func loadPorts() -> [PortEntry] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: portsKey),
              let ports = try? JSONDecoder().decode([PortEntry].self, from: data)
        else { return [] }
        return ports
    }

    static func lastUpdated() -> Date? {
        guard let defaults = sharedDefaults else { return nil }
        let ts = defaults.double(forKey: lastUpdatedKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }
}
