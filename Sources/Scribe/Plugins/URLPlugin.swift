import Foundation
import o
import Plugin

/// A  Scribe Plugin to send logs to a remote URL
public struct URLPlugin: ScribePlugin {
    /// The type alias DataResponse is defined as o.url.DataResponse.
    public typealias DataResponse = o.url.DataResponse

    /// The URL of the endpoint the plugin will send data to.
    public var url: URL

    /// The header fields to include in the HTTP request.
    public var headerFields: [String: String]

    /// A closure that formats the `Scribe.PluginPayload` into a  JSON (`Data`) object.
    public var outputFormatter: (Scribe.PluginPayload) async throws -> Data

    /// A closure that handles the response from the remote URL.
    public var responseHandler: (DataResponse) async throws -> Void

    /// Initializes a new `URLPlugin`.
    ///
    /// - Parameters:
    ///   - url: The URL of the endpoint to which the plugin will send log data.
    ///   - headerFields: The header fields to include in the HTTP request. Defaults to `["Content-Type": "application/json; charset=utf-8", "Accept": "application/json"]`.
    ///   - outputFormatter: A closure that formats the `Scribe.PluginPayload` into a  JSON (`Data`) object.
    ///   - responseHandler: A closure that handles the response from the remote URL. Defaults to an empty closure.
    public init(
        url: URL,
        headerFields: [String : String] = [
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json"
        ],
        outputFormatter: @escaping (Scribe.PluginPayload) async throws -> Data,
        responseHandler: @escaping (DataResponse) async throws -> Void = { _ in }
    ) {
        self.url = url
        self.headerFields = headerFields
        self.outputFormatter = outputFormatter
        self.responseHandler = responseHandler
    }

    /// Handles the given `Scribe.PluginPayload` by sending it to the remote URL.
    public func handle(value: Scribe.PluginPayload) async throws {
        let dataResponse = try await o.url.post(
            url: url,
            body: try await outputFormatter(value),
            headerFields: headerFields
        )

        try await responseHandler(dataResponse)
    }
}
