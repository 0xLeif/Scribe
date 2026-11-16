/// A plugin that receives every entry logged through a ``Scribe``.
///
/// Scribe delivers entries to each plugin in the order they were logged, one at a time,
/// on its own delivery task. A plugin that throws is skipped for that entry only: it still
/// receives later entries, and other plugins are not affected.
///
/// ```swift
/// actor CountPlugin: ScribePlugin {
///     private(set) var count = 0
///
///     func handle(value: Scribe.PluginPayload) async throws {
///         count += 1
///     }
/// }
/// ```
public protocol ScribePlugin: Sendable {
    /// Handles one logged entry.
    ///
    /// - Parameter value: The entry that was logged.
    func handle(value: Scribe.PluginPayload) async throws
}
