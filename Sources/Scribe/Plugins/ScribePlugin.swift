import Plugin

/// A protocol that defines a Scribe plugin.
public protocol ScribePlugin: Plugin
where Source == Scribe,
      Output == Void,
      Input == Scribe.PluginPayload
{ }

/// Extension that provides a default implementation for the `keyPath` property of `ScribePlugin`.
extension ScribePlugin {
    /// A keypath that provides access to the `immutable` property of `Scribe`.
    public var keyPath: WritableKeyPath<Scribe, ()> {
        get { \.immutable }
        set { }
    }
}
