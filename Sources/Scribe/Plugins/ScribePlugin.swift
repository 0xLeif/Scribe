import Plugin

/// A protocol that defines a Scribe plugin.
public protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {}
