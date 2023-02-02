import o
import Plugin
import XCTest
@testable import Scribe

final class ScribeTests: XCTestCase {
    func testExample() async throws {
        let filename = "scribe.test"

        let scribe = Scribe(
            label: "Scribe.Tests",
            plugins: [
                FilePlugin(filename: filename) { payload in
                    "\(payload.level.rawValue.uppercased()): \(payload.message)"
                }
            ]
        )

        let pluginTask = scribe.info("Test")

        try await pluginTask.value

        let fileContents: [String] = (try? o.file.in(filename: filename)) ?? []

        XCTAssertEqual(fileContents.first, "INFO: Test")

        // Clean up and delete test file

        XCTAssertNoThrow(try o.file.data(filename: filename))

        try o.file.delete(filename: filename)

        XCTAssertThrowsError(try o.file.data(filename: filename))
    }

    func testPeristablePlugin() async throws {
        class CountPlugin: ScribePlugin {
            static let shared = CountPlugin()

            var count: Int = 0

            private init() {}

            func handle(value: Scribe.PluginPayload) async throws {
                count += 1
            }
        }

        let scribe = Scribe(
            label: "test.count",
            plugins: [
                CountPlugin.shared
            ]
        )

        XCTAssertEqual(CountPlugin.shared.count, 0)

        let pluginTask = scribe.debug("Test")

        try await pluginTask.value

        XCTAssertEqual(CountPlugin.shared.count, 1)
    }
}
