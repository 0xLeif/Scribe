import Foundation
import Logging
import struct os.OSAllocatedUnfairLock

/// A logger that writes to swift-log and hands every entry to its plugins.
///
/// Each logging call is synchronous: it logs to swift-log, puts the entry on one ordered
/// delivery pipeline, and returns without waiting for any plugin. A single delivery task
/// hands each entry to each plugin, in the order the entries were logged, one at a time.
/// Call ``flush()`` to wait until everything logged so far has been delivered.
///
/// `Scribe` is `Sendable`, so one instance can be shared between tasks and actors.
public final class Scribe: Sendable {
    /// An alias for `Logger.Level`.
    public typealias Level = Logger.Level
    /// An alias for `Logger.Message`.
    public typealias Message = Logger.Message
    /// An alias for `Logger.Metadata`.
    public typealias Metadata = Logger.Metadata

    /// The entry handed to each plugin when a message is logged.
    public struct PluginPayload: Sendable {
        /// The log level of the message.
        public let level: Level
        /// The message being logged.
        public let message: Message
        /// The metadata passed with the log call, if any.
        public let metadata: Metadata?
        /// The source passed with the log call, if any.
        public let source: String?
        /// The file that made the log call.
        public let file: String
        /// The function that made the log call.
        public let function: String
        /// The line that made the log call.
        public let line: UInt
        /// When the log call was made.
        public let date: Date

        /// Creates a payload.
        public init(
            level: Level,
            message: Message,
            metadata: Metadata?,
            source: String?,
            file: String = #fileID,
            function: String = #function,
            line: UInt = #line,
            date: Date = Date()
        ) {
            self.level = level
            self.message = message
            self.metadata = metadata
            self.source = source
            self.file = file
            self.function = function
            self.line = line
            self.date = date
        }
    }

    /// Identifies one registered plugin, so it can be removed later.
    public struct PluginRegistration: Hashable, Sendable {
        let id: UInt64
    }

    private enum Item: Sendable {
        case entry(PluginPayload, [any ScribePlugin])
        case flush(CheckedContinuation<Void, Never>)
    }

    private struct State: Sendable {
        var nextID: UInt64 = 0
        var plugins: [(registration: PluginRegistration, plugin: any ScribePlugin)] = []

        mutating func add(_ plugin: any ScribePlugin) -> PluginRegistration {
            let registration = PluginRegistration(id: nextID)
            nextID += 1
            plugins.append((registration, plugin))
            return registration
        }
    }

    /// The swift-log logger every entry is written to.
    private let logger: Logger
    /// The registered plugins. The same lock also orders entries onto the pipeline,
    /// so the delivery order matches the order the log calls took the lock.
    private let state: OSAllocatedUnfairLock<State>
    /// The input of the delivery pipeline.
    private let pipeline: AsyncStream<Item>.Continuation

    /// Creates a Scribe that logs with swift-log's bootstrapped handler.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - plugins: The plugins to register.
    public convenience init(
        label: String,
        plugins: [any ScribePlugin] = []
    ) {
        self.init(logger: Logger(label: label), plugins: plugins)
    }

    /// Creates a Scribe that logs with a custom `LogHandler`.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - factory: A closure creating the `LogHandler`.
    ///   - plugins: The plugins to register.
    public convenience init(
        label: String,
        factory: (String) -> any LogHandler,
        plugins: [any ScribePlugin] = []
    ) {
        self.init(logger: Logger(label: label, factory: factory), plugins: plugins)
    }

    /// Creates a Scribe whose logger uses a custom metadata provider.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - metadataProvider: The metadata provider this logger invokes, instead of the
    ///     system-wide bootstrapped one, when a log statement is about to be emitted.
    ///   - plugins: The plugins to register.
    public convenience init(
        label: String,
        metadataProvider: Logger.MetadataProvider,
        plugins: [any ScribePlugin] = []
    ) {
        self.init(logger: Logger(label: label, metadataProvider: metadataProvider), plugins: plugins)
    }

    private init(logger: Logger, plugins: [any ScribePlugin]) {
        self.logger = logger

        var initial = State()
        for plugin in plugins {
            _ = initial.add(plugin)
        }
        state = OSAllocatedUnfairLock(initialState: initial)

        let (stream, continuation) = AsyncStream.makeStream(of: Item.self)
        pipeline = continuation

        // The one consumer. It holds only the stream, never `self`, and ends when
        // `deinit` finishes the stream, after delivering what was already logged.
        Task {
            for await item in stream {
                switch item {
                case let .entry(payload, plugins):
                    for plugin in plugins {
                        // A throwing plugin must not stop later entries or other plugins.
                        try? await plugin.handle(value: payload)
                    }
                case let .flush(waiter):
                    waiter.resume()
                }
            }
        }
    }

    deinit {
        pipeline.finish()
    }

    // MARK: - Plugins

    /// The plugins registered now, in registration order.
    public var plugins: [any ScribePlugin] {
        state.withLock { state in state.plugins.map(\.plugin) }
    }

    /// Registers a plugin. It receives every entry logged after this call.
    ///
    /// - Parameter plugin: The plugin to register.
    /// - Returns: A registration to pass to ``remove(plugin:)``.
    @discardableResult
    public func register(plugin: any ScribePlugin) -> PluginRegistration {
        state.withLock { state in state.add(plugin) }
    }

    /// Removes a registered plugin. It receives no entry logged after this call;
    /// entries logged before it are still delivered.
    ///
    /// - Parameter registration: The registration ``register(plugin:)`` returned.
    public func remove(plugin registration: PluginRegistration) {
        state.withLock { state in
            state.plugins.removeAll { $0.registration == registration }
        }
    }

    /// Removes every plugin, including those registered at creation.
    public func removeAllPlugins() {
        state.withLock { state in state.plugins.removeAll() }
    }

    // MARK: - Delivery

    /// Waits until every entry logged before this call has been handed to its plugins.
    ///
    /// Use it in tests, and at shutdown so plugins see the last entries.
    public func flush() async {
        await withCheckedContinuation { (waiter: CheckedContinuation<Void, Never>) in
            if case .terminated = pipeline.yield(.flush(waiter)) {
                waiter.resume()
            }
        }
    }

    // MARK: - Logging

    /// Logs a message at a level, and hands it to every registered plugin.
    ///
    /// Returns without waiting for any plugin.
    ///
    /// - Parameters:
    ///   - level: The level of the log event.
    ///   - message: The message to log.
    ///   - metadata: Additional information about the log event.
    ///   - source: The source of the log event.
    ///   - file: The file the call came from. Leave the default.
    ///   - function: The function the call came from. Leave the default.
    ///   - line: The line the call came from. Leave the default.
    public func log(
        level: Level,
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        let payload = PluginPayload(
            level: level,
            message: message,
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line
        )

        logger.log(
            level: level,
            message,
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line
        )

        state.withLock { state in
            guard !state.plugins.isEmpty else { return }
            _ = pipeline.yield(.entry(payload, state.plugins.map(\.plugin)))
        }
    }
}

// MARK: - Log Level Functions

extension Scribe {
    /// Logs a message at the trace level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func trace(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .trace, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the debug level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func debug(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .debug, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the info level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func info(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .info, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the notice level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func notice(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .notice, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the warning level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func warning(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .warning, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the error level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func error(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .error, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    /// Logs a message at the critical level. See ``log(level:_:metadata:source:file:function:line:)``.
    public func critical(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .critical, message, metadata: metadata, source: source, file: file, function: function, line: line)
    }
}
