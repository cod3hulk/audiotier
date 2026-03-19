import Foundation

struct DeviceConfig: Codable {
    var audioInput: [String]
    var audioOutput: [String]

    static let configDir: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/audiotier")
    }()

    static let configFile: URL = {
        configDir.appendingPathComponent("config.json")
    }()

    static func load() -> DeviceConfig {
        guard FileManager.default.fileExists(atPath: configFile.path),
              let data = try? Data(contentsOf: configFile),
              let config = try? JSONDecoder().decode(DeviceConfig.self, from: data) else {
            return defaultConfig()
        }
        return config
    }

    func save() {
        try? FileManager.default.createDirectory(
            at: DeviceConfig.configDir, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) {
            try? data.write(to: DeviceConfig.configFile)
        }
    }

    static func defaultConfig() -> DeviceConfig {
        // Generate default config from currently connected devices
        let audio = AudioManager.shared
        let inputs = audio.getInputDevices().map { $0.name }
        let outputs = audio.getOutputDevices().map { $0.name }
        let config = DeviceConfig(audioInput: inputs, audioOutput: outputs)
        config.save()
        return config
    }
}
