import Foundation
import Logging
import Scribe
import Testing
import struct os.OSAllocatedUnfairLock

// MARK: - Test plugins

/// Records every payload it receives, in order.
actor Recorder: ScribePlugin {
    private(set) var payloads: [Scribe.PluginPayload] = []

    var messages: [String] { payloads.map(\.message.description) }

    func handle(value: Scribe.PluginPayload) async throws {
        payloads.append(value)
    }
}

/// Throws on every message in `failing`, after recording that it was asked.
actor ThrowingPlugin: ScribePlugin {
    struct Failure: Error {}

    let failing: Set<String>
    private(set) var received: [String] = []

    init(failing: Set<String>) {
        self.failing = failing
    }

    func handle(value: Scribe.PluginPayload) async throws {
        received.append(value.message.description)
        if failing.contains(value.message.description) {
            throw Failure()
        }
    }
}

/// Blocks inside `handle` until `open()` is called, then records.
actor GatePlugin: ScribePlugin {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var received = 0

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func handle(value: Scribe.PluginPayload) async throws {
        if !isOpen {
            await withCheckedContinuation { waiters.append($0) }
        }
        received += 1
    }
}

/// A swift-log handler that records what swift-log was asked to log.
struct RecordingLogHandler: LogHandler {
    let lines: OSAllocatedUnfairLock<[String]>
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(event: LogEvent) {
        lines.withLock { $0.append("\(event.level):\(event.message)") }
    }
}

// MARK: - REQ-Scribe-1

@Suite("REQ-Scribe-1: Swift 6, Sendable types")
struct SendableTests {
    actor Owner {
        let scribe: Scribe
        init(scribe: Scribe) { self.scribe = scribe }
        func write(_ text: String) { scribe.info("\(text)") }
    }

    @Test("REQ-Scribe-1: a Scribe is shared between tasks and an actor")
    func sharedAcrossIsolation() async {
        let recorder = Recorder()
        let scribe = quietScribe("test.sendable", plugins: [recorder])
        let owner = Owner(scribe: scribe)

        await owner.write("from actor")
        await Task.detached { scribe.info("from detached task") }.value
        await scribe.flush()

        #expect(await recorder.messages == ["from actor", "from detached task"])
    }

    @Test("REQ-Scribe-1: Scribe, ScribePlugin and PluginPayload are Sendable")
    func typesAreSendable() {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(Scribe.self)
        requireSendable(Scribe.PluginPayload.self)
        requireSendable((any ScribePlugin).self)
        requireSendable(Scribe.PluginRegistration.self)
    }
}

// MARK: - REQ-Scribe-2

@Suite("REQ-Scribe-2: plugin protocol on Plugin 3.0, register and remove")
struct RegistrationTests {
    @Test("REQ-Scribe-2: a plugin registered at creation receives entries")
    func registeredAtCreation() async {
        let recorder = Recorder()
        let scribe = quietScribe("test.init", plugins: [recorder])

        scribe.debug("one")
        await scribe.flush()

        #expect(await recorder.messages == ["one"])
        #expect(scribe.plugins.count == 1)
    }

    @Test("REQ-Scribe-2: register(plugin:) adds a plugin for later entries")
    func registerLater() async {
        let recorder = Recorder()
        let scribe = quietScribe("test.register")

        scribe.debug("before")
        scribe.register(plugin: recorder)
        scribe.debug("after")
        await scribe.flush()

        #expect(await recorder.messages == ["after"])
    }

    @Test("REQ-Scribe-2: remove(plugin:) stops one plugin, keeps the others")
    func removeOne() async {
        let kept = Recorder()
        let removed = Recorder()
        let scribe = quietScribe("test.remove", plugins: [kept])
        let registration = scribe.register(plugin: removed)

        scribe.debug("both")
        scribe.remove(plugin: registration)
        scribe.debug("kept only")
        await scribe.flush()

        #expect(await kept.messages == ["both", "kept only"])
        #expect(await removed.messages == ["both"])
        #expect(scribe.plugins.count == 1)
    }

    @Test("REQ-Scribe-2: removeAllPlugins() removes plugins from creation too")
    func removeAll() async {
        let first = Recorder()
        let second = Recorder()
        let scribe = quietScribe("test.removeAll", plugins: [first])
        scribe.register(plugin: second)

        scribe.debug("before")
        scribe.removeAllPlugins()
        scribe.debug("after")
        await scribe.flush()

        #expect(await first.messages == ["before"])
        #expect(await second.messages == ["before"])
        #expect(scribe.plugins.isEmpty)
    }

    @Test("REQ-Scribe-2: Package.swift depends on exactly swift-log and Plugin 3.0")
    func swiftLogAndPluginOnly() throws {
        let manifest = try String(contentsOf: packageRoot.appending(path: "Package.swift"), encoding: .utf8)
        let dependencies = manifest.components(separatedBy: ".package(url:").dropFirst()
        #expect(dependencies.count == 2)
        #expect(dependencies.contains { $0.contains("\"https://github.com/apple/swift-log\"") })
        #expect(dependencies.contains {
            $0.contains("\"https://github.com/0xLeif/Plugin\"") && $0.contains("from: \"3.0.0\"")
        })
        #expect(!manifest.contains("Fork"))
    }
}

// MARK: - REQ-Scribe-3

@Suite("REQ-Scribe-3: synchronous logging, ordered delivery")
struct DeliveryTests {
    @Test("REQ-Scribe-3: 1,000 entries from one task arrive in order")
    func orderedDelivery() async {
        let recorder = Recorder()
        let scribe = quietScribe("test.order", plugins: [recorder])

        for index in 0..<1_000 {
            scribe.info("\(index)")
        }
        await scribe.flush()

        #expect(await recorder.messages == (0..<1_000).map(String.init))
    }

    @Test("REQ-Scribe-3: a throwing plugin keeps receiving, others get everything")
    func throwingPlugin() async {
        let thrower = ThrowingPlugin(failing: ["1", "3"])
        let after = Recorder()
        let scribe = quietScribe("test.throw", plugins: [thrower, after])

        for index in 0..<5 {
            scribe.warning("\(index)")
        }
        await scribe.flush()

        #expect(await thrower.received == ["0", "1", "2", "3", "4"])
        #expect(await after.messages == ["0", "1", "2", "3", "4"])
    }

    @Test("REQ-Scribe-3: a slow plugin does not block logging")
    func slowPluginDoesNotBlock() async {
        let gate = GatePlugin()
        let scribe = quietScribe("test.slow", plugins: [gate])

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for index in 0..<100 {
                scribe.info("\(index)")
            }
        }

        // Every log call returned while the plugin was still blocked on the first entry.
        #expect(await gate.received == 0)
        #expect(elapsed < .milliseconds(500))

        await gate.open()
        await scribe.flush()
        #expect(await gate.received == 100)
    }

    @Test("REQ-Scribe-3: concurrent logging delivers every entry exactly once")
    func concurrentLogging() async {
        let recorder = Recorder()
        let scribe = quietScribe("test.concurrent", plugins: [recorder])
        let tasks = 50
        let perTask = 100

        await withTaskGroup(of: Void.self) { group in
            for task in 0..<tasks {
                group.addTask {
                    for index in 0..<perTask {
                        scribe.info("\(task)-\(index)")
                    }
                }
            }
        }
        await scribe.flush()

        let messages = await recorder.messages
        let expected = (0..<tasks).flatMap { task in (0..<perTask).map { "\(task)-\($0)" } }
        #expect(messages.count == tasks * perTask)
        #expect(Set(messages) == Set(expected))
        // Each task's own entries keep their order.
        for task in 0..<tasks {
            let own = messages.filter { $0.hasPrefix("\(task)-") }
            #expect(own == (0..<perTask).map { "\(task)-\($0)" })
        }
    }

    @Test("REQ-Scribe-3: the payload carries level, message, metadata, source and call site")
    func payloadFields() async throws {
        let recorder = Recorder()
        let scribe = quietScribe("test.payload", plugins: [recorder])
        let before = Date()

        scribe.error("failed", metadata: ["id": "42"], source: "Tests"); let line = UInt(#line)
        await scribe.flush()

        let payload = try #require(await recorder.payloads.first)
        #expect(payload.level == .error)
        #expect(payload.message == "failed")
        #expect(payload.metadata == ["id": "42"])
        #expect(payload.source == "Tests")
        #expect(payload.file == #fileID)
        #expect(payload.function == "payloadFields()")
        #expect(payload.line == line)
        #expect(payload.date >= before && payload.date <= Date())
    }

    @Test("REQ-Scribe-3: each level function logs to swift-log and to plugins")
    func levelsReachSwiftLogAndPlugins() async {
        let lines = OSAllocatedUnfairLock<[String]>(initialState: [])
        let recorder = Recorder()
        let scribe = Scribe(
            label: "test.levels",
            factory: { _ in RecordingLogHandler(lines: lines) },
            plugins: [recorder]
        )

        scribe.trace("t")
        scribe.debug("d")
        scribe.info("i")
        scribe.notice("n")
        scribe.warning("w")
        scribe.error("e")
        scribe.critical("c")
        scribe.log(level: .info, "l")
        await scribe.flush()

        // swift-log has the entry as soon as the call returns.
        #expect(lines.withLock { $0 } == [
            "trace:t", "debug:d", "info:i", "notice:n", "warning:w", "error:e", "critical:c", "info:l"
        ])
        #expect(await recorder.payloads.map(\.level) == [
            .trace, .debug, .info, .notice, .warning, .error, .critical, .info
        ])
    }

    @Test("REQ-Scribe-3: entries logged before the Scribe is released are still delivered")
    func deliveryOutlivesScribe() async {
        let gate = GatePlugin()
        var scribe: Scribe? = quietScribe("test.release", plugins: [gate])
        for index in 0..<10 {
            scribe?.info("\(index)")
        }
        scribe = nil

        await gate.open()
        for _ in 0..<1_000 where await gate.received < 10 {
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(await gate.received == 10)
    }
}

// MARK: - REQ-Scribe-4

@Suite("REQ-Scribe-4: README documents 3.0")
struct DocumentationTests {
    @Test("REQ-Scribe-4: README shows Swift 6 usage and a Moving from 2.x section")
    func readme() throws {
        let readme = try String(contentsOf: packageRoot.appending(path: "README.md"), encoding: .utf8)
        #expect(readme.contains("## Moving from 2.x"))
        #expect(readme.contains("ScribePlugin"))
        #expect(readme.contains("register(plugin:"))
        #expect(readme.contains("flush()"))
    }
}

/// The package root, found from this file's path.
let packageRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

/// A Scribe whose swift-log output is discarded, so test logs stay readable.
func quietScribe(_ label: String, plugins: [any ScribePlugin] = []) -> Scribe {
    Scribe(label: label, factory: { _ in SwiftLogNoOpLogHandler() }, plugins: plugins)
}
