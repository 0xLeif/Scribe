import o
import Plugin
import XCTest
@testable import Scribe

final class ScribeTests: XCTestCase {
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
