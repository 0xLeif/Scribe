import o
import Plugin

/// A  Scribe Plugin to save logs to a file
public struct FilePlugin: ScribePlugin {
    /// The path of the directory to write the file to
    public var path: String

    /// The filename of the file to write to
    public var filename: String

    /// A closure that formats the log output. If the closure returns nil, then the log data won't be written to the file.
    public var outputFormatter: (Scribe.PluginPayload) async throws -> String?

    /// Initializes a `FilePlugin`
    ///
    /// - Parameters:
    ///   - path: The path of the directory to write the file to.
    ///   - filename: The filename of the file to write to.
    ///   - outputFormatter: A closure that formats the log output. If the closure returns nil, then the log data won't be written to the file.
    public init(
        path: String = ".",
        filename: String,
        outputFormatter: @escaping (Scribe.PluginPayload) async throws -> String?
    ) {
        self.path = path
        self.filename = filename
        self.outputFormatter = outputFormatter
    }

    /// Handles the logging event by writing it to a file.
    public func handle(value: Scribe.PluginPayload) async throws {
        guard let formattedLog = try await outputFormatter(value) else {
            return
        }

        var fileContents: [String] = (try? o.file.in(path: path, filename: filename)) ?? []

        fileContents.append(formattedLog)

        try o.file.out(fileContents, path: path, filename: filename)
    }
}
