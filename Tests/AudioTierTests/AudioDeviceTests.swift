import CoreAudio
import XCTest
@testable import AudioTier

final class AudioDeviceTests: XCTestCase {
    func testTransportNameMapping() {
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeBuiltIn).transportName, "Built-in")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeUSB).transportName, "USB")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeBluetooth).transportName, "Bluetooth")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeBluetoothLE).transportName, "Bluetooth")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeHDMI).transportName, "HDMI")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeVirtual).transportName, "Virtual")
        XCTAssertEqual(makeDevice(transport: kAudioDeviceTransportTypeAggregate).transportName, "Aggregate")
        XCTAssertEqual(makeDevice(transport: 0xDEADBEEF).transportName, "Unknown")
    }

    func testDescriptionIncludesNameAndTransport() {
        let device = makeDevice(name: "AirPods Pro", transport: kAudioDeviceTransportTypeBluetooth)
        XCTAssertEqual(device.description, "AirPods Pro (Bluetooth)")
    }

    private func makeDevice(name: String = "Test", transport: UInt32) -> AudioDevice {
        AudioDevice(
            id: 1,
            name: name,
            uid: "uid-\(name)",
            isInput: true,
            isOutput: true,
            transportType: transport
        )
    }
}
