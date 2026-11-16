import Logging
import Plugin
import Scribe
import Testing

/// Requires the plugin to be one Plugin 3.0 accepts as an `ImmutablePlugin` of Scribe's payload.
func requireImmutablePlugin<P: ImmutablePlugin<Scribe.PluginPayload>>(_ plugin: P) -> P {
    plugin
}

@Suite("REQ-Scribe-5: a Scribe plugin is a Plugin 3.0 ImmutablePlugin")
struct PluginInteropTests {
    @Test("REQ-Scribe-5: Scribe plugins run in a Plugins<Scribe.PluginPayload, Void> via register and handleInOrder")
    func scribePluginsInPlugins() async throws {
        let actorPlugin = Scribe30ActorPlugin()
        let sink = MessageSink()
        let scribePlugins: [any ScribePlugin] = [actorPlugin, Scribe30StructPlugin(sink: sink)]

        // Register one at a time through the generic `register(_:)`, which opens each
        // existential. Converting `any ScribePlugin` to `any ImmutablePlugin<…>` is not supported.
        let plugins = Plugins<Scribe.PluginPayload, Void>()
        let tokens = scribePlugins.map { plugins.register($0) }
        #expect(tokens.count == 2)
        #expect(plugins.count == 2)

        for index in 0..<3 {
            try await plugins.handleInOrder(
                value: Scribe.PluginPayload(level: .info, message: "\(index)", metadata: nil, source: nil)
            )
        }

        #expect(await actorPlugin.messages == ["0", "1", "2"])
        #expect(await sink.messages == ["0", "1", "2"])
    }

    @Test("REQ-Scribe-5: a concrete Scribe plugin satisfies ImmutablePlugin<Scribe.PluginPayload>")
    func concreteScribePluginIsImmutablePlugin() async throws {
        let plugin = requireImmutablePlugin(Scribe30ActorPlugin())
        let immutable: any ImmutablePlugin<Scribe.PluginPayload> = plugin
        let general: any Plugin<Scribe.PluginPayload, Void> = plugin

        try await immutable.handle(value: Scribe.PluginPayload(level: .debug, message: "a", metadata: nil, source: nil))
        try await general.handle(value: Scribe.PluginPayload(level: .debug, message: "b", metadata: nil, source: nil))

        // The same instance still works as a Scribe plugin.
        let scribe = quietScribe("test.interop", plugins: [plugin])
        scribe.info("c")
        await scribe.flush()

        #expect(await plugin.messages == ["a", "b", "c"])
    }
}
