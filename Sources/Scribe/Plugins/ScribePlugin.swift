import Plugin

/// A protocol that defines a Scribe plugin.
public protocol ScribePlugin: Plugin
where Source == Scribe,
      Output == Void,
      Input == Scribe.PluginPayload {
    /// Handles the input value.
    ///
    /// - Parameters:
    ///   - value: The input value that the plugin will handle.
    /// - Throws: Any errors that occur during handling of the input value.
    func handle(value: Scribe.PluginPayload) async throws
}

/// Extension that provides a default implementation for the `keyPath` property of `ScribePlugin`.
extension ScribePlugin {
    /// A keypath that provides access to the `immutable` property of `Scribe`.
    public var keyPath: WritableKeyPath<Scribe, ()> {
        get { \.immutable }
        set { }
    }

    public func handle(value: Scribe.PluginPayload, output: inout ()) async throws {
        try await handle(value: value)
    }
}
