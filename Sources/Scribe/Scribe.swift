import Logging
import Plugin

/// A class that serves as the main logging.
/// It has the ability to have plugins attached to it that can further process the logs.
open class Scribe: Pluginable {
    /// The structure that represents the payload passed to each plugin when a log is made.
    public struct PluginPayload {
        /// The log level of the message.
        public let level: Level
        /// The message being logged.
        public let message: Message
        /// Additional information about the log event.
        public let metadata: Metadata?
        /// The source of the log event.
        public let source: String?

        init(level: Level, message: Message, metadata: Metadata?, source: String?) {
            self.level = level
            self.message = message
            self.metadata = metadata
            self.source = source
        }
    }

    /// An alias Logger.Level.
    public typealias Level = Logger.Level
    /// An alias Logger.Message.
    public typealias Message = Logger.Message
    /// An alias for Logger.Metadata.
    public typealias Metadata = Logger.Metadata

    /// The private logger used by Scribe.
    private let logger: Logger
    /// The plugins attached to Scribe.
    public var plugins: [any Plugin]

    /// Initializes a new instance of Scribe.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - plugins: The initial plugins to attach to Scribe.
    public init(
        label: String,
        plugins initialPlugins: [any Plugin] = []
    ) {
        logger = Logger(label: label)
        plugins = initialPlugins
    }

    /// Initializes a new instance of Scribe.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - factory: A closure creating non-standard `LogHandler`s.
    ///   - plugins: The initial plugins to attach to Scribe.
    public init(
        label: String,
        factory: (String) -> LogHandler,
        plugins initialPlugins: [any Plugin] = []
    ) {
        logger = Logger(label: label, factory: factory)
        plugins = initialPlugins
    }

    /// Initializes a new instance of Scribe.
    ///
    /// - Parameters:
    ///   - label: The label for the logger.
    ///   - metadataProvider: The custom metadata provider this logger should invoke,
    ///                         instead of the system wide bootstrapped one, when a log statement is about to be emitted.
    ///   - plugins: The initial plugins to attach to Scribe.
    public init(
        label: String,
        metadataProvider: Logger.MetadataProvider,
        plugins initialPlugins: [any Plugin] = []
    ) {
        logger = Logger(label: label, metadataProvider: metadataProvider)
        plugins = initialPlugins
    }

    /// Logs a message with a specified level and metadata.
    ///
    /// - Parameters:
    ///   - level: The level of the log event.
    ///   - message: The message to log.
    ///   - metadata: Additional information about the log event.
    ///   - source: The source of the log event.
    /// - Returns: A task that represents the logging process.
    @discardableResult
    open func log(
        level: Level,
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        let pluginPayload = PluginPayload(
            level: level,
            message: message,
            metadata: metadata,
            source: source
        )

        logger.log(
            level: level,
            message,
            metadata: metadata,
            source: source
        )

        return Task {
            try await handle(value: pluginPayload)
        }
    }
}

// MARK: - Log Level Functions

extension Scribe {
    /// Logs a message with the trace log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func trace(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .trace,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the debug log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func debug(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .debug,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the info log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func info(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .info,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the notice log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func notice(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .notice,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the warning log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func warning(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .warning,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the error log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func error(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .error,
            message,
            metadata: metadata,
            source: source
        )
    }

    /// Logs a message with the critical log level.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - metadata: Optional metadata to be included with the log message.
    ///   - source: Optional source information to be included with the log message.
    /// - Returns: A task representing the log operation.
    @discardableResult
    public func critical(
        _ message: Message,
        metadata: Metadata? = nil,
        source: String? = nil
    ) -> Task<Void, Error> {
        log(
            level: .critical,
            message,
            metadata: metadata,
            source: source
        )
    }
}
