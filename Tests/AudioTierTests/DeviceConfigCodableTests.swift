import XCTest
@testable import AudioTier

final class DeviceConfigCodableTests: XCTestCase {
    func testRoundTripPreservesOrder() throws {
        let original = DeviceConfig(
            audioInput: ["Shure MV7", "Built-in Microphone"],
            audioOutput: ["Studio Display", "AirPods Pro", "Built-in Output"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DeviceConfig.self, from: data)

        XCTAssertEqual(decoded.audioInput, original.audioInput)
        XCTAssertEqual(decoded.audioOutput, original.audioOutput)
    }

    func testDecodesCanonicalConfigShape() throws {
        let json = """
        {
          "audioInput": ["Shure MV7", "Built-in Microphone"],
          "audioOutput": ["Studio Display", "AirPods Pro"]
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(DeviceConfig.self, from: json)

        XCTAssertEqual(config.audioInput, ["Shure MV7", "Built-in Microphone"])
        XCTAssertEqual(config.audioOutput, ["Studio Display", "AirPods Pro"])
    }

    func testDecodingRejectsMissingFields() {
        let json = #"{"audioInput": ["Mic"]}"#.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(DeviceConfig.self, from: json))
    }

    func testEmptyListsRoundTrip() throws {
        let original = DeviceConfig(audioInput: [], audioOutput: [])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DeviceConfig.self, from: data)

        XCTAssertEqual(decoded.audioInput, [])
        XCTAssertEqual(decoded.audioOutput, [])
    }
}
