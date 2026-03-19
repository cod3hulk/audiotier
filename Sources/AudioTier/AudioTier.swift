import Foundation

class AudioTier {
    static let shared = AudioTier()
    private let audio = AudioManager.shared
    private var config: DeviceConfig

    init() {
        config = DeviceConfig.load()
    }

    func reloadConfig() {
        config = DeviceConfig.load()
    }

    /// Apply priority-based switching for both input and output
    func applyPriorities() {
        applyInputPriority()
        applyOutputPriority()
    }

    func applyInputPriority() {
        let connected = audio.getInputDevices()
        let currentDefault = audio.getDefaultInputDevice()

        guard let best = bestDevice(from: config.audioInput, connected: connected) else { return }

        if best.id != currentDefault {
            if audio.setDefaultInputDevice(best.id) {
                log("Audio input → \(best.name) (\(best.transportName))")
                sendNotification(
                    title: "Audio Input Changed",
                    body: best.name
                )
            }
        }
    }

    func applyOutputPriority() {
        let connected = audio.getOutputDevices()
        let currentDefault = audio.getDefaultOutputDevice()

        guard let best = bestDevice(from: config.audioOutput, connected: connected) else { return }

        if best.id != currentDefault {
            if audio.setDefaultOutputDevice(best.id) {
                log("Audio output → \(best.name) (\(best.transportName))")
                sendNotification(
                    title: "Audio Output Changed",
                    body: best.name
                )
            }
        }
    }

    func currentStatus() -> (input: AudioDevice?, output: AudioDevice?) {
        let devices = audio.getAllDevices()
        let inputID = audio.getDefaultInputDevice()
        let outputID = audio.getDefaultOutputDevice()
        let input = devices.first { $0.id == inputID }
        let output = devices.first { $0.id == outputID }
        return (input, output)
    }

    // MARK: - Private

    private func bestDevice(from priority: [String], connected: [AudioDevice]) -> AudioDevice? {
        // Find the highest-priority device that is currently connected
        for name in priority {
            if let device = connected.first(where: { $0.name == name }) {
                return device
            }
        }
        // If no priority match, return first connected device
        return connected.first
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("[\(formatter.string(from: Date()))] \(message)")
    }

    private func sendNotification(title: String, body: String) {
        let script = """
        display notification "\(body)" with title "\(title)" sound name "Glass"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
}
