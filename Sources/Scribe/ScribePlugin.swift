import Plugin

/// A plugin that receives every entry logged through a ``Scribe``.
///
/// `ScribePlugin` refines Plugin 3.0's `ImmutablePlugin` with its input fixed to
/// ``Scribe/PluginPayload``. It adds no requirement of its own, so a type only writes
/// `func handle(value: Scribe.PluginPayload) async throws`, exactly as in Scribe 3.0,
/// and the same type can be used wherever Plugin expects an
/// `ImmutablePlugin<Scribe.PluginPayload>`.
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
///
/// To hand an `any ScribePlugin` to Plugin's `Plugins` list, pass it to the generic
/// `register(_:)`, one plugin at a time. Converting `any ScribePlugin` to
/// `any ImmutablePlugin<Scribe.PluginPayload>` by assignment, or through
/// `register(contentsOf:)`, is not supported by Swift 6.
public protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {
    /// Handles one logged entry.
    ///
    /// This restates `ImmutablePlugin`'s own requirement for Scribe's input; it is not a second
    /// requirement, and one method satisfies both. Restating it keeps `handle(value:)` visible
    /// to code that imports only Scribe, including with the `MemberImportVisibility` feature.
    ///
    /// - Parameter value: The entry that was logged.
    func handle(value: Scribe.PluginPayload) async throws
}
