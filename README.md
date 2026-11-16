# Scribe

*📜 Logging all events*

Scribe is a logging library for Swift. It writes every entry to [swift-log](https://github.com/apple/swift-log) and hands it to plugins you register, so one log call can reach the console, a file, a debug screen or a server.

Scribe 3 is built for Swift 6: `Scribe`, `ScribePlugin` and `Scribe.PluginPayload` are `Sendable`, logging calls are synchronous, and each plugin receives entries in the order they were logged, one at a time. Its only dependency is swift-log.

## Requirements

- Swift 6.0 or later (swift-tools-version 6.0)
- macOS 13, iOS 16, tvOS 16, watchOS 9 or visionOS 1

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/Scribe", from: "3.0.0")
]
```

## Usage

### Creating a Scribe

```swift
import Scribe

let scribe = Scribe(label: "com.example.app")
```

`Scribe` is `Sendable`, so a single instance can be stored in a global, passed to actors or used from any task.

You can also pass a custom swift-log handler or metadata provider:

```swift
let scribe = Scribe(label: "com.example.app", factory: { label in StreamLogHandler.standardError(label: label) })
```

### Writing a plugin

A plugin conforms to `ScribePlugin`, which is `Sendable` and has one async requirement. An actor is the simplest way to keep state:

```swift
actor CountPlugin: ScribePlugin {
    private(set) var count = 0

    func handle(value: Scribe.PluginPayload) async throws {
        count += 1
    }
}
```

The payload carries the entry's `level`, `message`, `metadata` and `source`, the `file`, `function` and `line` that logged it, and the `date` it was logged.

A plugin may throw. Scribe ignores the error: that plugin still receives later entries, and other plugins are not affected.

### Registering plugins

Pass plugins when you create the Scribe:

```swift
let counter = CountPlugin()
let scribe = Scribe(label: "com.example.app", plugins: [counter])
```

Or register one later. `register(plugin:)` returns a registration you can use to remove the plugin:

```swift
let registration = scribe.register(plugin: counter)

scribe.remove(plugin: registration)
scribe.removeAllPlugins()
```

A plugin receives the entries logged after it was registered and before it was removed.

### Logging

The logging functions match swift-log's. Each one logs to swift-log and returns immediately; it never waits for a plugin:

```swift
scribe.debug("Loaded settings")
scribe.error("Request failed", metadata: ["status": "500"], source: "Network")
scribe.log(level: .info, "Signed in")
```

Scribe supports the levels `trace`, `debug`, `info`, `notice`, `warning`, `error` and `critical`.

### Waiting for plugins

Plugins run on Scribe's own delivery task. Call `flush()` to wait until every entry logged so far has reached every plugin, for example in a test or before the app exits:

```swift
scribe.info("Shutting down")
await scribe.flush()
```

## Moving from 2.x

Scribe 3.0.0 is a major release. It drops the [Plugin](https://github.com/0xLeif/Plugin) package (and Fork with it), so update code that used Plugin's types:

| 2.x | 3.0 |
|-----|-----|
| `swift-tools-version: 5.7`, macOS 11 / iOS 14 | Swift 6 (`swift-tools-version: 6.0`), macOS 13 / iOS 16 / tvOS 16 / watchOS 9 |
| `ScribePlugin: ImmutablePlugin` from the Plugin package | `ScribePlugin: Sendable`, defined by Scribe; remove `import Plugin` |
| A plugin could be a non-Sendable class | A plugin must be `Sendable`; use an actor, a struct, or a final class with a lock |
| `open class Scribe: Pluginable` | `public final class Scribe: Sendable`; it cannot be subclassed |
| `scribe.plugins` was a mutable array | `scribe.plugins` is read-only; use `register(plugin:)`, `remove(plugin:)` and `removeAllPlugins()` |
| Each log call returned a `Task<Void, Error>` | Log calls return nothing; `await scribe.flush()` waits for delivery |
| Each log call started its own task, so plugins could see entries out of order | Each plugin receives entries in the order they were logged, one at a time |
| A plugin's error ended that log call's task | A plugin's error is ignored; delivery continues |
| `PluginPayload` had `level`, `message`, `metadata`, `source` | It also has `file`, `function`, `line` and `date` |

A 2.x test that awaited the returned task:

```swift
try await scribe.debug("Test").value
```

becomes:

```swift
scribe.debug("Test")
await scribe.flush()
```

## Documentation

API documentation is published with DocC at [scribe.0xl.io](https://scribe.0xl.io/documentation/scribe).
