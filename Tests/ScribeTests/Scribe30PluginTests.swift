// This file deliberately does not import Plugin: the plugins below are written exactly as
// they were for Scribe 3.0, against `ScribePlugin`'s one requirement and `import Scribe` alone.
import Foundation
import Logging
import Scribe
import Testing

// MARK: - Plugins written against Scribe 3.0

/// A struct plugin as written for Scribe 3.0: `Sendable`, only `handle(value:)`.
struct Scribe30StructPlugin: ScribePlugin {
    let sink: MessageSink

    func handle(value: Scribe.PluginPayload) async throws {
        await sink.append(value.message.description)
    }
}

/// An actor plugin as written for Scribe 3.0: only `handle(value:)`.
actor Scribe30ActorPlugin: ScribePlugin {
    private(set) var messages: [String] = []

    func handle(value: Scribe.PluginPayload) async throws {
        messages.append(value.message.description)
    }
}

actor MessageSink {
    private(set) var messages: [String] = []

    func append(_ message: String) {
        messages.append(message)
    }
}

// MARK: - REQ-Scribe-5

@Suite("REQ-Scribe-5: Scribe 3.0 plugins and API unchanged")
struct Scribe30CompatibilityTests {
    @Test("REQ-Scribe-5: a struct written against Scribe 3.0 receives every entry in order")
    func scribe30Struct() async {
        let sink = MessageSink()
        let plugin = Scribe30StructPlugin(sink: sink)
        let scribe = quietScribe("test.compat.struct", plugins: [plugin])

        for index in 0..<500 {
            scribe.info("\(index)")
        }
        await scribe.flush()

        #expect(await sink.messages == (0..<500).map(String.init))
    }

    @Test("REQ-Scribe-5: an actor written against Scribe 3.0 receives every entry in order")
    func scribe30Actor() async {
        let plugin = Scribe30ActorPlugin()
        let scribe = quietScribe("test.compat.actor")
        let registration = scribe.register(plugin: plugin)

        for index in 0..<500 {
            scribe.debug("\(index)")
        }
        await scribe.flush()
        scribe.remove(plugin: registration)
        scribe.debug("after removal")
        await scribe.flush()

        #expect(await plugin.messages == (0..<500).map(String.init))
    }

    @Test("REQ-Scribe-5: a 3.0 plugin is still called directly and stored as any ScribePlugin")
    func scribe30DirectCall() async throws {
        let plugin = Scribe30ActorPlugin()
        let stored: [any ScribePlugin] = [plugin, Scribe30StructPlugin(sink: MessageSink())]

        try await plugin.handle(value: Scribe.PluginPayload(level: .info, message: "direct", metadata: nil, source: nil))
        for each in stored {
            try await each.handle(value: Scribe.PluginPayload(level: .info, message: "stored", metadata: nil, source: nil))
        }

        #expect(await plugin.messages == ["direct", "stored"])
    }

    @Test("REQ-Scribe-5: Scribe 3.1 keeps Scribe 3.0's public API")
    func scribe30PublicAPI() async {
        // Every 3.0 entry point, spelled with its 3.0 types. This test fails to compile if one changes.
        let plugin = Scribe30ActorPlugin()
        let initializers: [Scribe] = [
            Scribe(label: "test.compat.api"),
            Scribe(label: "test.compat.api", plugins: [plugin]),
            Scribe(label: "test.compat.api", factory: { _ in SwiftLogNoOpLogHandler() }, plugins: []),
            Scribe(label: "test.compat.api", metadataProvider: Logger.MetadataProvider { [:] }, plugins: [])
        ]
        #expect(initializers.count == 4)

        let scribe: Scribe = quietScribe("test.compat.api")
        let registration: Scribe.PluginRegistration = scribe.register(plugin: plugin)
        let registered: [any ScribePlugin] = scribe.plugins
        #expect(registered.count == 1)

        let level: Scribe.Level = .notice
        let message: Scribe.Message = "api"
        let metadata: Scribe.Metadata = ["k": "v"]
        let log: () -> Void = { scribe.log(level: level, message, metadata: metadata, source: "Tests") }
        log()
        scribe.trace("t"); scribe.debug("d"); scribe.info("i"); scribe.notice("n")
        scribe.warning("w"); scribe.error("e"); scribe.critical("c")
        await scribe.flush()

        scribe.remove(plugin: registration)
        scribe.register(plugin: plugin)
        scribe.removeAllPlugins()
        #expect(scribe.plugins.isEmpty)
        #expect(await plugin.messages == ["api", "t", "d", "i", "n", "w", "e", "c"])
    }
}
