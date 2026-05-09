import CoreAudio
import XCTest
@testable import AudioTier

final class AudioTierPriorityTests: XCTestCase {
    func testReturnsHighestPriorityConnectedDevice() {
        let connected = [
            device(id: 1, name: "Built-in"),
            device(id: 2, name: "AirPods Pro"),
            device(id: 3, name: "Studio Display")
        ]
        let priority = ["Studio Display", "AirPods Pro", "Built-in"]

        let best = AudioTier.bestDevice(from: priority, connected: connected)

        XCTAssertEqual(best?.name, "Studio Display")
    }

    func testSkipsPriorityEntriesThatAreNotConnected() {
        let connected = [
            device(id: 1, name: "Built-in"),
            device(id: 2, name: "AirPods Pro")
        ]
        let priority = ["Studio Display", "AirPods Pro", "Built-in"]

        let best = AudioTier.bestDevice(from: priority, connected: connected)

        XCTAssertEqual(best?.name, "AirPods Pro")
    }

    func testFallsBackToFirstConnectedWhenNoPriorityMatches() {
        let connected = [
            device(id: 1, name: "Random USB Mic"),
            device(id: 2, name: "Built-in")
        ]
        let priority = ["Studio Display", "AirPods Pro"]

        let best = AudioTier.bestDevice(from: priority, connected: connected)

        XCTAssertEqual(best?.name, "Random USB Mic")
    }

    func testReturnsNilWhenNoDevicesConnected() {
        XCTAssertNil(AudioTier.bestDevice(from: ["Anything"], connected: []))
    }

    func testReturnsFirstConnectedWhenPriorityListIsEmpty() {
        let connected = [
            device(id: 1, name: "Built-in"),
            device(id: 2, name: "AirPods Pro")
        ]

        let best = AudioTier.bestDevice(from: [], connected: connected)

        XCTAssertEqual(best?.name, "Built-in")
    }

    func testMatchIsExactByName() {
        let connected = [device(id: 1, name: "AirPods Pro")]
        let priority = ["AirPods"]

        let best = AudioTier.bestDevice(from: priority, connected: connected)

        XCTAssertEqual(best?.name, "AirPods Pro", "no priority match → falls back to first connected")
    }

    private func device(id: AudioDeviceID, name: String) -> AudioDevice {
        AudioDevice(
            id: id,
            name: name,
            uid: "uid-\(id)",
            isInput: true,
            isOutput: true,
            transportType: kAudioDeviceTransportTypeUSB
        )
    }
}
